# TCL File Generated by Component Editor 18.1
# Mon Jan 04 15:50:35 CET 2021
# DO NOT MODIFY


# 
# CameraController "Camera Controller for TRDB-D5M" v1.0
#  2021.01.04.15:50:35
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module CameraController
# 
set_module_property DESCRIPTION ""
set_module_property NAME CameraController
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Camera Controller for TRDB-D5M"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL CameraController
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file buffer_sm.vhd VHDL PATH ../hdl/camera_controller/comp/buffer_sm.vhd
add_fileset_file cam_interface.vhd VHDL PATH ../hdl/camera_controller/comp/cam_interface.vhd
add_fileset_file camera_controller.vhd VHDL PATH ../hdl/camera_controller/comp/camera_controller.vhd TOP_LEVEL_FILE
add_fileset_file dma.vhd VHDL PATH ../hdl/camera_controller/comp/dma.vhd
add_fileset_file fsm.vhd VHDL PATH ../hdl/camera_controller/comp/fsm.vhd
add_fileset_file pixel_merger.vhd VHDL PATH ../hdl/camera_controller/comp/pixel_merger.vhd
add_fileset_file registers.vhd VHDL PATH ../hdl/camera_controller/comp/registers.vhd
add_fileset_file double_clk_fifo.vhd VHDL PATH ../hdl/camera_controller/ip/double_clk_fifo.vhd
add_fileset_file single_clk_fifo.vhd VHDL PATH ../hdl/camera_controller/ip/single_clk_fifo.vhd


# 
# parameters
# 
add_parameter maxBuffers POSITIVE 4
set_parameter_property maxBuffers DEFAULT_VALUE 4
set_parameter_property maxBuffers DISPLAY_NAME maxBuffers
set_parameter_property maxBuffers TYPE POSITIVE
set_parameter_property maxBuffers UNITS None
set_parameter_property maxBuffers HDL_PARAMETER true
add_parameter burstsize POSITIVE 80 ""
set_parameter_property burstsize DEFAULT_VALUE 80
set_parameter_property burstsize DISPLAY_NAME burstsize
set_parameter_property burstsize WIDTH ""
set_parameter_property burstsize TYPE POSITIVE
set_parameter_property burstsize UNITS None
set_parameter_property burstsize ALLOWED_RANGES 1:2147483647
set_parameter_property burstsize DESCRIPTION ""
set_parameter_property burstsize HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset nReset reset_n Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset reset
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave AS_address address Input 1
add_interface_port avalon_slave AS_read read Input 1
add_interface_port avalon_slave AS_readdata readdata Output 32
add_interface_port avalon_slave AS_write write Input 1
add_interface_port avalon_slave AS_writedata writedata Input 32
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point avalon_master
# 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock
set_interface_property avalon_master associatedReset reset
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master maximumPendingWriteTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master AM_address address Output 32
add_interface_port avalon_master AM_write write Output 1
add_interface_port avalon_master AM_writedata writedata Output 32
add_interface_port avalon_master AM_burstcount burstcount Output 8
add_interface_port avalon_master AM_waitreq waitrequest Input 1


# 
# connection point camera_conduit
# 
add_interface camera_conduit conduit end
set_interface_property camera_conduit associatedClock clock
set_interface_property camera_conduit associatedReset reset
set_interface_property camera_conduit ENABLED true
set_interface_property camera_conduit EXPORT_OF ""
set_interface_property camera_conduit PORT_NAME_MAP ""
set_interface_property camera_conduit CMSIS_SVD_VARIABLES ""
set_interface_property camera_conduit SVD_ADDRESS_GROUP ""

add_interface_port camera_conduit fval framevalid Input 1
add_interface_port camera_conduit lval linevalid Input 1
add_interface_port camera_conduit pixclk clk Input 1
add_interface_port camera_conduit data data Input 12


# 
# connection point synchro_conduit
# 
add_interface synchro_conduit conduit end
set_interface_property synchro_conduit associatedClock clock
set_interface_property synchro_conduit associatedReset reset
set_interface_property synchro_conduit ENABLED true
set_interface_property synchro_conduit EXPORT_OF ""
set_interface_property synchro_conduit PORT_NAME_MAP ""
set_interface_property synchro_conduit CMSIS_SVD_VARIABLES ""
set_interface_property synchro_conduit SVD_ADDRESS_GROUP ""

add_interface_port synchro_conduit bufferCapt capturing Output 4
add_interface_port synchro_conduit bufferDisp displaying Input maxbuffers

