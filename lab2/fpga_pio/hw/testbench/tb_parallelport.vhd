library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_parallelport is
end tb_parallelport;

architecture test of tb_parallelport is

    constant CLK_PERIOD: time := 100ns;
    signal test_finished: boolean := false;

    -- parallel port signals
    signal clk: std_logic;
    signal nReset: std_logic;
    signal address: std_logic_vector(2 downto 0);
    signal write: std_logic;
    signal read: std_logic;
    signal writedata: std_logic_vector(7 downto 0);
    signal readdata: std_logic_vector(7 downto 0);
    signal ParPort: std_logic_vector(7 downto 0);

begin

    -- instantiate the parallel port
    dut: entity work.ParallelPort
    port map(
        clk => clk,
        nReset => nReset,
        address => address,
        write => write,
        read => read,
        writedata => writedata,
        readdata => readdata,
        ParPort => ParPort
    );

    -- continuous clock signal
    clk_generation: process
    begin
        if not test_finished then
            clk <= '1';
            wait for CLK_PERIOD / 2;
            clk <= '0';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;

    -- test the parallel port
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure writeRegister(addr: in std_logic_vector(2 downto 0); data: in std_logic_vector(7 downto 0)) is
            begin
                wait until rising_edge(clk);
                address <= addr;
                write <= '1';
                read <= '0';
                writedata <= data;
                wait until rising_edge(clk);
                write <= '0';
            end procedure writeRegister;

            procedure checkValue(addr: in std_logic_vector(2 downto 0); 
                                actual: in std_logic_vector(7 downto 0); 
                                expected: in std_logic_vector(7 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Register = " & integer'image(to_integer(unsigned(addr))) &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected)))
                severity error;
            end procedure checkValue;

            procedure testRegister(addr: in std_logic_vector(2 downto 0); expected: in std_logic_vector(7 downto 0)) is
            begin
                wait until rising_edge(clk);
                address <= addr;
                write <= '0';
                read <= '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk); -- 1wait
                
                checkValue(addr, readdata, expected);
                
                read <= '0';
            end procedure testRegister;

            

            variable tmp: std_logic_vector(7 downto 0);

    begin

        -- default values
        nReset <= '1';
        address <= (others => '0');
        writedata <= (others => '0');
        read <= '0';
        write <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test RegDir
        writeRegister("010", "11111111"); -- out value
        for i in 0 to 7 loop
            tmp := (others => '0');
            tmp(i) := '1';
            writeRegister("000", tmp);
            testRegister("000", tmp); -- read back OK

            tmp := (others => 'Z');
            tmp(i) := '1';
            testRegister("001", tmp); -- RegPin OK
            checkValue("111", ParPort, tmp); -- conduit OK
        end loop;

        -- test RegSet & RegClr
        for i in 0 to 7 loop
            writeRegister("010", "00000000"); -- test RegSet
            tmp := (others => '0');
            tmp(i) := '1';
            writeRegister("011", tmp);
            testRegister("010", tmp);

            writeRegister("010", "11111111"); -- test RegClr
            writeRegister("100", tmp);
            tmp := (others => '1');
            tmp(i) := '0';
            testRegister("010", tmp);
        end loop;

        -- test RegPort
        writeRegister("000", "11111111"); -- all to output mode
        for i in 0 to 7 loop
            tmp := (others => '0');
            tmp(i) := '1';
            writeRegister("010", tmp);
            testRegister("010", tmp); -- read back OK
            testRegister("001", tmp); -- RegPin OK
            checkValue("111", ParPort, tmp); -- conduit OK
        end loop;

        -- test done
        test_finished <= true;

    end process;

end architecture test;