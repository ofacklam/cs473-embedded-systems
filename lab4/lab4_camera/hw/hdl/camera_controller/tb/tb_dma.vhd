library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dma is
end tb_dma;

architecture test of tb_dma is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- dma interface signals
    constant BURST_SIZE: positive := 4;

    signal nReset:          std_logic;
    signal clk:             std_logic;
    
    signal enableDma:       std_logic;
    signal bufAddress:      std_logic_vector(31 downto 0);
    signal bufLength:       std_logic_vector(31 downto 0);
    
    signal data:            std_logic_vector(31 downto 0);
    signal size:            std_logic_vector(11 downto 0);
    signal read:            std_logic;

    signal AM_address:      std_logic_vector(31 downto 0);
    signal AM_write:        std_logic;
    signal AM_writedata:    std_logic_vector(31 downto 0);
    signal AM_burstcount:   std_logic_vector(7 downto 0);
    signal AM_waitreq:      std_logic;

begin

    -- instantiate the dma interface
    dut: entity work.Dma
    generic map(
        burstsize => BURST_SIZE
    )
    port map(
        nReset => nReset,
        clk => clk,
        
        enableDma => enableDma,
        bufAddress => bufAddress,
        bufLength => bufLength,

        data => data,
        size => size,
        read => read,
        
        AM_address => AM_address,
        AM_write => AM_write,
        AM_writedata => AM_writedata,
        AM_burstcount => AM_burstcount,
        AM_waitreq => AM_waitreq
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

    -- FIFO simulation
    fifo: process(nReset, clk)
    begin
        if nReset = '0' then
            size <= bufLength(13 downto 2);
            data <= (others => '0');
        elsif rising_edge(clk) then
            if read = '1' then
                size <= std_logic_vector(unsigned(size) - 1);
                data <= std_logic_vector(unsigned(data) + 1);
            end if;
        end if;
    end process;

    -- slave simulation
    slave: process(nReset, clk)
        variable expected: natural := 0;
        variable addr: std_logic_vector(31 downto 0);
    begin
        if nReset = '0' then
            expected := 0;
        elsif rising_edge(clk) then
            if AM_write = '1' then
                addr := std_logic_vector(unsigned(bufAddress) + to_unsigned((expected / BURST_SIZE) * 4 * BURST_SIZE, 32));

                assert AM_address = addr
                report "Expected address = " & integer'image(to_integer(unsigned(addr))) &
                        "Got address = " & integer'image(to_integer(unsigned(AM_address)))
                severity error;

                assert AM_writedata = std_logic_vector(to_unsigned(expected, 32))
                report "Expected value = " & integer'image(expected) &
                        "Got value = " & integer'image(to_integer(unsigned(AM_writedata)))
                severity error;

                assert AM_burstcount = std_logic_vector(to_unsigned(BURST_SIZE, 8))
                report "Bad burst count !!"
                severity error;

                expected := expected + 1;
            end if;
        end if;
    end process;

    -- test the cam interface
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                enableDma <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

    begin

        -- default values
        nReset <= '1';
        enableDma <= '0';
        bufAddress <= X"00000010";
        bufLength <= X"00000020";
        AM_waitreq <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test DMA
        enableDma <= '1';
        wait for 12 * CLK_PERIOD;
        enableDma <= '0';

        assert to_integer(unsigned(size)) = 0 report "Didn't empty FIFO" severity error;

        -- test done
        test_finished <= true;
        wait for CLK_PERIOD;
        wait;

    end process;

end architecture test;