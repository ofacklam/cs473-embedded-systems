library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dma is
    generic(
        burstsize:      positive range 1 to 128
    );
    port(
        nReset:         in std_logic;
        clk:            in std_logic;
        
        -- Control signals
        enableDma:      in std_logic;
        bufAddress:     in std_logic_vector(31 downto 0);
        bufLength:      in std_logic_vector(31 downto 0);
        
        -- Connection to other controller modules
        data:           in std_logic_vector(31 downto 0);
        size:           in std_logic_vector(11 downto 0);
        read:           out std_logic;

        -- Avalon master interface
        AM_address:     out std_logic_vector(31 downto 0);
        AM_write:       buffer std_logic := '0';
        AM_writedata:   out std_logic_vector(31 downto 0);
        AM_burstcount:  out std_logic_vector(7 downto 0);
        AM_waitreq:     in std_logic
    );
end Dma;

architecture comp of Dma is

    -- State machine
    type burst_type is ( -- https://vhdlguide.readthedocs.io/en/latest/vhdl/fsm.html
        idle, 
        burstprepare, 
        burst, 
        burstend
    );
    signal burst_state:         burst_type := idle;
    
    signal currentAddress:      unsigned(31 downto 0);
    signal counter:             natural range 0 to burstsize;

begin

    -- Burst state machine (drives burst_state, currentAddress, counter, AM_write, AM_burstcount)
    process(clk, nReset)

        procedure handleIdle is
        begin
            if enableDMA = '1' then
                currentAddress <= unsigned(bufAddress);
                burst_state <= burstprepare;
            end if;
        end procedure;

        procedure handlePrepare is
        begin
            if enableDMA = '0' then
                burst_state <= idle;
            elsif unsigned(size) >= burstsize then
                AM_write <= '1';
                AM_burstcount <= std_logic_vector(to_unsigned(burstsize, 8));
                counter <= 0;
                burst_state <= burst;
            end if;
        end procedure;

        procedure handleBurst is
        begin
            if AM_write = '1' and AM_waitreq = '0' then
                if counter < burstsize - 1 then     -- continue burst
                    counter <= counter + 1;
                else                                -- stop burst
                    AM_write <= '0';
                    burst_state <= burstend;
                end if;
            end if;
        end procedure;

        procedure handleEnd is
        begin
            if currentAddress + 8*burstsize <= unsigned(bufAddress) + unsigned(bufLength) then
                currentAddress <= currentAddress + 4*burstsize;
            end if;
            burst_state <= burstprepare;
        end procedure;

    begin
        if nReset = '0' then
            burst_state <= idle;
            AM_write <= '0';
        elsif rising_edge(clk) then
            case burst_state is
                when idle => handleIdle;
                when burstprepare => handlePrepare;
                when burst => handleBurst;
                when burstend => handleEnd;
            end case;
        end if;
    end process;

    -- remaining signals logic
    AM_address <= std_logic_vector(currentAddress);
    AM_writedata <= data;
    read <= AM_write and not AM_waitreq;

end comp ; -- comp