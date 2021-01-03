library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CamInterface is
    port(
        -- Control logic
        nReset:     in std_logic;
        enableCam:  in std_logic;

        -- Camera input conduits
        pixclk:     in std_logic;
        data:       in std_logic_vector(11 downto 0);
        lval:       in std_logic;
        fval:       in std_logic;
        
        -- Connection to other controller modules
        pixelData:      out std_logic_vector(15 downto 0);
        pixelWrite:     out std_logic;
        pixelFull:      in std_logic;
        frameActive:    out std_logic
    );
end CamInterface;

architecture comp of CamInterface is

    -- State machine
    type row_type is ( -- https://vhdlguide.readthedocs.io/en/latest/vhdl/fsm.html
        inactive, 
        pre_row_even, 
        row_even, 
        pre_row_odd, 
        row_odd
    ); 
    signal row_state:           row_type := inactive;
    signal row_is_even:         std_logic; -- convert bool to std_logic https://electronics.stackexchange.com/a/158721
    signal row_is_odd:          std_logic;

    type col_type is (
        inactive,
        col_even,
        col_odd
    );
    signal col_state:           col_type := inactive;
    signal col_is_even:         std_logic;
    signal col_is_odd:          std_logic;

    -- Green1 FIFO
    signal greenData:           std_logic_vector(11 downto 0);
    signal greenFull:           std_logic;
    signal greenWrite:          std_logic;
    signal greenEmpty:          std_logic;
    signal greenRead:           std_logic;
    signal G1:                  std_logic_vector(11 downto 0);

    -- Red FIFO
    signal redData:             std_logic_vector(11 downto 0);
    signal redFull:             std_logic;
    signal redWrite:            std_logic;
    signal redEmpty:            std_logic;
    signal redRead:             std_logic;
    signal R:                   std_logic_vector(11 downto 0);

    -- Blue register
    signal B:                   std_logic_vector(11 downto 0);
    
    -- Green2 register
    signal G2:                  std_logic_vector(11 downto 0);

    -- The components
    component single_clk_fifo
        PORT (
            aclr:       IN STD_LOGIC ;
            clock:      IN STD_LOGIC ;
            data:       IN STD_LOGIC_VECTOR (11 DOWNTO 0);
            rdreq:      IN STD_LOGIC ;
            wrreq:      IN STD_LOGIC ;
            empty:      OUT STD_LOGIC ;
            full:       OUT STD_LOGIC ;
            q:          OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
        );
    end component;

    component PixelMerger
        port(
            G1:     in std_logic_vector(11 downto 0);
            R:      in std_logic_vector(11 downto 0);
            B:      in std_logic_vector(11 downto 0);
            G2:     in std_logic_vector(11 downto 0);

            pixel:  out std_logic_vector(15 downto 0)
        );
    end component;

begin

    -- Row state machine
    process(pixclk, nReset)
    begin
        if nReset = '0' then
            row_state <= inactive;
        elsif falling_edge(pixclk) then
            case row_state is
                when inactive => 
                    if fval = '1' then
                        row_state <= pre_row_even;
                    end if;
                when pre_row_even => 
                    if fval = '0' then
                        row_state <= inactive;
                    elsif lval = '1' then
                        row_state <= row_even;
                    end if;
                when row_even =>
                    if fval = '0' then
                        row_state <= inactive;
                    elsif lval = '0' then
                        row_state <= pre_row_odd;
                    end if;
                when pre_row_odd =>
                    if fval = '0' then
                        row_state <= inactive;
                    elsif lval = '1' then
                        row_state <= row_odd;
                    end if;
                when row_odd => 
                    if fval = '0' then
                        row_state <= inactive;
                    elsif lval = '0' then
                        row_state <= pre_row_even;
                    end if;
            end case;
        end if;
    end process;

    row_is_even <= '1' when (row_state = pre_row_even or row_state = row_even) else '0';
    row_is_odd <= '1' when (row_state = pre_row_odd or row_state = row_odd) else '0';


    -- Column state machine
    process(pixclk, nReset)
    begin
        if nReset = '0' then
            col_state <= inactive;
        elsif falling_edge(pixclk) then
            case col_state is
                when inactive =>
                    if lval = '1' then
                        col_state <= col_odd;
                    end if;
                when col_odd => 
                    if lval = '0' then
                        col_state <= inactive;
                    else
                        col_state <= col_even;
                    end if;
                when col_even =>
                    if lval = '0' then
                        col_state <= inactive;
                    else
                        col_state <= col_odd;
                    end if;
            end case;
        end if;
    end process;

    col_is_even <= '1' when (col_state = inactive or col_state = col_even) else '0';
    col_is_odd <= '1' when col_state = col_odd else '0';


    -- Green1 FIFO
    greenFifo: single_clk_fifo
    port map(
        aclk => not nReset,
        clock => pixclk,
        data => greenData,
        rdreq => greenRead,
        wrreq => greenWrite,
        empty => greenEmpty,
        full => greenFull,
        q => G1
    );

    greenWrite <= enableCam and nReset and fval and lval and row_is_even and col_is_odd and (not greenFull);
    greenRead <= enableCam and nReset and fval and lval and row_is_odd and col_is_odd and (not greenEmpty);


    -- Red FIFO
    redFifo: single_clk_fifo
    port map(
        aclk => not nReset,
        clock => pixclk,
        data => redData,
        rdreq => redRead,
        wrreq => redWrite,
        empty => redEmpty,
        full => redFull,
        q => R
    );

    redWrite <= enableCam and nReset and fval and lval and row_is_even and col_is_even and (not redFull);
    redRead <= enableCam and nReset and fval and lval and row_is_odd and col_is_odd and (not redEmpty);


    -- Debayerisation process
    process(pixclk, nReset)
    begin
        if nReset = '0' then
            greenData <= (others => '0');
            redData <= (others => '0');
            B <= (others => '0');
            G2 <= (others => '0');
        elsif falling_edge(pixclk) then
            if row_is_even = '1' then
                if col_is_even = '1' then
                    greenData <= data;
                end if;
                if col_is_odd = '1' then
                    redData <= data;
                end if;
            end if;
            if row_is_odd = '1' then
                if col_is_even = '1' then
                    B <= data;
                end if;
                if col_is_odd = '1' then
                    G2 <= data;
                end if;
            end if;
        end if;
    end process;


    -- Pixel merger
    merger: PixelMerger
    port map(
        G1 => G1,
        R => R,
        B => B, 
        G2 => G2, 
        pixel => pixelData
    );

    pixelWrite <= enableCam and nReset and fval and lval and row_is_odd and col_is_even and (not pixelFull);
    frameActive <= fval;

end comp ; -- comp