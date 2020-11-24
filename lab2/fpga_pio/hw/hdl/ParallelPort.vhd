library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ParallelPort is
    port(
        clk: in std_logic;
        nReset: in std_logic;

        -- Avalon slave
        address: in std_logic_vector(2 downto 0);
        write: in std_logic;
        read: in std_logic;
        writedata: in std_logic_vector(7 downto 0);
        readdata: out std_logic_vector(7 downto 0);

        -- Conduit
        ParPort: inout std_logic_vector(7 downto 0)
    );
end ParallelPort;

architecture comp of ParallelPort is

    signal iRegDir: std_logic_vector(7 downto 0);
    signal iRegPin: std_logic_vector(7 downto 0);
    signal iRegPort: std_logic_vector(7 downto 0);

begin

    -- output value
    process(iRegDir, iRegPort)
    begin
        for i in 0 to 7 loop
            if iRegDir(i) = '1' then
                ParPort(i) <= iRegPort(i);
            else
                ParPort(i) <= 'Z';   
            end if;
        end loop;
    end process;

    -- input value
    iRegPin <= ParPort;

    -- avalon slave write to regs
    process(clk, nReset)
    begin
        if nReset = '0' then
            iRegDir <= (others => '0');
            iRegPort <= (others => '0');
        elsif rising_edge(clk) then
            if write = '1' then
                case( address ) is                
                    when "000" => iRegDir <= writedata;
                    when "010" => iRegPort <= writedata;
                    when "011" => iRegPort <= iRegPort or writedata;
                    when "100" => iRegPort <= iRegPort and not writedata;
                    when others => null;
                end case ;
            end if;
        end if;
    end process;

    -- avalon slave read from regs
    process(clk)
    begin
        if rising_edge(clk) then
            readdata <= (others => '0');
            if read = '1' then
                case( address ) is
                    when "000" => readdata <= iRegDir;
                    when "001" => readdata <= iRegPin;
                    when "010" => readdata <= iRegPort;
                    when others => null;
                end case ;
            end if;
        end if;
    end process;

end comp ; -- comp