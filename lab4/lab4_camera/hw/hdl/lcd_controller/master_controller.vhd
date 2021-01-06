library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity master_controller is
    generic(
        BUFFER_NUM : integer := 4;
        BUFFER_LINE_SIZE : integer := 320;
        BUFFER_NUMBER_LINES : integer := 240;
        BURST_SIZE : integer := 40; --words
        PIXEL_SIZE : integer := 2; -- bytes
        PIXELS_IN_WORD : integer := 2);

    port(
        -- CLOCK AND RESET_N
        csi_clk                     : in std_logic;
        csi_reset_n                 : in std_logic;

        -- AVALON MASTER
        AM_address              : out   std_logic_vector(31 downto 0);
        AM_read                 : out   std_logic;
        AM_readdata             : in    std_logic_vector(31 downto 0);
        AM_burstcount           : out   std_logic_vector(7 downto 0);
        AM_waitreq              : in    std_logic;
        AM_readdatavalid        : in    std_logic;

        -- CAMERA CONDUCTS
        Camera_Writing_Buffer   : in    std_logic_vector(3 downto 0);
        Lcd_Reading_Buffer      : out    std_logic_vector(3 downto 0);

        -- REGISTER INPUT
        fps                     : in std_logic_vector(7 downto 0);
        buff_addr               : in std_logic_vector(31 downto 0);
        enabled                 : in std_logic;

        -- FIFO
        fifo_writereq           : out std_logic;
        fifo_writedata          : out std_logic_vector(31 downto 0);
        fifo_wrusedw		    : in STD_LOGIC_VECTOR (8 DOWNTO 0)
    );
end entity master_controller;

architecture rtl of master_controller is

    constant WORD_SIZE : integer := PIXEL_SIZE * PIXELS_IN_WORD; --bytes 
    constant DATABLOCK_SIZE : integer := BURST_SIZE * WORD_SIZE; --bytes

    constant BUFFER_SIZE : integer := BUFFER_NUMBER_LINES * BUFFER_LINE_SIZE * PIXEL_SIZE; --bytes 
    constant DATABLOCK_NUM : integer := BUFFER_SIZE / (BURST_SIZE * PIXELS_IN_WORD * PIXEL_SIZE); 

    -- pointers to current data
    signal current_buffer : integer range 0 to BUFFER_NUM-1;
    signal current_datablock : integer range 0 to DATABLOCK_NUM;
    signal current_bursttick : integer range 0 to BURST_SIZE-1;


    -- clock counter max signal
    signal count_max : std_logic;
    signal clock_counter : natural := 1;

    -- start signal
    signal reset_counter : std_logic;

    type State_type is (DISABLED, WAITING_PERIOD, WAITING_DATABLOCK, WAITING_BURSTTICK);
    signal state : State_type;


begin

    -- generate periodic at fps speed
    process(csi_clk)
    
        function setup_fps(fps: std_logic_vector(7 downto 0)) 
            return natural is
        begin
            if to_integer(unsigned(fps)) = 0 then
                return 1;
            else
                return to_integer(unsigned(fps));
            end if;
        end function;

        variable CLOCK_PERIOD : natural;

    begin
        if csi_reset_n = '0' then
            CLOCK_PERIOD := 50000000/setup_fps(fps);

        elsif rising_edge(csi_clk) then
            if clock_counter = CLOCK_PERIOD then
                if reset_counter = '0' then
                    count_max <= '1';
                    CLOCK_PERIOD := 50000000/setup_fps(fps);
                else
                    clock_counter <= 0;
                end if;
            else
                count_max <= '0';
                clock_counter <= clock_counter + 1;
            end if;
        end if;
    end process;



    process(csi_clk, csi_reset_n)
        constant FIFO_SIZE : integer := 128;
    begin
        if csi_reset_n = '0' then
            state <= DISABLED;
            AM_burstcount <= (others => '0');
            AM_address <= (others => '0');
            AM_read <= '0';
            Lcd_Reading_Buffer <= (others => '0');
            fifo_writereq <= '0';
            fifo_writedata <= (others => '0');

        elsif rising_edge(csi_clk) then

            if enabled = '0' then
                state <= DISABLED;
            else
                case state is
                    
                    -- disabled 
                    when DISABLED => 
                    
                        current_buffer <= 0;
                        state <= WAITING_PERIOD;

                    -- waiting that the next buffer is available
                    when WAITING_PERIOD =>

                        -- waited enough
                        if count_max = '1' then
                            reset_counter <= '1';
                            
                            if Camera_Writing_Buffer(current_buffer) = '0' then
                                state <= WAITING_DATABLOCK;
                                current_datablock <= 0;
                                Lcd_Reading_Buffer(current_buffer) <= '1';
                            end if;
                        else
                            reset_counter <= '0';
                        end if;

                    -- sending the read avalon request
                    when WAITING_DATABLOCK =>

                        fifo_writereq <= '0'; -- do not write anything in the fifo

                        if current_datablock <= DATABLOCK_NUM-1 then

                            -- if enough place in the fifo, start transmission
                            if FIFO_SIZE - to_integer(unsigned(fifo_wrusedw)) >= BURST_SIZE then
                                
                                -- avalon master call
                                AM_read <= '1';
                                AM_burstcount <= std_logic_vector(to_unsigned(BURST_SIZE, AM_burstcount'length));
                                AM_address <=  std_logic_vector(to_unsigned(to_integer(unsigned(buff_addr)) + BUFFER_SIZE * current_buffer + current_datablock * DATABLOCK_SIZE, AM_address'length));

                                if AM_waitreq = '0' then
                                    state <= WAITING_BURSTTICK;
                                    current_bursttick <= 0;
                                end if;

                            end if;

                        else
                            Lcd_Reading_Buffer(current_buffer) <= '0';
                            if current_buffer = BUFFER_NUM-1 then
                                current_buffer <= 0;
                            else
                                current_buffer <= current_buffer + 1;
                            end if;
                            state <= WAITING_PERIOD;
                        end if;
                            

                    -- receiving each burst tick
                    when WAITING_BURSTTICK =>

                        -- make sure all AM are low
                        AM_read <= '0';
                        AM_burstcount <= (others => '0');
                        AM_address <= (others => '0');
                            

                        -- data is available
                        if AM_readdatavalid = '1' then
                            fifo_writereq <= '1';
                            fifo_writedata <= AM_readdata;

                            if current_bursttick = BURST_SIZE-1 then
                                current_datablock <= current_datablock + 1;
                                state <= WAITING_DATABLOCK;
                            else
                                current_bursttick <= current_bursttick + 1;
                            end if;

                        else
                            fifo_writereq <= '0';
                        end if;

                end case;
            end if;
        end if;
    end process;

end;
