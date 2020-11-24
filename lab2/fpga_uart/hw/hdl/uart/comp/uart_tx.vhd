library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartTX is
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
        ready:          buffer std_logic := '1';
        start:          in std_logic;

        -- Conduit
        TX:     out std_logic := '1'
    );
end UartTX;

architecture comp of UartTX is

    signal index:       natural;
    signal localdata:   std_logic_vector(7 downto 0);
    signal paritybit:   std_logic;
    signal counter:     unsigned(7 downto 0);

begin

    -- everything synchronous to the slow clock
    process(clk, nReset)
        variable baudTick: boolean;

        -- https://www.thecodingforums.com/threads/driving-external-signals-from-a-procedure.498549/
        -- function inspired from https://vhdlwhiz.com/using-procedure/
        procedure tickCounter(variable wrapped: out boolean) is
        begin
            if counter = baudrate - 1 then
                counter <= (others => '0');
                wrapped := true;
            else
                counter <= counter + 1;
                wrapped := false;
            end if;
        end procedure;

        procedure handleIdle is
        begin 
            -- transition to START
            if start = '1' then
                ready <= '0';
                index <= 0;
                localdata <= inputdata;
                paritybit <= '0';
                TX <= '0';
                counter <= (others => '0');
            end if;
        end procedure;

        procedure toData is
        begin
            TX <= localdata(index);
            paritybit <= paritybit xor localdata(index);
            index <= index + 1;
        end procedure;

        procedure toParity is
        begin
            TX <= paritybit xor parityodd;
            index <= index + 1;
        end procedure;

        procedure toStop is
        begin
            TX <= '1';
            index <= index + 1;
        end procedure;

        procedure toIdle is
        begin
            ready <= '1';
            TX <= '1';
        end procedure;

        procedure handleBaudTimeout is 
        begin
            if index >= 9 then      -- STOP to IDLE
                toIdle;
            elsif index = 8 then    -- DATA to STOP
                toStop;
            else                    -- DATA or PARITY
                if index >= 7 and parityenable = '1' then
                    toParity;
                else
                    toData;
                end if;
            end if;
        end procedure;


    begin
        if nReset = '0' then
            ready <= '1';
            TX <= '1';
        elsif rising_edge(clk) then
            if clken = '1' then
                if ready = '1' then     -- IDLE state
                    handleIdle;
                else                    -- BUSY state
                    tickCounter(baudTick);
                    if baudTick then    -- Baud Timeout
                        handleBaudTimeout;
                    end if;
                end if;
            end if;
        end if;
    end process;

end comp ; -- comp