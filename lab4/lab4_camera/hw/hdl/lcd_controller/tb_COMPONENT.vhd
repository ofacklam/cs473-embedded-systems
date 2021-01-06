library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_component is
end tb_component;


architecture test of tb_component is

	constant CLK_PERIOD : time := 20 ns;
	signal sim_finished : boolean := false;

	-- clock
	signal csi_clk : std_logic;
	signal csi_reset_n : std_logic := '0';
	
	-- AVALON MASTER
	signal AM_address : std_logic_vector(31 downto 0);
	signal AM_read : std_logic;
	signal AM_readdata : std_logic_vector(31 downto 0);
	signal AM_burstcount : std_logic_vector(7 downto 0);
	signal AM_waitreq : std_logic;
	signal AM_readdatavalid : std_logic;

	-- Interface to LCD
	signal LCD_ON : std_logic;
	signal CSX : std_logic;
	signal RESX : std_logic;
	signal DCX : std_logic;
	signal WRX : std_logic;
	signal RDX : std_logic;
	signal D : std_logic_vector(15 downto 0);

		
	-- AVALON SLAVE
	signal AS_address : std_logic_vector(2 downto 0);
	signal AS_write : std_logic;
	signal AS_writedata : std_logic_vector(31 downto 0);
	signal AS_read : std_logic;
	signal AS_readdata : std_logic_vector(31 downto 0);

	-- CAMERA CONDUCTS
	signal Camera_Writing_Buffer : std_logic_vector(3 downto 0) := (others => '0');
	signal Lcd_Reading_Buffer : std_logic_vector(3 downto 0);

	
begin

	master_controller_sub : entity work.LCD_IP_COMPONENT
	port map(
				-- general
				csi_clk => csi_clk,
				csi_reset_n => csi_reset_n,

				-- to lcd
				LCD_ON => LCD_ON,
				CSX => CSX,
				RESX => RESX,
				DCX => DCX,
				WRX => WRX,
				RDX => RDX,
				D => D,

				-- avalon slave
				AS_address => AS_address,
				AS_write => AS_write,
				AS_writedata => AS_writedata,
				AS_read => AS_read,
				AS_readdata => AS_readdata,

				-- avalon master
				AM_address => AM_address,
				AM_read => AM_read,
				AM_readdata => AM_readdata,
				AM_waitreq => AM_waitreq,
				AM_burstcount => AM_burstcount,
				AM_readdatavalid => AM_readdatavalid,

				-- camera conduct
				Camera_Writing_Buffer => Camera_Writing_Buffer,
				Lcd_Reading_Buffer => Lcd_Reading_Buffer
			);

				
	
		-- Generate CLK signal
	clk_generation : process
	begin
		if not sim_finished then
			csi_clk <= '1';
			wait for CLK_PERIOD / 2;
			csi_clk <= '0';
			wait for CLK_PERIOD / 2;
		else
			wait;
		end if;
	end process clk_generation;
	
	
	
	-- Test adder_sequential
	simulation : process

		-- RESET MODULE
		procedure reset is
		begin
			csi_reset_n <= '0';
			wait for 100 ns;
			csi_reset_n <= '1';

		end procedure reset;
		
		-- SEND A TICK OF BURST FOR AVALON MASTER
		procedure avalon_master_send_tick(constant data : in std_logic_vector(31 downto 0)) is
		begin
			AM_readdatavalid <= '1';
			AM_readdata <= data;
			wait for 20 ns;
			AM_readdatavalid <= '0';
			AM_readdata <= (others => '0');
		end procedure avalon_master_send_tick;


		-- WRITE TO AVALON SLAVE
		procedure avalon_slave_write(constant address : in integer;
									constant datawrite : in std_logic_vector(31 downto 0)) is
		begin
			AS_writedata <= datawrite;
			AS_address <= std_logic_vector(to_unsigned(address, 3));
			AS_write <= '1';
			wait for 23 ns;
			AS_write <= '0';
		end procedure avalon_slave_write;

		 
	begin
        if sim_finished = true then 
            wait;
		end if;
		
		reset;
		wait for 100 ns;
		AM_waitreq <= '0';

		wait for 1 ms;

		avalon_slave_write(3, std_logic_vector(to_unsigned(0, 32)));
		avalon_slave_write(1, std_logic_vector(to_unsigned(60, 32)));

		wait for 1 ms;
		avalon_slave_write(0, std_logic_vector(to_unsigned(1, 32)));



		for i in 0 to 0 loop

			for datablock in 0 to 0 loop

				wait until AM_read = '1';
				wait for 100 ns;

				for bursttick in 0 to 39 loop
					wait for 30 ns;
					avalon_master_send_tick(std_logic_vector(to_unsigned(INTEGER'high - bursttick, 32)));
				end loop;
			end loop;

		end loop;

		-- disable lcd controller
		avalon_slave_write(0, std_logic_vector(to_unsigned(0, 32)));
		-- send command + data + data
		wait for 60 ns;
		avalon_slave_write(4, std_logic_vector(to_unsigned(7, 32)));
		wait for 60 ns;
		avalon_slave_write(5, std_logic_vector(to_unsigned(31, 32)));
		wait for 120 ns;
		avalon_slave_write(5, std_logic_vector(to_unsigned(7, 32)));
		wait for 120 ns;
		-- resume pixel polling
		avalon_slave_write(0, std_logic_vector(to_unsigned(1, 32)));

		wait for 1000 ns;

		sim_finished <= true;
		wait;

	end process simulation;
	
end architecture test;









































