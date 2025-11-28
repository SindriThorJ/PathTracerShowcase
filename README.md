# PathTracer Showcase
PathTracer is a motion-tracking device that reconstructs the 3D path of swung objects (primarily golf clubs) to deliver measurable, repeatable swing analytics.

## Why PathTracer
- Video alone is 2D, lens-dependent, and subjective. PathTracer records true 3D motion at high resolution, turning "looks wrong" into precise metrics.
- Works for golf swings, barbell paths, and any motion where path accuracy matters.
- Lets you overlay your swing with reference data to see exactly where you deviate.

## Hardware and performance
- Core: nRF54L15 SoC with ICM-45686 IMU and LIS2MDL magnetometer.
- Power: TPS62840-based power path, rechargeable Li-Po cell, 1.8 V VDD for efficiency.
- Capture: 1600 Hz sampling (~51.2 kB/s) for acceleration and rotation, written directly to high-speed QSPI flash.
- Transfer: BLE offload to mobile/desktop for post-processing.
- Outputs: 3D path visualization, velocity, acceleration, rotation, swing tempo, and other derived metrics.

## Visuals
- Renders and prototypes  
![Front render](3D/Front.jpg)
![Back render](3D/Back.jpg)
![Case prototype - front](CAD/Case%20Prototype%20Front.png)
![Case prototype - back](CAD/Case%20Prototype%20Back.png)
![Mounted on club](CAD/On%20club1.png)

- PCB stackup (4-layer)  
![Layer 1](PCB%20Views/Info%20L1.png)
![Layer 2](PCB%20Views/L2.png)
![Layer 3](PCB%20Views/L3.png)
![Layer 4](PCB%20Views/Info%20L4.png)

- Schematic overview  
![Schematic overview](Schematic/PathTracer_page-0001.jpg)

- Real-world build (SD card for scale)  
![Front photo](Real%20Life/real_front.jpg)
![Back photo](Real%20Life/real_back.jpg)
