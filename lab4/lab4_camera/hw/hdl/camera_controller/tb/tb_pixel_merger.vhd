library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pixel_merger is
end tb_pixel_merger;

architecture test of tb_pixel_merger is
    constant WAIT_PERIOD: time := 100 ns;

    -- pixel signals
    signal G1:      std_logic_vector(11 downto 0);
    signal R:       std_logic_vector(11 downto 0);
    signal B:       std_logic_vector(11 downto 0);
    signal G2:      std_logic_vector(11 downto 0);

    signal pixel:   std_logic_vector(15 downto 0);

begin

    -- instantiate the pixel merger
    dut: entity work.PixelMerger
    port map(
        G1 => G1,
        R => R,
        B => B,
        G2 => G2,
        pixel => pixel
    );

    -- test the UART
    simulation: process

        procedure checkMerge(
            green1: in std_logic_vector(11 downto 0);
            red: in std_logic_vector(11 downto 0);
            blue: in std_logic_vector(11 downto 0);
            green2: in std_logic_vector(11 downto 0);
            expected_out: in std_logic_vector(15 downto 0)
        ) is
        begin
            G1 <= green1;
            R <= red;
            B <= blue;
            G2 <= green2;

            wait for WAIT_PERIOD;

            assert pixel = expected_out
            report "Unexpected result: " &
                    "Read = " & integer'image(to_integer(unsigned(pixel))) &
                    "Expected = " & integer'image(to_integer(unsigned(expected_out)))
            severity error;
        end procedure;

    begin

        checkMerge("111100000000", "010101010101", "101010101010", "111100000000", "0101011110010101");
        checkMerge("111000000000", "111111111111", "000000000000", "000111000000", "1111101111100000");
        wait;

    end process;

end architecture test;