library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart is
end tb_uart;

architecture test of tb_uart is

    constant CLK_PERIOD: time := 100 ns;
    constant CLK_DIVIDER: integer := 4;
    constant CLKDIV: std_logic_vector(2 downto 0) := "010";
    signal test_finished: boolean := false;

    -- variable settings
    signal baudrate:        unsigned(7 downto 0);
    signal parityenable:    std_logic;
    signal parityodd:       std_logic;

    -- uart signals
    signal nReset:          std_logic;
    signal clk:             std_logic;

    signal address:    std_logic_vector(1 downto 0);
    signal read:       std_logic;
    signal readdata:   std_logic_vector(7 downto 0);
    signal write:      std_logic;
    signal writedata:  std_logic_vector(7 downto 0);

    signal TX:              std_logic;
    signal RX:              std_logic;

begin

    -- instantiate the UART
    dut: entity work.Uart
    port map(
        nReset => nReset,
        clk => clk,

        address => address,
        read => read,
        readdata => readdata,
        write => write,
        writedata => writedata,

        TX => TX,
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

    -- test the UART
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

            procedure checkBitValue(idx: in natural; 
                                    actual: in std_logic; 
                                    expected: in std_logic) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "TX index = " & integer'image(idx) &
                        "Read = " & std_logic'image(actual) &
                        "Expected = " & std_logic'image(expected)
                severity error;
            end procedure;

            procedure checkRegisterValue(addr: in std_logic_vector(1 downto 0); 
                                        actual: in std_logic_vector(7 downto 0); 
                                        expected: in std_logic_vector(7 downto 0);
                                        mask: in std_logic_vector(7 downto 0)) is
            begin
                assert (actual and mask) = (expected and mask)
                report "Unexpected result: " &
                        "Register = " & integer'image(to_integer(unsigned(addr))) &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected))) &
                        "Mask = " & integer'image(to_integer(unsigned(mask)))
                severity error;
            end procedure;

            procedure writeRegister(addr: in std_logic_vector(1 downto 0); data: in std_logic_vector(7 downto 0)) is
            begin
                -- wait until rising_edge(clk);
                address <= addr;
                write <= '1';
                read <= '0';
                writedata <= data;
                wait until rising_edge(clk);
                write <= '0';
            end procedure writeRegister;

            procedure writeCtrlA is
            begin
                writeRegister("00", "1" & CLKDIV & parityodd & parityenable & "01");
            end procedure;

            procedure writeCtrlB is
            begin
                writeRegister("01", std_logic_vector(baudrate));
            end procedure;

            procedure testRegister(addr: in std_logic_vector(1 downto 0);
                                    expected: in std_logic_vector(7 downto 0); 
                                    mask: in std_logic_vector(7 downto 0)) is
            begin
                -- wait until rising_edge(clk);
                address <= addr;
                write <= '0';
                read <= '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk); -- 1wait
                
                checkRegisterValue(addr, readdata, expected, mask);
                
                read <= '0';
            end procedure testRegister;

            procedure testCtrlA is
            begin
                testRegister("00", "0" & CLKDIV & parityodd & parityenable & "10", X"ff");
            end procedure;

            procedure checkTransmission(data: in std_logic_vector(7 downto 0);
                                        expected: in std_logic_vector(7 downto 0)) is
            begin
                testRegister("00", "00000010", "00000011"); -- ready bit set
                writeRegister("11", data);
                testRegister("00", "00000000", "00000011"); -- ready bit clear
                testRegister("11", data, X"ff");    -- data correct

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER / 2);
                testRegister("00", "00000010", "00000011"); -- ready bit set again (TX has started)
                checkBitValue(10, TX, '0'); -- start bit

                for i in 0 to 7 loop
                    waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                    checkBitValue(i, TX, expected(i)); -- data / parity bit
                end loop;

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                checkBitValue(11, TX, '1'); -- end bit

                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
            end procedure;

            procedure checkReception(data: in std_logic_vector(7 downto 0);
                                    correct: in boolean) is
            begin
                testRegister("00", "00000010", "00000011"); -- data not available

                RX <= '0'; -- start bit
                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);

                for i in 0 to 7 loop
                    RX <= data(i); -- data bit
                    waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);
                end loop;

                RX <= '1'; -- end bit
                waitBaudInterval(to_integer(baudrate) * CLK_DIVIDER);

                if correct then
                    testRegister("00", "00000011", "00000011"); -- data is available
                    testRegister("10", data, X"ff");
                else
                    testRegister("00", "00000010", "00000011"); -- data not available
                end if;
            end procedure;

    begin

        -- default values
        nReset <= '1';
        baudrate <= X"10";
        parityenable <= '0';
        parityodd <= '0';
        read <= '0';
        write <= '0';
        RX <= '1';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test CTRLA
        parityenable <= '0';
        parityodd <= '0';
        wait for CLK_PERIOD;
        writeCtrlA;
        testCtrlA;

        parityenable <= '1';
        parityodd <= '1';
        wait for CLK_PERIOD;
        writeCtrlA;
        testCtrlA;

        -- test CTRLB
        baudrate <= X"19";
        wait for CLK_PERIOD;
        writeCtrlB;
        testRegister("01", X"18", X"ff");

        baudrate <= X"08";
        wait for CLK_PERIOD;
        writeCtrlB;
        testRegister("01", std_logic_vector(baudrate), X"ff");

        -- test TRX without parity
        baudrate <= X"18";
        parityenable <= '0';
        parityodd <= '0';
        wait for CLK_PERIOD;
        writeCtrlA;
        writeCtrlB;
        checkTransmission("11000011", "11000011");
        checkReception("11000011", true);

        -- test TRX with even parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '0';
        wait for CLK_PERIOD;
        writeCtrlA;
        writeCtrlB;
        checkTransmission("11010011", "01010011");
        checkTransmission("01010011", "01010011");
        checkTransmission("10010011", "10010011");
        checkTransmission("00010011", "10010011");
        checkReception("11010011", false);
        checkReception("01010011", true);
        checkReception("00010011", false);
        checkReception("10010011", true);

        -- test with odd parity
        baudrate <= X"08";
        parityenable <= '1';
        parityodd <= '1';
        wait for CLK_PERIOD;
        writeCtrlA;
        writeCtrlB;
        checkTransmission("11010011", "11010011");
        checkTransmission("01010011", "11010011");
        checkTransmission("10010011", "00010011");
        checkTransmission("00010011", "00010011");
        checkReception("01010011", false);
        checkReception("11010011", true);
        checkReception("10010011", false);
        checkReception("00010011", true);

        -- test done
        test_finished <= true;

    end process;

end architecture test;