#################################################################################
# Sample cmos_sensor_output_generator design for CS-473 Embedded Systems course #
#################################################################################

Supplied files
==============

    cmos_sensor_output_generator_sample_design
    ├── cmos_sensor_output_generator
    │   ├── cmos_sensor_output_generator_hw.tcl
    │   ├── hdl
    │   │   ├── cmos_sensor_output_generator_constants.vhd
    │   │   └── cmos_sensor_output_generator.vhd
    │   └── tb
    │       └── tb_cmos_sensor_output_generator.vhd
    ├── cmos_sensor_output_generator.pdf
    ├── demo_code
    │   ├── cmos_sensor_output_generator
    │   │   ├── cmos_sensor_output_generator.c
    │   │   ├── cmos_sensor_output_generator.h
    │   │   ├── cmos_sensor_output_generator_io.h
    │   │   └── cmos_sensor_output_generator_regs.h
    │   └── demo.c
    └── README.txt

    Please read cmos_sensor_output_generator.pdf to know how to correctly
    program the controller.

How to use
==========
    1) To use the design, create an "ip/" folder inside your quartus project
       directory, and copy the following folder inside.

           cmos_sensor_output_generator
           ├── cmos_sensor_output_generator_hw.tcl
           └── hdl
               ├── cmos_sensor_output_generator_constants.vhd
               └── cmos_sensor_output_generator.vhd

       Example project directory after copying the above-mentioned i2c/ folder in the ip/ folder
       =========================================================================================

           camera_controller
           ├── hw
           │   ├── modelsim
           │   ├── hdl
           │   │   └── DE0_Nano_top_level.vhd
           │   └── quartus
           │       └── ip                                                     |
           │           └── cmos_sensor_output_generator                       | IP VHDL
           │               ├── cmos_sensor_output_generator_hw.tcl            | FILES
           │               └── hdl                                            | ADDED
           │                   ├── cmos_sensor_output_generator_constants.vhd | HERE
           │                   └── cmos_sensor_output_generator.vhd           |
           └── sw
               ├── camera_acquisition                                         |
               │   ├── cmos_sensor_output_generator                           | IP .c & .h
               │   │   ├── cmos_sensor_output_generator.c                     | FILES
               │   │   ├── cmos_sensor_output_generator.h                     | ADDED
               │   │   ├── cmos_sensor_output_generator_io.h                  | HERE
               │   │   └── cmos_sensor_output_generator_regs.h                |
               │   └── demo.c
               └── camera_acquisition_bsp

    2) Open Qsys

    3) The design is available in the IP catalog and can be instantiated.
