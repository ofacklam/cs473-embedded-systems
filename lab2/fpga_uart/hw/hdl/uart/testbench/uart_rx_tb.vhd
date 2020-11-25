library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end tb_uart_rx;

architecture test of tb_uart_rx is

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
    signal outputdata:      std_logic_vector(7 downto 0);
    signal dataok:          std_logic;
    signal RX:              std_logic;

begin

    -- instantiate the UART RX
    dut: entity work.UartRX
    port map(
        nReset => nReset,
        clk => clk,
        clken => clken,
        baudrate => baudrate,
        parityenable => parityenable,
        parityodd => parityodd,
        outputdata => outputdata,
        dataok => dataok,
        RX => RX
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

            procedure checkValue(actual: in std_logic_vector(7 downto 0); 
                                expected: in std_logic_vector(7 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected)))
                severity error;
            end procedure checkValue;

            procedure checkReception(data: in std_logic_vector(7 downto 0);
                                    correct: in boolean) is
            begin
                RX <= '0'; -- start bit
                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                assert dataok = '0' report "DataOK should be false after reception begin" severity error;

                for i in 0 to 7 loop
                    RX <= data(i); -- data bit
                    waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                end loop;

                RX <= '1'; -- end bit
                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);

                if correct then
                    assert dataok = '1' report "DataOK should be true for correct data" severity error;
                    checkValue(outputdata, data);
                else
                    assert dataok = '0' report "DataOK should be false for incorrect data" severity error;
                end if;
            end procedure;

    begin

        -- default values
        nReset <= '1';
        RX <= '1';
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
        checkReception("11000011", true);

        -- test with even parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '0';
        wait for CLK_PERIOD;
        checkReception("11010011", false);
        checkReception("01010011", true);
        checkReception("00010011", false);
        checkReception("10010011", true);

        -- test with odd parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '1';
        wait for CLK_PERIOD;
        checkReception("01010011", false);
        checkReception("11010011", true);
        checkReception("10010011", false);
        checkReception("00010011", true);

        -- test done
        test_finished <= true;

    end process;

end architecture test;