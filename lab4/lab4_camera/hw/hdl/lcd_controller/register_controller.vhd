library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_controller is
    port(
        -- CLOCK AND RESET_N
        csi_clk                     : in std_logic;
        csi_reset_n                 : in std_logic;

        -- AVALON SLAVE
        AS_address : in std_logic_vector(2 downto 0);
		AS_write : in std_logic;
		AS_writedata : in std_logic_vector(31 downto 0);
		AS_read : in std_logic;
		AS_readdata : out std_logic_vector(31 downto 0);

        -- REGISTER OUTPUT
        FAMESEC                     : out std_logic_vector(7 downto 0);
        BUFFADDR               : out std_logic_vector(31 downto 0);

        -- enabled 
        enabled                 : out std_logic;

        -- LCD CONTROL
        lcdc_dcx                : out std_logic;
        lcdc_data               : out std_logic_vector(15 downto 0);
        lcdc_busy               : in std_logic;
        lcdc_flipflop          : out std_logic
    );
end entity register_controller;

architecture rtl of register_controller is

    -- registers
    signal BUFFNUM : std_logic_vector(3 downto 0);

    signal finished_transmission : std_logic;

    -- state
    type State_type is (WAITING_AVALON_WRITE, WAITING_COMMAND_LCD, WAITING_DATA_LCD);
    signal state : State_type;

begin

    -- WRITE
    process(csi_clk, csi_reset_n)
	begin
		-- if reset
		if csi_reset_n = '0' then
            enabled <= '0';
            state <= WAITING_AVALON_WRITE;
            FAMESEC <= std_logic_vector(to_unsigned(60, FAMESEC'length));
            BUFFNUM <= (others => '0');
            AS_readdata <= (others => '0');
            lcdc_data <= (others => '0');

        elsif rising_edge(csi_clk) then
            
            if finished_transmission = '1' then
                state <= WAITING_AVALON_WRITE;
            end if;


			if AS_write = '1' then

				case AS_address is

					-- 0: enable or disable the whole module
					when "000" =>
						if AS_writedata(0) = '1' then
                            enabled <= '1';
						else
                            enabled <= '0';
						end if;
					
					-- 1: write frame per second
					when "001" =>
                        FAMESEC <= AS_writedata(7 downto 0);
                    
                    -- 2 writing buff number
                    when "010" =>
                        BUFFNUM <= AS_writedata(3 downto 0);
                    
                    -- 3 buffer address
                    when "011" =>
                        BUFFADDR <= AS_writedata;
                    
                    -- 4 write command to lcd screen
                    when "100" =>
                        lcdc_data <= AS_writedata(15 downto 0);
                        state <= WAITING_COMMAND_LCD;
                        enabled <= '0';

                    -- 5 write data to lcd screen
                    when "101" =>
                        lcdc_data <= AS_writedata(15 downto 0);
                        state <= WAITING_DATA_LCD;
                        enabled <= '0';
					when others => null;
				end case;

			end if;
		end if;
    end process;
    
    -- to send data to lcd controller
    process(csi_clk, csi_reset_n)
        variable flip_flop : std_logic;
    begin
        if csi_reset_n = '0' then
            finished_transmission <= '0';
            flip_flop := '0';
            lcdc_flipflop <= '0';
            lcdc_dcx <= '0';
        elsif rising_edge(csi_clk) then

            case state is
                when WAITING_AVALON_WRITE =>
                    finished_transmission <= '0';
                -- send command to lcd
                when WAITING_COMMAND_LCD =>
                    lcdc_dcx <= '0';

                    if lcdc_busy = '0' and finished_transmission = '0' then
                        if flip_flop = '1' then
                            lcdc_flipflop <= '0';
                            flip_flop := '0';
                        else
                            lcdc_flipflop <= '1';
                            flip_flop := '1';
                        end if;
                        finished_transmission <= '1';
                    end if;

                when WAITING_DATA_LCD =>
                    lcdc_dcx <= '1';

                    if lcdc_busy = '0' and finished_transmission = '0' then
                        if flip_flop = '1' then
                            lcdc_flipflop <= '0';
                            flip_flop := '0';
                        else
                            lcdc_flipflop <= '1';
                            flip_flop := '1';
                        end if;
                        finished_transmission <= '1';
                    end if;
            end case;

        end if;
    end process;

end;
