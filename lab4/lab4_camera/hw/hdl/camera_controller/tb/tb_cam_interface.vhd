library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cam_interface is
end tb_cam_interface;

architecture test of tb_cam_interface is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- cam interface signals
    signal nReset:          std_logic;
    signal enableCam:       std_logic;

    signal pixclk:          std_logic;
    signal data:            std_logic_vector(11 downto 0);
    signal fval:            std_logic;
    signal lval:            std_logic;
    
    signal pixelData:       std_logic_vector(15 downto 0);
    signal pixelWrite:      std_logic;
    signal pixelFull:       std_logic;
    signal frameActive:     std_logic;

begin

    -- instantiate the cam interface
    dut: entity work.CamInterface
    port map(
        nReset => nReset,
        enableCam => enableCam,

        pixclk => pixclk,
        data => data,
        fval => fval,
        lval => lval,

        pixelData => pixelData,
        pixelWrite => pixelWrite,
        pixelFull => pixelFull,
        frameActive => frameActive
    );

    -- continuous clock signal
    clk_generation: process
    begin
        if not test_finished then
            pixclk <= '1';
            wait for CLK_PERIOD / 2;
            pixclk <= '0';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;

    -- test the cam interface
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(pixclk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                enableCam <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure generatePixel(val: in std_logic_vector(11 downto 0)) is
            begin
                data <= val;
                wait until rising_edge(pixclk);
            end procedure;

            procedure checkPixelValue(actual: in std_logic_vector(15 downto 0); 
                                    expected: in std_logic_vector(15 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected)))
                severity error;
            end procedure;

            procedure testLine(cols: in integer; enabled: in boolean) is
                variable Bval: std_logic_vector(4 downto 0);
                variable Gval: std_logic_vector(4 downto 0);
            begin
                -- first row (G1 & R)
                wait until rising_edge(pixclk);
                lval <= '1';

                for i in 0 to cols-1 loop
                    generatePixel(std_logic_vector(to_unsigned(i, 5)) & "0000000"); -- G1
                    assert pixelWrite = '0' report "Expected pixelWrite to be inactive" severity error;

                    generatePixel(std_logic_vector(to_unsigned(cols - i, 5)) & "0000000"); -- R
                    assert pixelWrite = '0' report "Expected pixelWrite to be inactive" severity error;
                end loop;
                
                lval <= '0';
                wait until rising_edge(pixclk);

                -- second row (B & G2)
                wait until rising_edge(pixclk);
                lval <= '1';
                
                for i in 0 to cols-1 loop
                    Bval := std_logic_vector(to_unsigned(cols - i, 5)); -- B
                    generatePixel(Bval & "0000000");
                    assert pixelWrite = '0' report "Expected pixelWrite to be inactive" severity error;

                    Gval := std_logic_vector(to_unsigned(i, 5)); -- G2
                    generatePixel(Gval & "0000000");

                    -- check pixel
                    if enabled then
                        assert pixelWrite = '1' report "Expected pixelWrite to be active" severity error;
                        checkPixelValue(pixelData, Bval & Gval & "0" & Bval);
                    else
                        assert pixelWrite = '0' report "Expected pixelWrite to be inactive" severity error;
                    end if;
                end loop;
                
                lval <= '0';
                wait until rising_edge(pixclk);
                
            end procedure;

            procedure testFrame(rows: in integer; cols: in integer; enabled: in boolean) is
            begin
                wait until rising_edge(pixclk);
                fval <= '1';

                for i in 0 to rows-1 loop
                    testLine(cols, enabled);
                end loop;

                fval <= '0';
                wait until rising_edge(pixclk);
            end procedure;

    begin

        -- default values
        nReset <= '1';
        enableCam <= '0';
        data <= (others => '0');
        fval <= '0';
        lval <= '0';
        pixelFull <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- test frame while disabled
        testFrame(2, 3, false);

        -- test frame while enabled
        enableCam <= '1';
        wait until rising_edge(pixclk);

        testFrame(2, 3, true);
        
        enableCam <= '0';
        wait until rising_edge(pixclk);

        -- test done
        test_finished <= true;

    end process;

end architecture test;