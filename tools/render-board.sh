#!/usr/bin/env bash
#
# render-board.sh — Generate the PathTracer PCB showcase renders from a KiCad board.
#
# Produces raytraced, perspective, transparent-background PNGs (no floor shadow,
# so they sit cleanly on both light and dark README backgrounds):
#
#     <out-dir>/top-render.png      angled isometric top view (also used as the hero)
#     <out-dir>/bottom-render.png   angled isometric bottom view
#
# Usage:
#     tools/render-board.sh <board.kicad_pcb> <out-dir>
#
# Optional environment knobs:
#     KICAD_3DVARS="KEY=VAL KEY2=VAL2"   Extra --define-var entries, e.g. a 3D-model
#                                        search path:  KICAD8_3RD_PARTY=/path/to/3rdparty
#     HIDE_MODELS="substr1 substr2"      Suppress 3D models whose path contains a
#                                        substring (used to drop a placeholder library
#                                        model from a view, e.g. a coin-cell holder).
#     HIDE_DNP=1                         Exclude 3D models of DNP (do-not-populate)
#                                        footprints, for an as-built render.
#
# Examples:
#     # V2: hide the placeholder coin-cell holder so the back silkscreen shows
#     HIDE_MODELS="BATT-TH_MY-2032-02" tools/render-board.sh PathTracerV2.kicad_pcb "V2 PCB"
#
#     # V1: point KiCad at the 3rd-party module library so the BLE module renders
#     KICAD_3DVARS="KICAD8_3RD_PARTY=$HOME/.local/share/kicad/10.0/3rdparty" \
#         tools/render-board.sh PathTracer.kicad_pcb "V1 PCB"
#
# Requires: kicad-cli (KiCad 9+), python3. Optional: ImageMagick `magick` for cropping.
#
# Note: if a board's silkscreen uses custom fonts, install them first (e.g. into
# ~/.local/share/fonts, then `fc-cache -f`) or kicad-cli substitutes a default
# face. PathTracer V1 uses "Supercharge Semi-Straight" and "Direction".

set -euo pipefail

BOARD="${1:?usage: render-board.sh <board.kicad_pcb> <out-dir>}"
OUT="${2:?usage: render-board.sh <board.kicad_pcb> <out-dir>}"
mkdir -p "$OUT"

# Collect any extra project variables (3D-model search paths, etc).
DEFVARS=()
for kv in ${KICAD_3DVARS:-}; do DEFVARS+=(--define-var "$kv"); done

# Optionally suppress placeholder and/or DNP 3D models by breaking their path in a temp copy.
SRC="$BOARD"
CLEANUP=""
if [ -n "${HIDE_MODELS:-}" ] || [ -n "${HIDE_DNP:-}" ]; then
  SRC="$(mktemp --suffix=.kicad_pcb)"
  CLEANUP="$SRC"
  python3 - "$BOARD" "$SRC" ${HIDE_MODELS:-} <<'PY'
import sys, os, re
src, dst, pats = sys.argv[1], sys.argv[2], sys.argv[3:]
s = open(src).read()
# Exclude models of DNP footprints (footprint-aware paren matching)
if os.environ.get("HIDE_DNP"):
    out, idx = [], 0
    while True:
        j = s.find("(footprint ", idx)
        if j < 0:
            out.append(s[idx:]); break
        out.append(s[idx:j])
        depth, k = 0, j
        while k < len(s):
            c = s[k]
            if c == '(': depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0: break
            k += 1
        block = s[j:k + 1]
        if re.search(r'\(attr\b[^)]*\bdnp\b', block):
            block = block.replace('(model "', '(model "DNPHIDDEN_')
        out.append(block); idx = k + 1
    s = "".join(out)
# Break specific model paths by substring so KiCad skips them
for p in pats:
    s = s.replace(p, p + ".HIDDEN")
open(dst, "w").write(s)
PY
  # The temp copy lives elsewhere, so anchor ${KIPRJMOD} back to the real project dir.
  DEFVARS+=(--define-var "KIPRJMOD=$(cd "$(dirname "$BOARD")" && pwd)")
fi

# Shared look. Rotation angles are positive (340 = -20, 325 = -35) because kicad-cli's
# argument parser mistakes a leading-negative value for another flag.
COMMON=(--quality high --perspective --background transparent --zoom 0.9
        --width 2000 --height 1500 --rotate 340,0,325)

echo "Rendering top    -> $OUT/top-render.png"
kicad-cli pcb render -o "$OUT/top-render.png"    --side top    "${COMMON[@]}" ${DEFVARS[@]+"${DEFVARS[@]}"} "$SRC"
echo "Rendering bottom -> $OUT/bottom-render.png"
kicad-cli pcb render -o "$OUT/bottom-render.png" --side bottom "${COMMON[@]}" ${DEFVARS[@]+"${DEFVARS[@]}"} "$SRC"

[ -n "$CLEANUP" ] && rm -f "$CLEANUP"

# Tight, uniform crop around the board if ImageMagick is available.
if command -v magick >/dev/null 2>&1; then
  for f in "$OUT/top-render.png" "$OUT/bottom-render.png"; do
    magick "$f" -trim +repage -bordercolor none -border 60 "$f"
  done
  echo "Cropped renders to content."
fi

echo "Done."
