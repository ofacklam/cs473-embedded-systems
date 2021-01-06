# TCL File Generated by Component Editor 20.1
# Wed Jan 06 15:17:39 CET 2021
# DO NOT MODIFY


# 
# lcd_controller "LCD Controller" v1.0
#  2021.01.06.15:17:39
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module lcd_controller
# 
set_module_property DESCRIPTION ""
set_module_property NAME lcd_controller
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "LCD Controller"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL LCD_IP_COMPONENT
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file LCD_IP_COMPONENT.vhd VHDL PATH ../hdl/lcd_controller/LCD_IP_COMPONENT.vhd TOP_LEVEL_FILE
add_fileset_file fifo_module.vhd VHDL PATH ../hdl/lcd_controller/fifo_module.vhd
add_fileset_file lcd_controller.vhd VHDL PATH ../hdl/lcd_controller/lcd_controller.vhd
add_fileset_file master_controller.vhd VHDL PATH ../hdl/lcd_controller/master_controller.vhd
add_fileset_file register_controller.vhd VHDL PATH ../hdl/lcd_controller/register_controller.vhd


# 
# parameters
# 
add_parameter SCREEN_NUMBER_COLUMNS INTEGER 320
set_parameter_property SCREEN_NUMBER_COLUMNS DEFAULT_VALUE 320
set_parameter_property SCREEN_NUMBER_COLUMNS DISPLAY_NAME SCREEN_NUMBER_COLUMNS
set_parameter_property SCREEN_NUMBER_COLUMNS TYPE INTEGER
set_parameter_property SCREEN_NUMBER_COLUMNS UNITS None
set_parameter_property SCREEN_NUMBER_COLUMNS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property SCREEN_NUMBER_COLUMNS HDL_PARAMETER true
add_parameter SCREEN_NUMBER_LINES INTEGER 240
set_parameter_property SCREEN_NUMBER_LINES DEFAULT_VALUE 240
set_parameter_property SCREEN_NUMBER_LINES DISPLAY_NAME SCREEN_NUMBER_LINES
set_parameter_property SCREEN_NUMBER_LINES TYPE INTEGER
set_parameter_property SCREEN_NUMBER_LINES UNITS None
set_parameter_property SCREEN_NUMBER_LINES ALLOWED_RANGES -2147483648:2147483647
set_parameter_property SCREEN_NUMBER_LINES HDL_PARAMETER true
add_parameter PIXEL_SIZE INTEGER 16
set_parameter_property PIXEL_SIZE DEFAULT_VALUE 16
set_parameter_property PIXEL_SIZE DISPLAY_NAME PIXEL_SIZE
set_parameter_property PIXEL_SIZE TYPE INTEGER
set_parameter_property PIXEL_SIZE UNITS None
set_parameter_property PIXEL_SIZE ALLOWED_RANGES -2147483648:2147483647
set_parameter_property PIXEL_SIZE HDL_PARAMETER true


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

add_interface_port clock csi_clk clk Input 1


# 
# connection point clock_reset
# 
add_interface clock_reset reset end
set_interface_property clock_reset associatedClock clock
set_interface_property clock_reset synchronousEdges DEASSERT
set_interface_property clock_reset ENABLED true
set_interface_property clock_reset EXPORT_OF ""
set_interface_property clock_reset PORT_NAME_MAP ""
set_interface_property clock_reset CMSIS_SVD_VARIABLES ""
set_interface_property clock_reset SVD_ADDRESS_GROUP ""

add_interface_port clock_reset csi_reset_n reset_n Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset clock_reset
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

add_interface_port avalon_slave AS_address address Input 3
add_interface_port avalon_slave AS_write write Input 1
add_interface_port avalon_slave AS_writedata writedata Input 32
add_interface_port avalon_slave AS_read read Input 1
add_interface_port avalon_slave AS_readdata readdata Output 32
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point avalon_master_1
# 
add_interface avalon_master_1 avalon start
set_interface_property avalon_master_1 addressUnits SYMBOLS
set_interface_property avalon_master_1 associatedClock clock
set_interface_property avalon_master_1 associatedReset clock_reset
set_interface_property avalon_master_1 bitsPerSymbol 8
set_interface_property avalon_master_1 burstOnBurstBoundariesOnly false
set_interface_property avalon_master_1 burstcountUnits WORDS
set_interface_property avalon_master_1 doStreamReads false
set_interface_property avalon_master_1 doStreamWrites false
set_interface_property avalon_master_1 holdTime 0
set_interface_property avalon_master_1 linewrapBursts false
set_interface_property avalon_master_1 maximumPendingReadTransactions 0
set_interface_property avalon_master_1 maximumPendingWriteTransactions 0
set_interface_property avalon_master_1 readLatency 0
set_interface_property avalon_master_1 readWaitTime 1
set_interface_property avalon_master_1 setupTime 0
set_interface_property avalon_master_1 timingUnits Cycles
set_interface_property avalon_master_1 writeWaitTime 0
set_interface_property avalon_master_1 ENABLED true
set_interface_property avalon_master_1 EXPORT_OF ""
set_interface_property avalon_master_1 PORT_NAME_MAP ""
set_interface_property avalon_master_1 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master_1 SVD_ADDRESS_GROUP ""

add_interface_port avalon_master_1 AM_address address Output 32
add_interface_port avalon_master_1 AM_read read Output 1
add_interface_port avalon_master_1 AM_readdata readdata Input 32
add_interface_port avalon_master_1 AM_burstcount burstcount Output 8
add_interface_port avalon_master_1 AM_waitreq waitrequest Input 1
add_interface_port avalon_master_1 AM_readdatavalid readdatavalid Input 1


# 
# connection point synchro_conduct
# 
add_interface synchro_conduct conduit end
set_interface_property synchro_conduct associatedClock clock
set_interface_property synchro_conduct associatedReset ""
set_interface_property synchro_conduct ENABLED true
set_interface_property synchro_conduct EXPORT_OF ""
set_interface_property synchro_conduct PORT_NAME_MAP ""
set_interface_property synchro_conduct CMSIS_SVD_VARIABLES ""
set_interface_property synchro_conduct SVD_ADDRESS_GROUP ""

add_interface_port synchro_conduct Camera_Writing_Buffer capturing Input 4
add_interface_port synchro_conduct Lcd_Reading_Buffer displaying Output 4


# 
# connection point lcd_output
# 
add_interface lcd_output conduit end
set_interface_property lcd_output associatedClock clock
set_interface_property lcd_output associatedReset ""
set_interface_property lcd_output ENABLED true
set_interface_property lcd_output EXPORT_OF ""
set_interface_property lcd_output PORT_NAME_MAP ""
set_interface_property lcd_output CMSIS_SVD_VARIABLES ""
set_interface_property lcd_output SVD_ADDRESS_GROUP ""

add_interface_port lcd_output CSX csx Output 1
add_interface_port lcd_output D d Output 16
add_interface_port lcd_output DCX dcx Output 1
add_interface_port lcd_output LCD_ON lcd_on Output 1
add_interface_port lcd_output RDX rdx Output 1
add_interface_port lcd_output RESX resx Output 1
add_interface_port lcd_output WRX wrx Output 1
