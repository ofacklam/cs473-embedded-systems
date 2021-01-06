library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;



entity lcd_controller is
    generic(
        SCREEN_NUMBER_COLUMNS : integer := 320;
        SCREEN_NUMBER_LINES : integer := 240;
        PIXEL_SIZE : integer := 16);

	port(
		clk : in std_logic;
		reset_n : in std_logic;
		
		-- Interface to FIFO module
		fifo_readdata : in std_logic_vector(15 downto 0);
		fifo_empty : in std_logic;
		fifo_readreq : out std_logic;
		
		-- Interface to Register module
		lcdc_enabled : in std_logic;
		lcdc_dcx : in std_logic;
		lcdc_flipflop : in std_logic;
		lcdc_data : in std_logic_vector(15 downto 0);
		fps_sig : in std_logic_vector(7 downto 0);
		lcdc_busy : out std_logic;
        
        -- Interface to LCD
		LCD_ON : out std_logic;
		CSX : out std_logic;
		RESX : out std_logic;
		DCX : out std_logic;
		WRX : out std_logic;
		RDX : out std_logic;
        D : out std_logic_vector(15 downto 0)
	);
end lcd_controller;


architecture lcdc_comp of lcd_controller is
    constant FRAME_SIZE : natural := SCREEN_NUMBER_COLUMNS * SCREEN_NUMBER_LINES;
    
    -- clock pulsing at 1/fps sec.
    signal clk_fps : std_logic;    
    -- counter increases each time a pixel is sent to the LCD screen
    signal pixel_counter : natural;
    
    type State_type is (IDLE, WAITING_AVAILABILITY, SENDING_DATA, FROM_REGISTER, SENDING_REGISTER);
    signal state : State_type;
begin

    -- slow clock pulsing at 1/fps sec
    process(clk, reset_n)
        variable clock_fps_period : natural;
        variable clock_fps_counter : natural;
        variable fps : integer range 0 to 1100;
    begin
        if reset_n = '0' then
            clock_fps_counter := 0;
        elsif rising_edge(clk) then
            if to_integer(unsigned(fps_sig)) /= 0 then 
                fps := to_integer(unsigned(fps_sig));
            else 
                fps := 20;
            end if;

			if clock_fps_counter >= 50000000/fps then
				clk_fps <= '1';
				clock_fps_counter := 0;
			else
                clk_fps <= '0';
				clock_fps_counter := clock_fps_counter + 1;
			end if;
		end if;
    end process;
    

    -- process dealing with dequeuing pixels and sending it to LCD screen
    -- REQUIRE software to send command 'MEMORY WRITE' before.
    process(clk, reset_n)
        variable must_wait : natural;
        variable flipflop_old : std_logic;
    begin 
        if reset_n = '0' then
            -- reset output signals
            fifo_readreq <= '0';
            lcdc_busy <= '1';
            LCD_ON <= '0';
            CSX <= '1';
            RESX <= '0';
            DCX <= '1';
            WRX <= '1';
            RDX <= '1';
            D <= (others => '0');
            
            -- reset global signals
            state <= IDLE;
            pixel_counter <= 0;

            -- reset local variables
            must_wait := 0;
        elsif rising_edge(clk) then
            -- chip select always activated
            CSX <= '0';
            RESX <= '1';
            LCD_ON <= '1';

            if clk_fps = '1' and pixel_counter = FRAME_SIZE then
                pixel_counter <= 0;
            end if;

            case state is

                -- waiting an element in fifo
                when IDLE =>
                    if lcdc_enabled = '1' and fifo_empty = '0' and pixel_counter < FRAME_SIZE then
                        fifo_readreq <= '1';
                        state <= WAITING_AVAILABILITY;                
                    elsif lcdc_enabled = '0' then
                        lcdc_busy <= '0';
                        flipflop_old := lcdc_flipflop;
                        state <= FROM_REGISTER;
                    end if;

                -- waiting availability + end of sending to LCD
                when WAITING_AVAILABILITY =>
                    fifo_readreq <= '0';
                    WRX <= '0';
                    must_wait := 1;
                    state <= SENDING_DATA;

                -- wait one clk cycle
                when SENDING_DATA =>
                    if must_wait = 1 then
                        D <= fifo_readdata;
                        must_wait := 0;
                    else 
                        WRX <= '1';
                        pixel_counter <= pixel_counter + 1;
                        state <= IDLE;
                    end if;

                when FROM_REGISTER =>
                    if lcdc_enabled = '1' then
                        lcdc_busy <= '1';
                        DCX <= '1';
                        state <= IDLE;

                    elsif lcdc_enabled = '0' then
                        if lcdc_flipflop /= flipflop_old then
                            flipflop_old := lcdc_flipflop;
                            WRX <= '0';
                            DCX <= lcdc_dcx;
                            D <= lcdc_data;
                            must_wait := 3;
                            lcdc_busy <= '1';  -- set component as busy
                            state <= SENDING_REGISTER;
                        end if;
                    end if;

                when SENDING_REGISTER =>
                    if must_wait > 2 then
                        must_wait := must_wait - 1;
                    elsif must_wait = 2 then
                        WRX <= '1';
                        must_wait := must_wait - 1;
                    elsif must_wait = 1 then
                        DCX <= '1';
                        must_wait := must_wait - 1;
                    elsif must_wait = 0 then
                        lcdc_busy <= '0';  -- set component as free
                        state <= FROM_REGISTER;
                    end if;
                    
                when others => null;
            end case;
            
        end if;
    end process;

end lcdc_comp;