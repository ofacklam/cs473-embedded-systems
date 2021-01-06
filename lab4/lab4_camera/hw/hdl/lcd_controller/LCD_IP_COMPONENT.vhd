library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;



entity LCD_IP_COMPONENT is
    generic(
        SCREEN_NUMBER_COLUMNS : integer := 320;
        SCREEN_NUMBER_LINES : integer := 240;
        PIXEL_SIZE : integer := 16);
	port(
        -- CLOCK AND RESET_N
		csi_clk : in std_logic;
		csi_reset_n : in std_logic;
		
        -- Interface to LCD
		LCD_ON : out std_logic;
		CSX : out std_logic;
		RESX : out std_logic;
		DCX : out std_logic;
		WRX : out std_logic;
		RDX : out std_logic;
        D : out std_logic_vector(15 downto 0);

        -- AVALON SLAVE
        AS_address : in std_logic_vector(2 downto 0);
		AS_write : in std_logic;
		AS_writedata : in std_logic_vector(31 downto 0);
		AS_read : in std_logic;
        AS_readdata : out std_logic_vector(31 downto 0);
        
        -- AVALON MASTER
        AM_address              : out   std_logic_vector(31 downto 0);
        AM_read                 : out   std_logic;
        AM_readdata             : in    std_logic_vector(31 downto 0);
        AM_burstcount           : out   std_logic_vector(7 downto 0);
        AM_waitreq              : in    std_logic;
        AM_readdatavalid        : in    std_logic;

        -- CAMERA CONDUCTS
        Camera_Writing_Buffer   : in    std_logic_vector(3 downto 0);
        Lcd_Reading_Buffer      : out    std_logic_vector(3 downto 0)
        
	);
end LCD_IP_COMPONENT;



architecture lcdc_comp of LCD_IP_COMPONENT is

    component master_controller is
        port (
        csi_clk                     : in std_logic;
        csi_reset_n                 : in std_logic;
        AM_address              : out   std_logic_vector(31 downto 0);
        AM_read                 : out   std_logic;
        AM_readdata             : in    std_logic_vector(31 downto 0);
        AM_burstcount           : out   std_logic_vector(7 downto 0);
        AM_waitreq              : in    std_logic;
        AM_readdatavalid        : in    std_logic;
        Camera_Writing_Buffer   : in    std_logic_vector(3 downto 0);
        Lcd_Reading_Buffer      : out    std_logic_vector(3 downto 0);
        fps                     : in std_logic_vector(7 downto 0);
        buff_addr               : in std_logic_vector(31 downto 0);
        enabled                 : in std_logic;
        fifo_writereq              : out std_logic;
        fifo_writedata          : out std_logic_vector(31 downto 0);
        fifo_wrusedw		    : in STD_LOGIC_VECTOR (8 DOWNTO 0)
        );
    end component master_controller;

    component lcd_controller is
        port (
        clk : in std_logic;
        reset_n : in std_logic;
        fifo_readreq : inout std_logic;
        fifo_readdata : in std_logic_vector(15 downto 0);
        fifo_empty : in std_logic;
        lcdc_enabled : in std_logic;
        lcdc_dcx : in std_logic;
        lcdc_busy : out std_logic;
        lcdc_data : in std_logic_vector(15 downto 0);
        fps_sig : in std_logic_vector(7 downto 0);
        lcdc_flipflop : in std_logic;
        LCD_ON : out std_logic;
        CSX : out std_logic;
        RESX : out std_logic;
        DCX : out std_logic;
        WRX : out std_logic;
        RDX : out std_logic;
        D : out std_logic_vector(15 downto 0));
    end component lcd_controller;

    component register_controller is
        port (
        csi_clk                     : in std_logic;
        csi_reset_n                 : in std_logic;
        AS_address : in std_logic_vector(2 downto 0);
		AS_write : in std_logic;
		AS_writedata : in std_logic_vector(31 downto 0);
		AS_read : in std_logic;
		AS_readdata : out std_logic_vector(31 downto 0);
        FAMESEC                     : out std_logic_vector(7 downto 0);
        BUFFADDR               : out std_logic_vector(31 downto 0);
        enabled                 : out std_logic;
        lcdc_dcx                : out std_logic;
        lcdc_data               : out std_logic_vector(15 downto 0);
        lcdc_busy               : in std_logic;
        lcdc_flipflop          : out std_logic);
    end component register_controller;

    component fifo_module is
        port (
        data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
        rdclk		: IN STD_LOGIC ;
        rdreq		: IN STD_LOGIC ;
        wrclk		: IN STD_LOGIC ;
        wrreq		: IN STD_LOGIC ;
        q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        rdempty		: OUT STD_LOGIC ;
        wrusedw		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0));
    end component fifo_module;

    signal fifo_read, fifo_writereq, fifo_empty, enabled, lcdc_dcx, lcdc_busy, lcdc_flipflop : std_logic;
    signal fps : std_logic_vector(7 downto 0);
    signal lcdc_data, fifo_readdata : std_logic_vector(15 downto 0);
    signal fifo_writedata, buff_addr : std_logic_vector(31 downto 0);
    signal fifo_wrusedw : std_logic_vector(8 downto 0);
    
begin

    fifo_submodule : component fifo_module
    port map (
                data => fifo_writedata,
                rdclk => csi_clk,
                rdreq => fifo_read,
                wrclk => csi_clk,
                wrreq => fifo_writereq,
                q => fifo_readdata,
                rdempty	 => fifo_empty,
                wrusedw	 => fifo_wrusedw
            );
    
    master_controller_submodule : component master_controller
	port map (
                csi_clk => csi_clk,
				csi_reset_n => csi_reset_n,
				AM_address => AM_address,
				AM_read => AM_read,
				AM_readdata => AM_readdata,
				AM_waitreq => AM_waitreq,
				AM_burstcount => AM_burstcount,
				AM_readdatavalid => AM_readdatavalid,
				Camera_Writing_Buffer => Camera_Writing_Buffer,
				Lcd_Reading_Buffer => Lcd_Reading_Buffer,
				fps => fps,
				buff_addr => buff_addr,
				fifo_writereq => fifo_writereq,
				fifo_writedata => fifo_writedata,
				fifo_wrusedw => fifo_wrusedw,
                enabled => enabled
            );

    register_controller_submodule : component register_controller
    port map (
                csi_clk => csi_clk,
                csi_reset_n => csi_reset_n,
                AS_address => AS_address,
                AS_write => AS_write,
                AS_writedata => AS_writedata,
                AS_read => AS_read,
                AS_readdata => AS_readdata,
                FAMESEC => fps,
                BUFFADDR => buff_addr,
                enabled => enabled,
                lcdc_dcx => lcdc_dcx,
                lcdc_data => lcdc_data,
                lcdc_busy => lcdc_busy,
                lcdc_flipflop => lcdc_flipflop
            );

    lcd_controller_submodule : component lcd_controller
    port map (
                clk => csi_clk,
                reset_n => csi_reset_n,
                fifo_readreq => fifo_read,
                fifo_readdata => fifo_readdata,
                fifo_empty => fifo_empty,
                lcdc_enabled => enabled,
                lcdc_dcx => lcdc_dcx,
                lcdc_flipflop => lcdc_flipflop,
                lcdc_data => lcdc_data,
                fps_sig => fps,
                lcdc_busy => lcdc_busy,
                LCD_ON => LCD_ON,
                CSX => CSX,
                RESX => RESX,
                DCX => DCX,
                WRX => WRX,
                RDX => RDX,
                D => D
            );
    
end lcdc_comp;