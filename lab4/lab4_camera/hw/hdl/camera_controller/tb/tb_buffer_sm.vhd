library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_buffer_sm is
end tb_buffer_sm;

architecture test of tb_buffer_sm is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- buffer SM interface signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    
    signal bufferDisp:      std_logic;
    signal bufferCapt:      std_logic;
    signal bufferReady:     std_logic;

begin

    -- instantiate the buffer SM interface
    dut: entity work.BufferSm
    port map(
        nReset => nReset,
        clk => clk,
        
        bufferDisp => bufferDisp,
        bufferCapt => bufferCapt,
        bufferReady => bufferReady
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

    -- test the cam interface
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure checkBitValue(actual: in std_logic; 
                                    expected: in std_logic) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Read = " & std_logic'image(actual) &
                        "Expected = " & std_logic'image(expected)
                severity error;
            end procedure;

            procedure testCycle is
            begin
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '1');

                -- Start capture
                bufferCapt <= '1';
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '1');
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');

                -- Stop capture
                bufferCapt <= '0';
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');

                -- Start displaying
                bufferDisp <= '1';
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');

                -- Stop displaying
                bufferDisp <= '0';
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '0');
                wait until rising_edge(clk);
                checkBitValue(bufferReady, '1');
            end procedure;

    begin

        -- default values
        nReset <= '1';
        bufferDisp <= '0';
        bufferCapt <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test
        testCycle;

        -- test done
        test_finished <= true;

    end process;

end architecture test;