library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Uart is
    port(
        nReset:     in std_logic;
        clk:        in std_logic;

        -- Avalon slave
        address:    in std_logic_vector(1 downto 0);
        read:       in std_logic;
        readdata:   out std_logic_vector(7 downto 0);
        write:      in std_logic;
        writedata:  in std_logic_vector(7 downto 0);
        
        -- Conduit
        TX:         out std_logic;
        RX:         in std_logic
    );
end Uart;

architecture comp of Uart is

    -- Register CTRLA
    signal RXavailable:         std_logic := '0';
    signal TXready:             std_logic := '1';
    signal parityenable:        std_logic := '0';
    signal parityodd:           std_logic := '0';
    signal clkdiv:              unsigned(2 downto 0) := "000";

    -- Register CTRLB
    signal baudrate:            unsigned(7 downto 0) := X"64";

    -- Register RXDATA
    signal RXdata:              std_logic_vector(7 downto 0) := X"00";

    -- Register TXDATA
    signal TXdata:              std_logic_vector(7 downto 0) := X"00";

    -- Internal signals
    signal clken:               std_logic; -- for clock divider

    signal ready:               std_logic; -- for TX
    signal start:               std_logic := '0';
    
    signal outputdata:          std_logic_vector(7 downto 0); -- for RX
    signal dataok:              std_logic;
    signal newdata:             std_logic := '1';

    -- The components
    component UartTX is
        port(
            -- timing
            nReset:     in std_logic;
            clk:        in std_logic;
            clken:      in std_logic; -- slow clock
            baudrate:   in unsigned(7 downto 0);

            -- parity setting
            parityenable:   in std_logic;
            parityodd:      in std_logic;

            -- data
            inputdata:      in std_logic_vector(7 downto 0);
            ready:          buffer std_logic;
            start:          in std_logic;

            -- Conduit
            TX:     out std_logic
        );
    end component;

    component UartRX is
        port (
            -- timing
            nReset:     in std_logic;
            clk:        in std_logic;
            clken:      in std_logic; -- slow clock
            baudrate:   in unsigned(7 downto 0);

            -- parity setting
            parityenable:   in std_logic;
            parityodd:      in std_logic;

            -- data
            outputdata:     out std_logic_vector(7 downto 0);
            dataok:         out std_logic;

            -- Conduit
            RX:     in std_logic
        );
    end component;

    component ClockDivider is
        port (
            nReset:     in std_logic;
            clk:        in std_logic;
            clkdiv:     in unsigned(2 downto 0);

            clken:      out std_logic -- slow clock
        );
    end component;

begin

    -- Instantiate the 3 components
    DividerBlock: ClockDivider
    port map(
        nReset => nReset,
        clk => clk,
        clkdiv => clkdiv,
        clken => clken
    );

    TXblock: UartTX
    port map(
        nReset => nReset,
        clk => clk,
        clken => clken,
        baudrate => baudrate,
        parityenable => parityenable,
        parityodd => parityodd,
        inputdata => TXdata,
        ready => ready,
        start => start,
        TX => TX
    );
    start <= not TXready;

    RXblock: UartRX
    port map(
        nReset => nReset,
        clk => clk,
        clken => clken,
        baudrate => baudrate,
        parityenable => parityenable,
        parityodd => parityodd,
        outputdata => outputdata,
        dataok => dataok,
        RX => RX
    );

    
    -- Avalon slave writes
    process(clk, nReset)

        procedure writeCtrlA(data: std_logic_vector(7 downto 0)) is
        begin
            parityenable <= data(2);
            parityodd <= data(3);
            clkdiv <= unsigned(data(6 downto 4));
        end procedure;

        procedure writeCtrlB(data: std_logic_vector(7 downto 0)) is
            variable br: unsigned(7 downto 0);
        begin
            br := unsigned(data);
            if br >= 4 then -- only accept baud rates >= 4 ticks/bit
                baudrate <= br and "11111110";
            end if;
        end procedure;

        procedure writeTXdata(data: std_logic_vector(7 downto 0)) is
        begin
            TXdata <= data;
            TXready <= '0';
        end procedure;

    begin
        if nReset = '0' then
            TXready <= '1';
            parityenable <= '0';
            parityodd <= '0';
            clkdiv <= "000";
            baudrate <= X"64";
            TXdata <= (others => '0');
        elsif rising_edge(clk) then
            if clken = '1' and start = '1' and ready = '1' then -- slow clock tick with TX ready => transmission started
                TXready <= '1';
            end if;
            if write = '1' then -- avalon write
                case (address) is
                    when "00" => writeCtrlA(writedata);
                    when "01" => writeCtrlB(writedata);
                    when "11" => writeTXdata(writedata);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Avalon slave reads
    process(clk, nReset)

        procedure readCtrlA is
            variable hi: std_logic_vector(3 downto 0);
            variable lo: std_logic_vector(3 downto 0);
        begin
            hi := "0" & std_logic_vector(clkdiv);
            lo := parityodd & parityenable & TXready & RXavailable;
            readdata <= hi & lo;
        end procedure;

        procedure readRXdata is
        begin
            readdata <= RXdata;
            RXavailable <= '0';
        end procedure;

    begin
        if nReset = '0' then
            RXavailable <= '0';
            RXdata <= (others => '0');
            newdata <= '1';
        elsif rising_edge(clk) then
            if read = '1' then -- avalon read
                case (address) is
                    when "00" => readCtrlA;
                    when "01" => readdata <= std_logic_vector(baudrate);
                    when "10" => readRXdata;
                    when "11" => readdata <= TXdata;
                    when others => null;
                end case;
            end if;
            if newdata = '1' and dataok = '1' then -- new data from RX
                RXdata <= outputdata;
                newdata <= '0';
                RXavailable <= '1';
            end if;
            if newdata = '0' and dataok = '0' then -- new RX starting
                newdata <= '1';
            end if;
        end if;
    end process;

end comp ; -- comp