########################################################
# Sample i2c design for CS-473 Embedded Systems course #
########################################################

Supplied files
==============

    i2c_sample_design
    ├── demo_code
    │   ├── demo.c
    │   └── i2c
    │       ├── i2c.c
    │       ├── i2c.h
    │       ├── i2c_io.h
    │       └── i2c_regs.h
    ├── i2c
    │   ├── hdl
    │   │   ├── i2c_clkgen.vhd
    │   │   ├── i2c_core.vhd
    │   │   └── i2c_interface.vhd
    │   └── i2c_hw.tcl
    └── README.txt

How to use
==========
    1) To use the design, create an "ip/" folder inside your quartus project
       directory, and copy the following folder inside.

           i2c
           ├── hdl
           │   ├── i2c_clkgen.vhd
           │   ├── i2c_core.vhd
           │   └── i2c_interface.vhd
           └── i2c_hw.tcl

       Example project directory after copying the above-mentioned i2c/ folder in the ip/ folder
       =========================================================================================

           camera_controller
           ├── hw
           │   ├── modelsim
           │   ├── hdl
           │   │   └── DE0_Nano_SoC_top_level.vhd
           │   └── quartus
           │       └── ip                              |
           │           └── i2c                         | IP VHDL
           │               ├── hdl                     | FILES
           │               │   ├── i2c_clkgen.vhd      | ADDED
           │               │   ├── i2c_core.vhd        | HERE
           │               │   └── i2c_interface.vhd   |
           │               └── i2c_hw.tcl              |
           └── sw
               ├── camera_acquisition
               │   ├── demo.c
               │   └── i2c                             | IP .c & .h
               │       ├── i2c.c                       | FILES
               │       ├── i2c.h                       | ADDED
               │       ├── i2c_io.h                    | HERE
               │       └── i2c_regs.h                  |
               └── camera_acquisition_bsp

    2) Open Qsys

    3) The design is available in the IP catalog and can be instantiated.
