library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CameraController is
    generic(
        maxBuffers:     positive                    := 4;
        burstsize:      positive range 1 to 128     := 80
    );
    port(
        -- clock
        nReset:         in std_logic;
        clk:            in std_logic;
        
        -- Avalon slave
        AS_address:     in std_logic;
        AS_read:        in std_logic;
        AS_readdata:    out std_logic_vector(31 downto 0);
        AS_write:       in std_logic;
        AS_writedata:   in std_logic_vector(31 downto 0);

        -- Avalon master
        AM_address:     out std_logic_vector(31 downto 0);
        AM_write:       out std_logic;
        AM_writedata:   out std_logic_vector(31 downto 0);
        AM_burstcount:  out std_logic_vector(7 downto 0);
        AM_waitreq:     in std_logic;

        -- Camera
        pixclk:         in std_logic;
        data:           in std_logic_vector(11 downto 0);
        lval:           in std_logic;
        fval:           in std_logic;

        -- Synchronization
        bufferDisp:     in std_logic_vector(maxBuffers-1 downto 0);
        bufferCapt:     out std_logic_vector(maxBuffers-1 downto 0)
    );
end CameraController;

architecture comp of CameraController is 

    -- Registers
    signal buf0Address:     std_logic_vector(31 downto 0);
    signal bufLength:       std_logic_vector(31 downto 0);
    signal bufNumber:       unsigned(2 downto 0);

    -- Camera
    signal enableCam:       std_logic;
    signal frameActive:     std_logic;
    
    -- DMA
    signal enableDma:       std_logic;
    signal dmaBufAddress:   std_logic_vector(31 downto 0);
    signal dmaBufLength:    std_logic_vector(31 downto 0);

    -- FIFO write
    signal pixelData:       std_logic_vector(15 downto 0);
    signal pixelWrite:      std_logic;
    signal pixelFull:       std_logic;
    signal pixelClear:      std_logic;

    -- FIFO read
    signal q:            std_logic_vector(31 downto 0);
    signal read:            std_logic;
    signal empty:           std_logic;
    signal size:            std_logic_vector(11 downto 0);

    -- Components
    component Registers
        port(
            nReset:         in std_logic;
            clk:            in std_logic;

            AS_address:     in std_logic;
            AS_read:        in std_logic;
            AS_readdata:    out std_logic_vector(31 downto 0);
            AS_write:       in std_logic;
            AS_writedata:   in std_logic_vector(31 downto 0);

            buf0Address:    buffer std_logic_vector(31 downto 0);
            bufLength:      buffer std_logic_vector(31 downto 0);
            bufNumber:      buffer unsigned(2 downto 0)
        );
    end component;

    component Fsm
        generic(
            maxBuffers:     positive
        );
        port(
            nReset:         in std_logic;
            clk:            in std_logic;

            buf0Address:    in std_logic_vector(31 downto 0);
            bufLength:      in std_logic_vector(31 downto 0);
            bufNumber:      in unsigned(2 downto 0);
            
            enableCam:      out std_logic;
            frameActive:    in std_logic;

            empty:          in std_logic;
            enableDMA:      out std_logic;
            dmaBufAddr:     out std_logic_vector(31 downto 0);
            dmaBufLen:      out std_logic_vector(31 downto 0);

            bufferDisp:     in std_logic_vector(maxBuffers-1 downto 0);
            bufferCapt:     buffer std_logic_vector(maxBuffers-1 downto 0)
        );
    end component;

    component CamInterface
        port(
            nReset:         in std_logic;
            enableCam:      in std_logic;

            pixclk:         in std_logic;
            data:           in std_logic_vector(11 downto 0);
            lval:           in std_logic;
            fval:           in std_logic;
            
            pixelData:      out std_logic_vector(15 downto 0);
            pixelWrite:     out std_logic;
            pixelFull:      in std_logic;
            frameActive:    out std_logic
        );
    end component;

    component Dma
        generic(
            burstsize:      positive range 1 to 128
        );
        port(
            nReset:         in std_logic;
            clk:            in std_logic;
            
            enableDma:      in std_logic;
            bufAddress:     in std_logic_vector(31 downto 0);
            bufLength:      in std_logic_vector(31 downto 0);
            
            data:           in std_logic_vector(31 downto 0);
            size:           in std_logic_vector(11 downto 0);
            read:           out std_logic;

            AM_address:     out std_logic_vector(31 downto 0);
            AM_write:       buffer std_logic;
            AM_writedata:   out std_logic_vector(31 downto 0);
            AM_burstcount:  out std_logic_vector(7 downto 0);
            AM_waitreq:     in std_logic
        );
    end component;

    component double_clk_fifo
        PORT(
            aclr:       IN STD_LOGIC  := '0';
            data:       IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            rdclk:      IN STD_LOGIC ;
            rdreq:      IN STD_LOGIC ;
            wrclk:      IN STD_LOGIC ;
            wrreq:      IN STD_LOGIC ;
            q:          OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            rdempty:    OUT STD_LOGIC ;
            rdusedw:    OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
            wrfull:     OUT STD_LOGIC 
        );
    end component;

begin

    -- Registers component
    regs: Registers
    port map(
        nReset => nReset,
        clk => clk,
        AS_address => AS_address,
        AS_read => AS_read,
        AS_readdata => AS_readdata,
        AS_write => AS_write,
        AS_writedata => AS_writedata,
        buf0Address => buf0Address,
        bufLength => bufLength,
        bufNumber => bufNumber
    );

    -- FSM component
    state_machine: Fsm
    generic map(
        maxBuffers => maxBuffers
    )
    port map(
        nReset => nReset,
        clk => clk,
        buf0Address => buf0Address,
        bufLength => bufLength,
        bufNumber => bufNumber,
        enableCam => enableCam,
        frameActive => frameActive,
        empty => empty,
        enableDMA => enableDma,
        dmaBufAddr => dmaBufAddress,
        dmaBufLen => dmaBufLength,
        bufferDisp => bufferDisp,
        bufferCapt => bufferCapt
    );

    -- Camera Interface component
    cam: CamInterface
    port map(
        nReset => nReset,
        enableCam => enableCam,
        pixclk => pixclk,
        data => data,
        lval => lval,
        fval => fval,
        pixelData => pixelData,
        pixelWrite => pixelWrite,
        pixelFull => pixelFull,
        frameActive => frameActive
    );

    -- DMA component
    master: Dma
    generic map(
        burstsize => burstsize
    )
    port map(
        nReset => nReset,
        clk => clk,
        enableDma => enableDma,
        bufAddress => dmaBufAddress,
        bufLength => dmaBufLength,
        data => q,
        size => size,
        read => read,
        AM_address => AM_address,
        AM_write => AM_write,
        AM_writedata => AM_writedata,
        AM_burstcount => AM_burstcount,
        AM_waitreq => AM_waitreq
    );

    -- Pixel DCFIFO component
    pxfifo: double_clk_fifo
    port map(
        aclr => pixelClear,
        data => pixelData,
        rdclk => clk,
        rdreq => read,
        wrclk => pixclk,
        wrreq => pixelWrite,
        q => q,
        rdempty => empty,
        rdusedw => size,
        wrfull => pixelFull
    );
    pixelClear <= not nReset;

end comp ; -- comp