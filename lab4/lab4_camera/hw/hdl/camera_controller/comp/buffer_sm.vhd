library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BufferSm is
    port(
        nReset:         in std_logic;
        clk:            in std_logic;

        -- conduit for synchronization
        bufferDisp:     in std_logic;
        bufferCapt:     in std_logic;

        -- output
        bufferReady:    out std_logic
    );
end BufferSm;

architecture comp of BufferSm is

    -- Buffer state machine
    type buffer_type is ( -- https://vhdlguide.readthedocs.io/en/latest/vhdl/fsm.html
        empty,
        capturing,
        full,
        displaying
    );

    signal buffer_state:        buffer_type := empty;

begin

    -- Buffer state machine (drives buffer_state signal)
    process(clk, nReset)
    begin
        if nReset = '0' then
            buffer_state <= empty;
        elsif rising_edge(clk) then
            case buffer_state is
                when empty => 
                    if bufferCapt = '1' then
                        buffer_state <= capturing;
                    end if;
                when capturing =>
                    if bufferCapt = '0' then
                        buffer_state <= full;
                    end if;
                when full => 
                    if bufferDisp = '1' then
                        buffer_state <= displaying;
                    end if;
                when displaying =>
                    if bufferDisp = '0' then
                        buffer_state <= empty;
                    end if;
            end case;
        end if;
    end process;

    -- drive bufferReady signal
    bufferReady <= '1' when buffer_state = empty else '0';

end comp ; -- comp