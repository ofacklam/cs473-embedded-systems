library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_trx is
end tb_uart_trx;

architecture test of tb_uart_trx is

    constant CLK_PERIOD: time := 100 ns;
    constant CLK_DIVIDER: integer := 4;
    signal test_finished: boolean := false;

    -- common signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    signal clken:           std_logic; -- slow clock
    signal baudrate:        unsigned(7 downto 0);
    signal parityenable:    std_logic;
    signal parityodd:       std_logic;

    -- TX signals
    signal inputdata:       std_logic_vector(7 downto 0);
    signal ready:           std_logic;
    signal start:           std_logic;
    signal TX:              std_logic;

    -- RX signals
    signal outputdata:      std_logic_vector(7 downto 0);
    signal dataok:          std_logic;
    signal RX:              std_logic;

begin

    -- instantiate the UART TX
    dutTX: entity work.UartTX
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

    -- instantiate the UART RX
    dutRX: entity work.UartRX
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

    -- connect TX to RX
    RX <= TX;

    -- test the UART tranmission / reception
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

            procedure checkTransmission(data: in std_logic_vector(7 downto 0);
                                        expected: in std_logic_vector(7 downto 0)) is
            begin
                -- TX ready
                assert ready = '1' report "Ready should be true" severity error;

                -- start TX
                inputdata <= data;
                start <= '1';

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                start <= '0';

                -- wait for transmission to finish
                waitBaudInterval(10 * to_integer(baudrate) * CLK_DIVIDER); -- start + 8*data + stop bit = 10bits
                
                -- TX ready, RX correct
                assert ready = '1' report "Ready should be true" severity error;
                assert dataok = '1' report "DataOK should be true" severity error;
                checkValue(outputdata, expected);
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