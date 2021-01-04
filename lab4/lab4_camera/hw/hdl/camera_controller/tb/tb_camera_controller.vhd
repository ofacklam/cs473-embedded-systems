library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_camera_controller is
end tb_camera_controller;

architecture test of tb_camera_controller is

    constant CLK_PERIOD: time := 100 ns;
    signal test_finished: boolean := false;

    -- variable settings
    constant MAX_BUFS: positive := 4;
    constant BURST_SIZE: positive := 2;

    -- Camera Controller signals
    signal nReset:          std_logic;
    signal clk:             std_logic;
    
    signal AS_address:      std_logic;
    signal AS_read:         std_logic;
    signal AS_readdata:     std_logic_vector(31 downto 0);
    signal AS_write:        std_logic;
    signal AS_writedata:    std_logic_vector(31 downto 0);
    
    signal AM_address:      std_logic_vector(31 downto 0);
    signal AM_write:        std_logic;
    signal AM_writedata:    std_logic_vector(31 downto 0);
    signal AM_burstcount:   std_logic_vector(7 downto 0);
    signal AM_waitreq:      std_logic;
    
    signal pixclk:          std_logic;
    signal data:            std_logic_vector(11 downto 0);
    signal lval:            std_logic;
    signal fval:            std_logic;
    
    signal bufferDisp:      std_logic_vector(MAX_BUFS-1 downto 0);
    signal bufferCapt:      std_logic_vector(MAX_BUFS-1 downto 0);
    
    -- CMOS generator signals
    signal cmos_reset:      std_logic;
    signal cmos_addr:       std_logic_vector(2 downto 0);
    signal cmos_read:       std_logic;
    signal cmos_write:      std_logic;
    signal cmos_rddata:     std_logic_vector(31 downto 0);
    signal cmos_wrdata:     std_logic_vector(31 downto 0);
    signal cmos_data:       std_logic_vector(5 downto 0);

    -- simulate a memory region
    type memory is array(15 downto 0) of std_logic_vector(31 downto 0); -- 2 buffers * 2*8 pixels = 2*2*4 words
    signal buffers:         memory;
    signal counter:         natural;

begin

    -- instantiate the Camera Controller
    dut: entity work.CameraController
    generic map(
        maxBuffers => MAX_BUFS,
        burstsize => BURST_SIZE
    )
    port map(
        nReset => nReset,
        clk => clk,

        AS_address => AS_address,
        AS_read => AS_read,
        AS_readdata => AS_readdata,
        AS_write => AS_write,
        AS_writedata => AS_writedata,

        AM_address => AM_address,
        AM_write => AM_write,
        AM_writedata => AM_writedata,
        AM_burstcount => AM_burstcount,
        AM_waitreq => AM_waitreq,

        pixclk => pixclk,
        data => data,
        lval => lval,
        fval => fval,

        bufferDisp => bufferDisp,
        bufferCapt => bufferCapt
    );

    -- instantiate the CMOS generator
    cmos_sensor_output_generator_inst : entity work.cmos_sensor_output_generator
    generic map(
        PIX_DEPTH  => 6,
        MAX_WIDTH  => 16,
        MAX_HEIGHT => 4
    )
    port map(
        clk         => clk,
        reset       => cmos_reset,
        addr        => cmos_addr,
        read        => cmos_read,
        write       => cmos_write,
        rddata      => cmos_rddata,
        wrdata      => cmos_wrdata,
        frame_valid => fval,
        line_valid  => lval,
        data        => cmos_data
    );
    cmos_reset <= not nReset;
    pixclk <= clk;
    data <= cmos_data & "000000";

    -- continuous clock signal
    clk_generation: process
    begin
        if not test_finished then
            clk <= '1';
            wait for CLK_PERIOD / 2;
            clk <= '0';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process;

    -- process Avalon Master bursts
    memory_proc: process(nReset, clk)
            variable idx: natural;
    begin
        if nReset = '0' then
            buffers <= (others => (others => '0'));
            counter <= 0;
        elsif rising_edge(clk) then
            if AM_write = '1' then
                idx := counter + (to_integer(unsigned(AM_address)) - 16) / 4;
                buffers(idx) <= AM_writedata;
                if counter = unsigned(AM_burstcount) - 1 then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- test the Camera Controller
    simulation: process
    
            procedure async_reset is 
            begin
                wait until rising_edge(clk);
                wait for CLK_PERIOD / 4;
                nReset <= '0';
                wait for CLK_PERIOD / 2;
                nReset <= '1';
            end procedure async_reset;

            procedure writeCMOS(addr: in std_logic_vector(2 downto 0); val: in std_logic_vector(31 downto 0)) is
            begin
                cmos_addr <= addr;
                cmos_write <= '1';
                cmos_read <= '0';
                cmos_wrdata <= val;
                wait until rising_edge(clk);
                cmos_write <= '0';
            end procedure;

            procedure configCMOS is
            begin
                writeCMOS("110", X"00000000"); -- stop gen
                writeCMOS("000", X"00000010"); -- width = 16
                writeCMOS("001", X"00000004"); -- height = 4
                writeCMOS("010", X"00000010"); -- frame-frame = 16
                writeCMOS("011", X"00000008"); -- frame-line = 8
                writeCMOS("100", X"00000008"); -- line-line = 8
                writeCMOS("101", X"00000008"); -- line-frame = 8
                writeCMOS("110", X"00000001"); -- start gen
            end procedure;

            procedure checkBitValue(desc: in string; 
                                    actual: in std_logic; 
                                    expected: in std_logic) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Descripttion = " & desc &
                        "Read = " & std_logic'image(actual) &
                        "Expected = " & std_logic'image(expected)
                severity error;
            end procedure;

            procedure checkRegisterValue(desc: string; 
                                        actual: in std_logic_vector(31 downto 0); 
                                        expected: in std_logic_vector(31 downto 0)) is
            begin
                assert actual = expected
                report "Unexpected result: " &
                        "Description = " & desc &
                        "Read = " & integer'image(to_integer(unsigned(actual))) &
                        "Expected = " & integer'image(to_integer(unsigned(expected)))
                severity error;
            end procedure;

            procedure writeRegister(addr: in std_logic; data: in std_logic_vector(31 downto 0)) is
            begin
                -- wait until rising_edge(clk);
                AS_address <= addr;
                AS_write <= '1';
                AS_read <= '0';
                AS_writedata <= data;
                wait until rising_edge(clk);
                AS_write <= '0';
            end procedure writeRegister;

            procedure testRegister(addr: in std_logic;
                                    expected: in std_logic_vector(31 downto 0)) is
            begin
                -- wait until rising_edge(clk);
                AS_address <= addr;
                AS_write <= '0';
                AS_read <= '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk); -- 1wait
                
                checkRegisterValue(std_logic'image(addr), AS_readdata, expected);
                
                AS_read <= '0';
            end procedure testRegister;

            procedure checkMemoryFrame(frameIdx: in natural) is
                variable r1: std_logic_vector(4 downto 0);
                variable g1: std_logic_vector(5 downto 0);
                variable b1: std_logic_vector(4 downto 0);
                variable r2: std_logic_vector(4 downto 0);
                variable g2: std_logic_vector(5 downto 0);
                variable b2: std_logic_vector(4 downto 0);
                variable word: std_logic_vector(31 downto 0);
            begin
                -- a frame is 2*8 pixels = 2*4 words
                for i in 0 to 3 loop
                    r1 := std_logic_vector(to_unsigned(2*i, 5));
                    g1 := std_logic_vector(to_unsigned(8+4*i, 6));
                    b1 := std_logic_vector(to_unsigned(8+2*i, 5));
                    r2 := std_logic_vector(to_unsigned(1+2*i, 5));
                    g2 := std_logic_vector(to_unsigned(10+4*i, 6));
                    b2 := std_logic_vector(to_unsigned(9+2*i, 5));
                    word := r2 & g2 & b2 & r1 & g1 & b1;

                    assert buffers(frameIdx * 8 + i) = word
                    report "Unexpected memory word: loop 1 / frame index " & integer'image(frameIdx) & " / index " & integer'image(i)
                    severity error;
                end loop;
                for i in 0 to 3 loop
                    r1 := std_logic_vector(to_unsigned(16+2*i, 5));
                    g1 := std_logic_vector(to_unsigned(40+4*i, 6));
                    b1 := std_logic_vector(to_unsigned(24+2*i, 5));
                    r2 := std_logic_vector(to_unsigned(17+2*i, 5));
                    g2 := std_logic_vector(to_unsigned(42+4*i, 6));
                    b2 := std_logic_vector(to_unsigned(25+2*i, 5));
                    word := r2 & g2 & b2 & r1 & g1 & b1;

                    assert buffers(frameIdx * 8 + 4 + i) = word
                    report "Unexpected memory word: loop 2 / frame index " & integer'image(frameIdx) & " / index " & integer'image(i)
                    severity error;
                end loop;
            end procedure checkMemoryFrame;

    begin

        -- default values
        nReset <= '1';
        AS_read <= '0';
        AS_write <= '0';
        AM_waitreq <= '0';
        bufferDisp <= (others => '0');
        cmos_read <= '0';
        cmos_write <= '0';
        wait for CLK_PERIOD;

        -- reset
        async_reset;

        -- config CMOS
        configCMOS;

        -- test slave
        writeRegister('0', X"00000010");
        testRegister('0', X"00000010");
        writeRegister('1', X"40000020");
        testRegister('1', X"40000020");

        -- capturing has started
        wait for 360 * CLK_PERIOD;
        -- both buffers should be full
        checkMemoryFrame(0);
        checkMemoryFrame(1);

        -- capturing restarts as soon as buffer displayed
        bufferDisp(0) <= '1';
        wait until rising_edge(clk);
        bufferDisp(0) <= '0';
        wait until rising_edge(clk);
        wait for 240 * CLK_PERIOD;

        -- test done
        test_finished <= true;

    end process;

end architecture test;