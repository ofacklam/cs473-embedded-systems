library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_registers is
end tb_registers;

architecture test of tb_registers is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- Registers interface signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    
    signal AS_address:      std_logic;
    signal AS_read:         std_logic;
    signal AS_readdata:     std_logic_vector(31 downto 0);
    signal AS_write:        std_logic;
    signal AS_writedata:    std_logic_vector(31 downto 0);
    
    signal buf0Address:     std_logic_vector(31 downto 0);
    signal bufLength:       std_logic_vector(31 downto 0);
    signal bufNumber:       unsigned(2 downto 0);
    
begin

    -- instantiate the register interface
    dut: entity work.Registers
    port map(
        nReset => nReset,
        clk => clk,
        
        buf0Address => buf0Address,
        bufLength => bufLength,
        bufNumber => bufNumber,

        AS_address => AS_address,
        AS_read => AS_read,
        AS_readdata => AS_readdata,
        AS_write => AS_write,
        AS_writedata => AS_writedata
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

            procedure checkBitValue(desc: in string;
                                    actual: in std_logic; 
                                    expected: in std_logic) is
            begin
                assert actual = expected
                report "Unexpected result for " & desc & ": " &
                        "Read = " & std_logic'image(actual) &
                        "Expected = " & std_logic'image(expected)
                severity error;
            end procedure;

            procedure check32BitValue(desc: in string;
                                    actual: in std_logic_vector(31 downto 0); 
                                    expected: in std_logic_vector(31 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result for " & desc & ": " &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected)))
                severity error;
            end procedure;

            procedure check3BitValue(desc: in string;
                                        actual: in unsigned(2 downto 0); 
                                        expected: in unsigned(2 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result for " & desc & ": " &
                        "Read = " & integer'image(to_integer(actual)) &
                        "Expected = " & integer'image(to_integer(expected))
                severity error;
            end procedure;

    begin

        -- default values
        nReset <= '1';
        AS_address <= '0';
        AS_read <= '0';
        AS_write <= '0';
        AS_writedata <= (others => '0');
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- write to register 0
        AS_address <= '0';
        AS_writedata <= X"00000010";
        AS_write <= '1';
        wait until rising_edge(clk);
        AS_write <= '0';
        wait for CLK_PERIOD / 4;
        check32BitValue("buf0Address", buf0Address, X"00000010");

        -- write to register 1
        AS_address <= '1';
        AS_writedata <= X"60000020";
        AS_write <= '1';
        wait until rising_edge(clk);
        AS_write <= '0';
        wait for CLK_PERIOD / 4;
        check32BitValue("bufLength", bufLength, X"00000020");
        check3BitValue("bufNumber", bufNumber, "011");

        -- read register 0
        AS_address <= '0';
        AS_read <= '1';
        wait until rising_edge(clk);
        AS_read <= '0';
        wait until rising_edge(clk);
        check32BitValue("register 0 value", AS_readdata, X"00000010");

        -- read register 1
        AS_address <= '1';
        AS_read <= '1';
        wait until rising_edge(clk);
        AS_read <= '0';
        wait until rising_edge(clk);
        check32BitValue("register 1 value", AS_readdata, X"60000020");

        -- test done
        test_finished <= true;

    end process;

end architecture test;