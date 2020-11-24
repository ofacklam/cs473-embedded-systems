library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end tb_uart_tx;

architecture test of tb_uart_tx is

    constant CLK_PERIOD: time := 100 ns;
    constant CLK_DIVIDER: integer := 4;
    signal test_finished: boolean := false;

    -- uart tx signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    signal clken:           std_logic; -- slow clock
    signal baudrate:        unsigned(7 downto 0);
    signal parityenable:    std_logic;
    signal parityodd:       std_logic;
    signal inputdata:       std_logic_vector(7 downto 0);
    signal ready:           std_logic;
    signal start:           std_logic;
    signal TX:              std_logic;

begin

    -- instantiate the UART TX
    dut: entity work.UartTX
    port map(
        nReset => nReset,
        clk => clk,
        clken => clken,
        baudrate => baudrate,
        parityenable => parityenable,
        parityodd => parityodd,
        inputdata => inputdata,
        ready => ready,
        start => start,
        TX => TX
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

    -- slow clock signal
    slow_clk: process
    begin
        if not test_finished then
            clken <= '1';
            wait until rising_edge(clk);
            
            clken <= '0';
            for i in 1 to CLK_DIVIDER - 1 loop
                wait until rising_edge(clk);
            end loop;
        else
            wait;
        end if;
    end process;

    -- test the UART TX
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure waitBaudInterval(clk_cycles: in integer) is
            begin
                for i in 0 to clk_cycles-1 loop
                    wait until rising_edge(clk);
                end loop;
            end procedure;

            procedure checkValue(idx: in natural; 
                                actual: in std_logic; 
                                expected: in std_logic) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "TX index = " & integer'image(idx) &
                        "Read = " & std_logic'image(actual) &
                        "Expected = " & std_logic'image(expected)
                severity error;
            end procedure checkValue;

            procedure checkTransmission(data: in std_logic_vector(7 downto 0);
                                        expected: in std_logic_vector(7 downto 0)) is
            begin
                assert ready = '1' report "Ready should be true" severity error;

                inputdata <= data;
                start <= '1';

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                start <= '0';
                checkValue(10, TX, '0'); -- start bit

                for i in 0 to 7 loop
                    waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                    checkValue(i, TX, expected(i)); -- data / parity bit
                end loop;

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                checkValue(11, TX, '1'); -- end bit

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                assert ready = '1' report "Ready should be true" severity error;
            end procedure;

    begin

        -- default values
        nReset <= '1';
        start <= '0';
        inputdata <= (others => '0');
        baudrate <= X"10";
        parityenable <= '0';
        parityodd <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test without parity
        baudrate <= X"19";
        parityenable <= '0';
        parityodd <= '0';
        wait for CLK_PERIOD;
        checkTransmission("11000011", "11000011");

        -- test with even parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '0';
        wait for CLK_PERIOD;
        checkTransmission("11010011", "01010011");
        checkTransmission("01010011", "01010011");
        checkTransmission("10010011", "10010011");
        checkTransmission("00010011", "10010011");

        -- test with odd parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '1';
        wait for CLK_PERIOD;
        checkTransmission("11010011", "11010011");
        checkTransmission("01010011", "11010011");
        checkTransmission("10010011", "00010011");
        checkTransmission("00010011", "00010011");

        -- test done
        test_finished <= true;

    end process;

end architecture test;