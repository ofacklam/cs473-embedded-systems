library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Registers is
    port(
        nReset:         in std_logic;
        clk:            in std_logic;

        -- Avalon slave
        AS_address:     in std_logic;
        AS_read:        in std_logic;
        AS_readdata:    out std_logic_vector(31 downto 0) := (others => '0');
        AS_write:       in std_logic;
        AS_writedata:   in std_logic_vector(31 downto 0);

        -- connection to other controller modules
        buf0Address:    buffer std_logic_vector(31 downto 0) := (others => '0');
        bufLength:      buffer std_logic_vector(31 downto 0) := (others => '0');
        bufNumber:      buffer unsigned(2 downto 0) := (others => '0')
    );
end Registers;

architecture comp of Registers is
begin

    -- Avalon slave write
    process(clk, nReset)
    begin
        if nReset = '0' then
            buf0Address <= (others => '0');
            bufLength <= (others => '0');
            bufNumber <= (others => '0');
        elsif rising_edge(clk) then
            if AS_write = '1' then
                if AS_address = '0' then
                    buf0Address <= AS_writedata;
                elsif AS_address = '1' then
                    bufLength <= "000" & AS_writedata(28 downto 0);
                    bufNumber <= unsigned(AS_writedata(31 downto 29));
                end if;
            end if;
        end if;
    end process;

    -- Avalon slave read
    process(clk, nReset)
    begin
        if nReset = '0' then
            AS_readdata <= (others => '0');
        elsif rising_edge(clk) then
            if AS_read = '1' then
                if AS_address = '0' then
                    AS_readdata <= buf0Address;
                elsif AS_address = '1' then
                    AS_readdata <= std_logic_vector(bufNumber) & bufLength(28 downto 0);
                end if;
            end if;
        end if;
    end process;

end comp ; -- comp