library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartRX is
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
        outputdata:     out std_logic_vector(7 downto 0) := "00000000";
        dataok:         out std_logic := '0';

        -- Conduit
        RX:     in std_logic
    );
end UartRX;

architecture comp of UartRX is

    signal ready:       std_logic := '1';
    signal pending:     std_logic := '0';
    signal index:       natural range 0 to 15;
    signal paritybit:   std_logic;
    signal counter:     unsigned(7 downto 0);

begin

    -- reception triggered by RX falling edge, logic synchronous to the slow clock
    process(clk, nReset, RX)
        variable baudTick: boolean;
        variable maxVal: unsigned(7 downto 0);

        -- https://www.thecodingforums.com/threads/driving-external-signals-from-a-procedure.498549/
        -- function inspired from https://vhdlwhiz.com/using-procedure/
        procedure tickCounter(variable maxVal: in unsigned(7 downto 0); variable wrapped: out boolean) is
        begin
            if counter = maxVal - 1 then
                counter <= (others => '0');
                wrapped := true;
            else
                counter <= counter + 1;
                wrapped := false;
            end if;
        end procedure;

        procedure handlePendingTimeout is
        begin
            if RX = '0' then    -- to START
                pending <= '0';
                dataok <= '0';
                index <= 0;
                paritybit <= '0';
            else                -- to IDLE
                pending <= '0';
                ready <= '1';
            end if;
        end procedure;

        procedure toData is
        begin
            outputdata(index) <= RX;
            paritybit <= paritybit xor RX;
            index <= index + 1;
        end procedure;

        procedure toFlush is
        begin
            if RX = '1' then
                if parityenable = '0' or paritybit = parityodd then
                    dataok <= '1';
                end if;
            end if;
        end procedure;

        procedure toIdle is
        begin
            ready <= '1';
        end procedure;

        procedure handleBaudTimeout is 
        begin
            if index >= 8 then      -- DATA to FLUSH/IDLE
                toFlush;
                toIdle;
            else                    -- DATA
                toData;
            end if;
        end procedure;


    begin
        if nReset = '0' then
            ready <= '1';
            pending <= '0';
            dataok <= '0';
        elsif rising_edge(clk) then
            if ready = '1' and RX = '0' then -- IDLE to PENDING
                ready <= '0';
                pending <= '1';
                counter <= (others => '0');
            end if;
            if clken = '1' then
                if ready = '0' then     -- BUSY state
                    if pending = '1' then   -- PENDING state
                        maxVal := baudrate / 2;
                        tickCounter(maxVal, baudTick);
                        if baudTick then
                            handlePendingTimeout;
                        end if;
                    else
                        maxVal := baudrate;
                        tickCounter(maxVal, baudTick);
                        if baudTick then
                            handleBaudTimeout;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end comp ; -- comp