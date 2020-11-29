library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_clock_divider is
end tb_clock_divider;

architecture test of tb_clock_divider is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- clock divider signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    signal clkdiv:          unsigned(2 downto 0) := "000";
    signal clken:           std_logic; -- slow clock

begin

    -- instantiate the clock divider
    dut: entity work.ClockDivider
    port map(
        nReset => nReset,
        clk => clk,
        clkdiv => clkdiv,
        clken => clken
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

    -- test the clock divider
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure checkSlowClk(divider: unsigned(2 downto 0)) is
            begin
                clkdiv <= divider;

                -- (2**divider-1) cycles off
                for i in 1 to 2**to_integer(divider) - 1 loop
                    wait until rising_edge(clk);
                    wait for CLK_PERIOD/4;
                    assert clken = '0' report "Expected slow clock to be false" severity error;
                end loop;

                -- last cycle on
                wait until rising_edge(clk);
                wait for CLK_PERIOD/4;
                assert clken = '1' report "Expected slow clock to be true" severity error;
            end procedure;

    begin

        -- default values
        nReset <= '1';
        clkdiv <= "000";
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test divider
        checkSlowClk("000");
        checkSlowClk("001");
        checkSlowClk("010");
        checkSlowClk("011");
        checkSlowClk("100");
        checkSlowClk("101");
        checkSlowClk("110");
        checkSlowClk("111");

        -- test done
        test_finished <= true;

    end process;

end architecture test;