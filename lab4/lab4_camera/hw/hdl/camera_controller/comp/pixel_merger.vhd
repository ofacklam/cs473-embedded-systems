library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PixelMerger is
    port(
        G1:     in std_logic_vector(11 downto 0);
        R:      in std_logic_vector(11 downto 0);
        B:      in std_logic_vector(11 downto 0);
        G2:     in std_logic_vector(11 downto 0);

        pixel:  out std_logic_vector(15 downto 0)
    );
end PixelMerger;

architecture comp of PixelMerger is

    signal greenSum: std_logic_vector(12 downto 0);

begin

    greenSum <= std_logic_vector(unsigned("0" & G1) + unsigned("0" & G2));
    pixel <= R(11 downto 7) & greenSum(12 downto 7) & B(11 downto 7);

end comp ; -- comp