library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fsm is
    generic(
        maxBuffers:     positive
    );
    port(
        nReset:         in std_logic;
        clk:            in std_logic;
        
        -- to registers
        buf0Address:    in std_logic_vector(31 downto 0);
        bufLength:      in std_logic_vector(31 downto 0);
        bufNumber:      in unsigned(2 downto 0);
        
        -- to camera interface
        enableCam:      out std_logic := '0';
        frameActive:    in std_logic;

        -- to DMA
        empty:          in std_logic;
        enableDMA:      out std_logic := '0';
        dmaBufAddr:     out std_logic_vector(31 downto 0);
        dmaBufLen:      out std_logic_vector(31 downto 0);

        -- conduit for synchronization
        bufferDisp:     in std_logic_vector(maxBuffers downto 0);
        bufferCapt:     buffer std_logic_vector(maxBuffers downto 0) := (others => '0')
    );
end Fsm;

architecture comp of Fsm is 

    -- Main state machine
    type operation_type is ( -- https://vhdlguide.readthedocs.io/en/latest/vhdl/fsm.html
        idle, 
        armed, 
        enabled, 
        busy,
        flushing
    );
    signal operation_state:     operation_type := idle;
    signal index:               natural range 0 to maxBuffers := 0;

    -- Buffer state machine
    signal buffer_ready:        std_logic_vector(maxBuffers-1 downto 0);

    component BufferSm
        port(
            nReset:         in std_logic;
            clk:            in std_logic;
            bufferDisp:     in std_logic;
            bufferCapt:     in std_logic;
            bufferReady:    out std_logic
        );
    end component;

begin

    -- Buffer state machine (drives buffer_ready signal)
    generate_buffer_sms: for i in 0 to maxBuffers-1 generate -- https://www.ics.uci.edu/~jmoorkan/vhdlref/generate.html
        BSM: BufferSm
        port map(
            nReset => nReset,
            clk => clk,
            bufferDisp => bufferDisp(i),
            bufferCapt => bufferCapt(i),
            bufferReady => buffer_ready(i)
        );
    end generate generate_buffer_sms;

    -- Main state machine (drives operation_state, index, enableCam, enableDma, bufferCapt signals)
    process(clk, nReset)

        procedure handleIdle is
        begin
            if index >= bufNumber then
                index <= 0;
            elsif buffer_ready(index) = '1' and unsigned(bufLength) > 0 then
                operation_state <= armed;
                bufferCapt(index) <= '1';
            end if;
        end procedure;

        procedure handleArmed is
        begin
            if frameActive = '0' then
                operation_state <= enabled;
                enableCam <= '1';
                enableDma <= '1';
            end if;
        end procedure;

        procedure handleEnabled is
        begin
            if frameActive = '1' then
                operation_state <= busy;
            end if;
        end procedure;

        procedure handleBusy is
        begin
            if frameActive = '0' then
                operation_state <= flushing;
                enableCam <= '0';
            end if;
        end procedure;

        procedure handleFlushing is
        begin
            if empty = '1' then
                operation_state <= idle;
                enableDma <= '0';
                bufferCapt(index) <= '0';

                if index >= maxBuffers-1 then
                    index <= 0;
                else
                    index <= index + 1;
                end if;
            end if;
        end procedure;

    begin
        if nReset = '0' then
            operation_state <= idle;
            index <= 0;
            enableCam <= '0';
            enableDma <= '0';
            bufferCapt <= (others => '0');
        elsif rising_edge(clk) then
            case operation_state is
                when idle => handleIdle;
                when armed => handleArmed;
                when enabled => handleEnabled;
                when busy => handleBusy;
                when flushing => handleFlushing;
            end case;
        end if;
    end process;

    -- remaining signals logic
    dmaBufAddr <= std_logic_vector(to_unsigned(
        to_integer(unsigned(buf0Address)) + index * to_integer(unsigned(bufLength)),
        32
    ));
    dmaBufLen <= bufLength;

end comp ; -- comp