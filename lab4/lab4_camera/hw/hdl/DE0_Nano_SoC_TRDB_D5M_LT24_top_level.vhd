-- #############################################################################
-- DE0_Nano_SoC_TRDB_D5M_LT24_top_level.vhd
--
-- BOARD         : DE0-Nano-SoC from Terasic
-- Author        : Sahand Kashani-Akhavan from Terasic documentation
-- Revision      : 1.3
-- Creation date : 11/06/2015
--
-- Syntax Rule : GROUP_NAME_N[bit]
--
-- GROUP : specify a particular interface (ex: SDR_)
-- NAME  : signal name (ex: CONFIG, D, ...)
-- bit   : signal index
-- _N    : to specify an active-low signal
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity DE0_Nano_SoC_TRDB_D5M_LT24_top_level is
    port(
        -- ADC
        ADC_CONVST : out std_logic;
        ADC_SCK    : out std_logic;
        ADC_SDI    : out std_logic;
        ADC_SDO    : in  std_logic;

        -- ARDUINO
        ARDUINO_IO      : inout std_logic_vector(15 downto 0);
        ARDUINO_RESET_N : inout std_logic;

        -- CLOCK
        FPGA_CLK1_50 : in std_logic;
        FPGA_CLK2_50 : in std_logic;
        FPGA_CLK3_50 : in std_logic;

        -- KEY
        KEY_N : in std_logic_vector(1 downto 0);

        -- LED
        LED : out std_logic_vector(7 downto 0);

        -- SW
        SW : in std_logic_vector(3 downto 0);

        -- GPIO_0
        GPIO_0_LT24_ADC_BUSY     : in  std_logic;
        GPIO_0_LT24_ADC_CS_N     : out std_logic;
        GPIO_0_LT24_ADC_DCLK     : out std_logic;
        GPIO_0_LT24_ADC_DIN      : out std_logic;
        GPIO_0_LT24_ADC_DOUT     : in  std_logic;
        GPIO_0_LT24_ADC_PENIRQ_N : in  std_logic;
        GPIO_0_LT24_CS_N         : out std_logic;
        GPIO_0_LT24_D            : out std_logic_vector(15 downto 0);
        GPIO_0_LT24_LCD_ON       : out std_logic;
        GPIO_0_LT24_RD_N         : out std_logic;
        GPIO_0_LT24_RESET_N      : out std_logic;
        GPIO_0_LT24_RS           : out std_logic;
        GPIO_0_LT24_WR_N         : out std_logic;

        -- GPIO_1
        GPIO_1_D5M_D       : in    std_logic_vector(11 downto 0);
        GPIO_1_D5M_FVAL    : in    std_logic;
        GPIO_1_D5M_LVAL    : in    std_logic;
        GPIO_1_D5M_PIXCLK  : in    std_logic;
        GPIO_1_D5M_RESET_N : out   std_logic;
        GPIO_1_D5M_SCLK    : inout std_logic;
        GPIO_1_D5M_SDATA   : inout std_logic;
        GPIO_1_D5M_STROBE  : in    std_logic;
        GPIO_1_D5M_TRIGGER : out   std_logic;
        GPIO_1_D5M_XCLKIN  : out   std_logic;

        -- HPS
        HPS_CONV_USB_N   : inout std_logic;
        HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
        HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
        HPS_DDR3_CAS_N   : out   std_logic;
        HPS_DDR3_CK_N    : out   std_logic;
        HPS_DDR3_CK_P    : out   std_logic;
        HPS_DDR3_CKE     : out   std_logic;
        HPS_DDR3_CS_N    : out   std_logic;
        HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
        HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_ODT     : out   std_logic;
        HPS_DDR3_RAS_N   : out   std_logic;
        HPS_DDR3_RESET_N : out   std_logic;
        HPS_DDR3_RZQ     : in    std_logic;
        HPS_DDR3_WE_N    : out   std_logic;
        HPS_ENET_GTX_CLK : out   std_logic;
        HPS_ENET_INT_N   : inout std_logic;
        HPS_ENET_MDC     : out   std_logic;
        HPS_ENET_MDIO    : inout std_logic;
        HPS_ENET_RX_CLK  : in    std_logic;
        HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
        HPS_ENET_RX_DV   : in    std_logic;
        HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
        HPS_ENET_TX_EN   : out   std_logic;
        HPS_GSENSOR_INT  : inout std_logic;
        HPS_I2C0_SCLK    : inout std_logic;
        HPS_I2C0_SDAT    : inout std_logic;
        HPS_I2C1_SCLK    : inout std_logic;
        HPS_I2C1_SDAT    : inout std_logic;
        HPS_KEY_N        : inout std_logic;
        HPS_LED          : inout std_logic;
        HPS_LTC_GPIO     : inout std_logic;
        HPS_SD_CLK       : out   std_logic;
        HPS_SD_CMD       : inout std_logic;
        HPS_SD_DATA      : inout std_logic_vector(3 downto 0);
        HPS_SPIM_CLK     : out   std_logic;
        HPS_SPIM_MISO    : in    std_logic;
        HPS_SPIM_MOSI    : out   std_logic;
        HPS_SPIM_SS      : inout std_logic;
        HPS_UART_RX      : in    std_logic;
        HPS_UART_TX      : out   std_logic;
        HPS_USB_CLKOUT   : in    std_logic;
        HPS_USB_DATA     : inout std_logic_vector(7 downto 0);
        HPS_USB_DIR      : in    std_logic;
        HPS_USB_NXT      : in    std_logic;
        HPS_USB_STP      : out   std_logic
    );
end entity DE0_Nano_SoC_TRDB_D5M_LT24_top_level;

architecture rtl of DE0_Nano_SoC_TRDB_D5M_LT24_top_level is

    component soc_system is
		port (
			cameracontroller_0_camera_conduit_framevalid           : in    std_logic                     := 'X';             -- framevalid
			cameracontroller_0_camera_conduit_linevalid            : in    std_logic                     := 'X';             -- linevalid
			cameracontroller_0_camera_conduit_clk                  : in    std_logic                     := 'X';             -- clk
			cameracontroller_0_camera_conduit_data                 : in    std_logic_vector(11 downto 0) := (others => 'X'); -- data
			cameracontroller_0_synchro_conduit_capturing           : out   std_logic_vector(3 downto 0);                     -- capturing
			cameracontroller_0_synchro_conduit_displaying          : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- displaying
			clk_clk                                                : in    std_logic                     := 'X';             -- clk
			cmos_sensor_output_generator_0_cmos_sensor_frame_valid : out   std_logic;                                        -- frame_valid
			cmos_sensor_output_generator_0_cmos_sensor_line_valid  : out   std_logic;                                        -- line_valid
			cmos_sensor_output_generator_0_cmos_sensor_data        : out   std_logic_vector(11 downto 0);                    -- data
			hps_0_ddr_mem_a                                        : out   std_logic_vector(14 downto 0);                    -- mem_a
			hps_0_ddr_mem_ba                                       : out   std_logic_vector(2 downto 0);                     -- mem_ba
			hps_0_ddr_mem_ck                                       : out   std_logic;                                        -- mem_ck
			hps_0_ddr_mem_ck_n                                     : out   std_logic;                                        -- mem_ck_n
			hps_0_ddr_mem_cke                                      : out   std_logic;                                        -- mem_cke
			hps_0_ddr_mem_cs_n                                     : out   std_logic;                                        -- mem_cs_n
			hps_0_ddr_mem_ras_n                                    : out   std_logic;                                        -- mem_ras_n
			hps_0_ddr_mem_cas_n                                    : out   std_logic;                                        -- mem_cas_n
			hps_0_ddr_mem_we_n                                     : out   std_logic;                                        -- mem_we_n
			hps_0_ddr_mem_reset_n                                  : out   std_logic;                                        -- mem_reset_n
			hps_0_ddr_mem_dq                                       : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
			hps_0_ddr_mem_dqs                                      : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
			hps_0_ddr_mem_dqs_n                                    : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
			hps_0_ddr_mem_odt                                      : out   std_logic;                                        -- mem_odt
			hps_0_ddr_mem_dm                                       : out   std_logic_vector(3 downto 0);                     -- mem_dm
			hps_0_ddr_oct_rzqin                                    : in    std_logic                     := 'X';             -- oct_rzqin
			hps_0_io_hps_io_emac1_inst_TX_CLK                      : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
			hps_0_io_hps_io_emac1_inst_TXD0                        : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
			hps_0_io_hps_io_emac1_inst_TXD1                        : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
			hps_0_io_hps_io_emac1_inst_TXD2                        : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
			hps_0_io_hps_io_emac1_inst_TXD3                        : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
			hps_0_io_hps_io_emac1_inst_RXD0                        : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
			hps_0_io_hps_io_emac1_inst_MDIO                        : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
			hps_0_io_hps_io_emac1_inst_MDC                         : out   std_logic;                                        -- hps_io_emac1_inst_MDC
			hps_0_io_hps_io_emac1_inst_RX_CTL                      : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
			hps_0_io_hps_io_emac1_inst_TX_CTL                      : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
			hps_0_io_hps_io_emac1_inst_RX_CLK                      : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
			hps_0_io_hps_io_emac1_inst_RXD1                        : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
			hps_0_io_hps_io_emac1_inst_RXD2                        : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
			hps_0_io_hps_io_emac1_inst_RXD3                        : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
			hps_0_io_hps_io_sdio_inst_CMD                          : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
			hps_0_io_hps_io_sdio_inst_D0                           : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
			hps_0_io_hps_io_sdio_inst_D1                           : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
			hps_0_io_hps_io_sdio_inst_CLK                          : out   std_logic;                                        -- hps_io_sdio_inst_CLK
			hps_0_io_hps_io_sdio_inst_D2                           : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
			hps_0_io_hps_io_sdio_inst_D3                           : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
			hps_0_io_hps_io_usb1_inst_D0                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
			hps_0_io_hps_io_usb1_inst_D1                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
			hps_0_io_hps_io_usb1_inst_D2                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
			hps_0_io_hps_io_usb1_inst_D3                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
			hps_0_io_hps_io_usb1_inst_D4                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
			hps_0_io_hps_io_usb1_inst_D5                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
			hps_0_io_hps_io_usb1_inst_D6                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
			hps_0_io_hps_io_usb1_inst_D7                           : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
			hps_0_io_hps_io_usb1_inst_CLK                          : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
			hps_0_io_hps_io_usb1_inst_STP                          : out   std_logic;                                        -- hps_io_usb1_inst_STP
			hps_0_io_hps_io_usb1_inst_DIR                          : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
			hps_0_io_hps_io_usb1_inst_NXT                          : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
			hps_0_io_hps_io_spim1_inst_CLK                         : out   std_logic;                                        -- hps_io_spim1_inst_CLK
			hps_0_io_hps_io_spim1_inst_MOSI                        : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
			hps_0_io_hps_io_spim1_inst_MISO                        : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
			hps_0_io_hps_io_spim1_inst_SS0                         : out   std_logic;                                        -- hps_io_spim1_inst_SS0
			hps_0_io_hps_io_uart0_inst_RX                          : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
			hps_0_io_hps_io_uart0_inst_TX                          : out   std_logic;                                        -- hps_io_uart0_inst_TX
			hps_0_io_hps_io_i2c0_inst_SDA                          : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SDA
			hps_0_io_hps_io_i2c0_inst_SCL                          : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SCL
			hps_0_io_hps_io_i2c1_inst_SDA                          : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SDA
			hps_0_io_hps_io_i2c1_inst_SCL                          : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SCL
			hps_0_io_hps_io_gpio_inst_GPIO09                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO09
			hps_0_io_hps_io_gpio_inst_GPIO35                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO35
			hps_0_io_hps_io_gpio_inst_GPIO40                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO40
			hps_0_io_hps_io_gpio_inst_GPIO53                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO53
			hps_0_io_hps_io_gpio_inst_GPIO54                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO54
			hps_0_io_hps_io_gpio_inst_GPIO61                       : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO61
			i2c_0_i2c_scl                                          : inout std_logic                     := 'X';             -- scl
			i2c_0_i2c_sda                                          : inout std_logic                     := 'X';             -- sda
			pio_leds_external_connection_export                    : out   std_logic_vector(7 downto 0);                     -- export
			reset_reset_n                                          : in    std_logic                     := 'X'              -- reset_n
		);
    end component soc_system;
    
    signal framevalid:      std_logic;
    signal linevalid:       std_logic;
    signal data:            std_logic_vector(11 downto 0);
    signal displaying:     std_logic_vector(3 downto 0);
    signal capturing:       std_logic_vector(3 downto 0);

begin

    displaying(0) <= not KEY_N(1);

    u0 : component soc_system
    port map (
        cameracontroller_0_camera_conduit_framevalid           => framevalid,           --          cameracontroller_0_camera_conduit.framevalid
        cameracontroller_0_camera_conduit_linevalid            => linevalid,            --                                           .linevalid
        cameracontroller_0_camera_conduit_clk                  => FPGA_CLK1_50,                  --                                           .clk
        cameracontroller_0_camera_conduit_data                 => data,                 --                                           .data
        cameracontroller_0_synchro_conduit_capturing           => capturing,           --         cameracontroller_0_synchro_conduit.capturing
        cameracontroller_0_synchro_conduit_displaying          => displaying,          --                                           .displaying
        clk_clk                                                => FPGA_CLK1_50,                                                --                                        clk.clk
        cmos_sensor_output_generator_0_cmos_sensor_frame_valid => framevalid, -- cmos_sensor_output_generator_0_cmos_sensor.frame_valid
        cmos_sensor_output_generator_0_cmos_sensor_line_valid  => linevalid,  --                                           .line_valid
        cmos_sensor_output_generator_0_cmos_sensor_data        => data,        --                                           .data
        hps_0_ddr_mem_a                                        => HPS_DDR3_ADDR,                                        --                                  hps_0_ddr.mem_a
        hps_0_ddr_mem_ba                                       => HPS_DDR3_BA,                                       --                                           .mem_ba
        hps_0_ddr_mem_ck                                       => HPS_DDR3_CK_P,                                       --                                           .mem_ck
        hps_0_ddr_mem_ck_n                                     => HPS_DDR3_CK_N,                                     --                                           .mem_ck_n
        hps_0_ddr_mem_cke                                      => HPS_DDR3_CKE,                                      --                                           .mem_cke
        hps_0_ddr_mem_cs_n                                     => HPS_DDR3_CS_N,                                     --                                           .mem_cs_n
        hps_0_ddr_mem_ras_n                                    => HPS_DDR3_RAS_N,                                    --                                           .mem_ras_n
        hps_0_ddr_mem_cas_n                                    => HPS_DDR3_CAS_N,                                    --                                           .mem_cas_n
        hps_0_ddr_mem_we_n                                     => HPS_DDR3_WE_N,                                     --                                           .mem_we_n
        hps_0_ddr_mem_reset_n                                  => HPS_DDR3_RESET_N,                                  --                                           .mem_reset_n
        hps_0_ddr_mem_dq                                       => HPS_DDR3_DQ,                                       --                                           .mem_dq
        hps_0_ddr_mem_dqs                                      => HPS_DDR3_DQS_P,                                      --                                           .mem_dqs
        hps_0_ddr_mem_dqs_n                                    => HPS_DDR3_DQS_N,                                    --                                           .mem_dqs_n
        hps_0_ddr_mem_odt                                      => HPS_DDR3_ODT,                                      --                                           .mem_odt
        hps_0_ddr_mem_dm                                       => HPS_DDR3_DM,                                       --                                           .mem_dm
        hps_0_ddr_oct_rzqin                                    => HPS_DDR3_RZQ,                                    --                                           .oct_rzqin
        hps_0_io_hps_io_emac1_inst_TX_CLK                      => HPS_ENET_GTX_CLK,                      --                                   hps_0_io.hps_io_emac1_inst_TX_CLK
        hps_0_io_hps_io_emac1_inst_TXD0                        => HPS_ENET_TX_DATA(0),                        --                                           .hps_io_emac1_inst_TXD0
        hps_0_io_hps_io_emac1_inst_TXD1                        => HPS_ENET_TX_DATA(1),                        --                                           .hps_io_emac1_inst_TXD1
        hps_0_io_hps_io_emac1_inst_TXD2                        => HPS_ENET_TX_DATA(2),                        --                                           .hps_io_emac1_inst_TXD2
        hps_0_io_hps_io_emac1_inst_TXD3                        => HPS_ENET_TX_DATA(3),                        --                                           .hps_io_emac1_inst_TXD3
        hps_0_io_hps_io_emac1_inst_RXD0                        => HPS_ENET_RX_DATA(0),                        --                                           .hps_io_emac1_inst_RXD0
        hps_0_io_hps_io_emac1_inst_MDIO                        => HPS_ENET_MDIO,                        --                                           .hps_io_emac1_inst_MDIO
        hps_0_io_hps_io_emac1_inst_MDC                         => HPS_ENET_MDC,                         --                                           .hps_io_emac1_inst_MDC
        hps_0_io_hps_io_emac1_inst_RX_CTL                      => HPS_ENET_RX_DV,                      --                                           .hps_io_emac1_inst_RX_CTL
        hps_0_io_hps_io_emac1_inst_TX_CTL                      => HPS_ENET_TX_EN,                      --                                           .hps_io_emac1_inst_TX_CTL
        hps_0_io_hps_io_emac1_inst_RX_CLK                      => HPS_ENET_RX_CLK,                      --                                           .hps_io_emac1_inst_RX_CLK
        hps_0_io_hps_io_emac1_inst_RXD1                        => HPS_ENET_RX_DATA(1),                        --                                           .hps_io_emac1_inst_RXD1
        hps_0_io_hps_io_emac1_inst_RXD2                        => HPS_ENET_RX_DATA(2),                        --                                           .hps_io_emac1_inst_RXD2
        hps_0_io_hps_io_emac1_inst_RXD3                        => HPS_ENET_RX_DATA(3),                        --                                           .hps_io_emac1_inst_RXD3
        hps_0_io_hps_io_sdio_inst_CMD                          => HPS_SD_CMD,                          --                                           .hps_io_sdio_inst_CMD
        hps_0_io_hps_io_sdio_inst_D0                           => HPS_SD_DATA(0),                           --                                           .hps_io_sdio_inst_D0
        hps_0_io_hps_io_sdio_inst_D1                           => HPS_SD_DATA(1),                           --                                           .hps_io_sdio_inst_D1
        hps_0_io_hps_io_sdio_inst_CLK                          => HPS_SD_CLK,                          --                                           .hps_io_sdio_inst_CLK
        hps_0_io_hps_io_sdio_inst_D2                           => HPS_SD_DATA(2),                           --                                           .hps_io_sdio_inst_D2
        hps_0_io_hps_io_sdio_inst_D3                           => HPS_SD_DATA(3),                           --                                           .hps_io_sdio_inst_D3
        hps_0_io_hps_io_usb1_inst_D0                           => HPS_USB_DATA(0),                           --                                           .hps_io_usb1_inst_D0
        hps_0_io_hps_io_usb1_inst_D1                           => HPS_USB_DATA(1),                           --                                           .hps_io_usb1_inst_D1
        hps_0_io_hps_io_usb1_inst_D2                           => HPS_USB_DATA(2),                           --                                           .hps_io_usb1_inst_D2
        hps_0_io_hps_io_usb1_inst_D3                           => HPS_USB_DATA(3),                           --                                           .hps_io_usb1_inst_D3
        hps_0_io_hps_io_usb1_inst_D4                           => HPS_USB_DATA(4),                           --                                           .hps_io_usb1_inst_D4
        hps_0_io_hps_io_usb1_inst_D5                           => HPS_USB_DATA(5),                           --                                           .hps_io_usb1_inst_D5
        hps_0_io_hps_io_usb1_inst_D6                           => HPS_USB_DATA(6),                           --                                           .hps_io_usb1_inst_D6
        hps_0_io_hps_io_usb1_inst_D7                           => HPS_USB_DATA(7),                           --                                           .hps_io_usb1_inst_D7
        hps_0_io_hps_io_usb1_inst_CLK                          => HPS_USB_CLKOUT,                          --                                           .hps_io_usb1_inst_CLK
        hps_0_io_hps_io_usb1_inst_STP                          => HPS_USB_STP,                          --                                           .hps_io_usb1_inst_STP
        hps_0_io_hps_io_usb1_inst_DIR                          => HPS_USB_DIR,                          --                                           .hps_io_usb1_inst_DIR
        hps_0_io_hps_io_usb1_inst_NXT                          => HPS_USB_NXT,                          --                                           .hps_io_usb1_inst_NXT
        hps_0_io_hps_io_spim1_inst_CLK                         => HPS_SPIM_CLK,                         --                                           .hps_io_spim1_inst_CLK
        hps_0_io_hps_io_spim1_inst_MOSI                        => HPS_SPIM_MOSI,                        --                                           .hps_io_spim1_inst_MOSI
        hps_0_io_hps_io_spim1_inst_MISO                        => HPS_SPIM_MISO,                        --                                           .hps_io_spim1_inst_MISO
        hps_0_io_hps_io_spim1_inst_SS0                         => HPS_SPIM_SS,                         --                                           .hps_io_spim1_inst_SS0
        hps_0_io_hps_io_uart0_inst_RX                          => HPS_UART_RX,                          --                                           .hps_io_uart0_inst_RX
        hps_0_io_hps_io_uart0_inst_TX                          => HPS_UART_TX,                          --                                           .hps_io_uart0_inst_TX
        hps_0_io_hps_io_i2c0_inst_SDA                          => HPS_I2C0_SDAT,                          --                                           .hps_io_i2c0_inst_SDA
        hps_0_io_hps_io_i2c0_inst_SCL                          => HPS_I2C0_SCLK,                          --                                           .hps_io_i2c0_inst_SCL
        hps_0_io_hps_io_i2c1_inst_SDA                          => HPS_I2C1_SDAT,                          --                                           .hps_io_i2c1_inst_SDA
        hps_0_io_hps_io_i2c1_inst_SCL                          => HPS_I2C1_SCLK,                          --                                           .hps_io_i2c1_inst_SCL
        hps_0_io_hps_io_gpio_inst_GPIO09                       => HPS_CONV_USB_N,                       --                                           .hps_io_gpio_inst_GPIO09
        hps_0_io_hps_io_gpio_inst_GPIO35                       => HPS_ENET_INT_N,                       --                                           .hps_io_gpio_inst_GPIO35
        hps_0_io_hps_io_gpio_inst_GPIO40                       => HPS_LTC_GPIO,                       --                                           .hps_io_gpio_inst_GPIO40
        hps_0_io_hps_io_gpio_inst_GPIO53                       => HPS_LED,                       --                                           .hps_io_gpio_inst_GPIO53
        hps_0_io_hps_io_gpio_inst_GPIO54                       => HPS_KEY_N,                       --                                           .hps_io_gpio_inst_GPIO54
        hps_0_io_hps_io_gpio_inst_GPIO61                       => HPS_GSENSOR_INT,                       --                                           .hps_io_gpio_inst_GPIO61
        i2c_0_i2c_scl                                          => GPIO_1_D5M_SCLK,                                          --                                  i2c_0_i2c.scl
        i2c_0_i2c_sda                                          => GPIO_1_D5M_SDATA,                                          --                                           .sda
        pio_leds_external_connection_export                    => LED,                    --               pio_leds_external_connection.export
        reset_reset_n                                          => KEY_N(0)                                           --                                      reset.reset_n
    );

end;
