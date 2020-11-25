library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ClockDivider is
    port(
        nReset:     in std_logic;
        clk:        in std_logic;
        clkdiv:     in unsigned(2 downto 0);

        clken:      out std_logic := '0' -- slow clock
    );
end ClockDivider;

architecture comp of ClockDivider is

    signal counter: unsigned(7 downto 0) := "00000000";
    signal maxVal: unsigned(7 downto 0);

begin

    -- for bit shift syntax: https://www.edaboard.com/threads/vhdl-code-to-obtain-2-n-for-the-input-n-can-u-help-me-plssssssss.236516/
    maxVal <= x"01" sll to_integer(clkdiv);

    process(clk, nReset)
    begin
        if nReset = '0' then
            counter <= (others => '0');
            clken <= '0';
        elsif rising_edge(clk) then
            if counter = maxVal - 1 then
                counter <= (others => '0');
                clken <= '1';
            else
                counter <= counter + 1;
                clken <= '0';
            end if;
        end if;
    end process;

end comp ; -- comp