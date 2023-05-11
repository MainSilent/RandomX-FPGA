library ieee;
library std;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use work.common.all;


entity tb_run is
end tb_run;


architecture test of tb_run is

    constant bram_WIDTH  : integer := 512;
    constant bram_DEPTH  : integer := 32768;
    constant bram_ADDR_W : integer := 15;

    component adapt512x64 is
        port(
            clk  : in  std_logic;
    
            mem_addr : out  std_logic_vector(14 downto 0);
            mem_din  : out  std_logic_vector(511 downto 0);
            mem_dout : in std_logic_vector(511 downto 0);
    
            addr : in  integer;
            din  : in  unsigned(63 downto 0);
            dout : out unsigned(63 downto 0)
        );
    end component;

    component bram is
        generic(
            WIDTH  : integer := bram_WIDTH;  -- data width of each memory location
            DEPTH  : integer := bram_DEPTH;  -- depth of memory
            ADDR_W : integer := bram_ADDR_W  -- address width
        );

        port(
            clk  : in  std_logic;
            we   : in  std_logic;
            addr : in  std_logic_vector(ADDR_W - 1 downto 0);
            din  : in  std_logic_vector(WIDTH - 1 downto 0);
            dout : out std_logic_vector(WIDTH - 1 downto 0)
        );
	end component;

    component hashAes1Rx4 is
        port (
            clk   : in  std_logic;
            reset : in  std_logic;
    
            hash : out std_logic_vector(511 downto 0);
            data : in std_logic_vector(511 downto 0);
            addr : out std_logic_vector(14 downto 0);
    
            is_valid : in boolean := false;
            is_done  : out boolean := false
        );
    end component;

    component dataset is
        port (
            clk  : in std_logic := '0';

            addr : in integer;
    
            r0 : out unsigned(63 downto 0);
            r1 : out unsigned(63 downto 0);
            r2 : out unsigned(63 downto 0);
            r3 : out unsigned(63 downto 0);
            r4 : out unsigned(63 downto 0);
            r5 : out unsigned(63 downto 0);
            r6 : out unsigned(63 downto 0);
            r7 : out unsigned(63 downto 0)
        );
    end component;

    component run is
        port (
            clk  : in  std_logic;
            reset : in  std_logic;

            hash : in std_logic_vector(511 downto 0) := (others => '0');
    
            treg : inout register_file;
            tround_mode : inout round_type := round_nearest;
    
            -- Scratchpad
            we   : out  std_logic := '0';
            addr : out integer := 0;
            din  : out unsigned(63 downto 0)  := (others => '0');
            dout : in unsigned(63 downto 0)  := (others => '0');
    
            -- Dataset
            dataset_addr : out integer := 0;
            dataset_r0   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r1   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r2   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r3   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r4   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r5   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r6   : in unsigned(63 downto 0)  := (others => '0');
            dataset_r7   : in unsigned(63 downto 0)  := (others => '0');
    
            is_valid : in boolean := false;
            is_done  : out boolean := false
        );
    end component;
    
    signal hash : std_logic_vector(511 downto 0) := x"375198c011775b86c4cc98d6e0919e63ffbe63b237ffb160fbf791cbae76509864ae6e106a7352c0347f1322f4a70bad3b9ef87d7bede5a4a2eda891266ef129";

    signal finish : boolean := false;
    signal reset : std_logic := '0';
    signal clk : std_logic := '0';
    constant clk_period : time := 1 fs;

    signal bram_we : std_logic := '1';
    signal bram_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');
    signal bram_din  : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');
    signal bram_dout : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');

    signal load_count : integer := 0;
    signal load_we : std_logic := '1';
    signal load_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');
    signal load_din  : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');

    signal we : std_logic := '0';
    signal mem_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');
    signal mem_din  : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');

    signal addr : integer := 0;
    signal din  : unsigned(63 downto 0)  := (others => '0');
    signal dout : unsigned(63 downto 0)  := (others => '0');

    signal is_ready : boolean := false;

    signal final_hash : std_logic_vector(511 downto 0);
    signal hash_is_valid : boolean := false;
    signal hash_is_done  : boolean := false;
    signal hash_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');
    signal spad : boolean := false;

    type state_type is (
        STATE_COMPILE,
        STATE_EXEC
	);
    signal state : state_type := STATE_COMPILE;

    signal reg : register_file;
    signal round_mode : round_type := round_nearest;

    signal dataset_addr : integer := 0;
    signal dataset_r0   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r1   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r2   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r3   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r4   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r5   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r6   : unsigned(63 downto 0)  := (others => '0');
    signal dataset_r7   : unsigned(63 downto 0)  := (others => '0');

    signal run_is_valid : boolean := false;
    signal run_is_done : boolean := false;

    file fin : text open read_mode is "sch.dat";
begin

    bram_we <= we when is_ready else load_we;
    bram_addr <= hash_addr when hash_is_valid else mem_addr when is_ready else load_addr;
    bram_din <= mem_din when is_ready else load_din;

    scratchpad : bram
        port map (
            clk => clk,
            we => bram_we,
            addr => bram_addr,
            din => bram_din,
            dout => bram_dout
        );

    bram_adapt512x64 : adapt512x64
        port map (
            clk => clk,
            mem_addr => mem_addr,
            mem_din => mem_din,
            mem_dout => bram_dout,
            addr => addr,
            din => din,
            dout => dout
        );

    scratchpad_hash : hashAes1Rx4
        port map (
            clk => clk,
            reset => reset,
            hash => final_hash,
            data => bram_dout,
            addr => hash_addr,
            is_valid => hash_is_valid,
            is_done => hash_is_done
        );

    dataset_comp : dataset
        port map (
            clk => clk,
            addr => dataset_addr,
            r0 => dataset_r0,
            r1 => dataset_r1,
            r2 => dataset_r2,
            r3 => dataset_r3,
            r4 => dataset_r4,
            r5 => dataset_r5,
            r6 => dataset_r6,
            r7 => dataset_r7
        );

    run_la : run
        port map (
            clk => clk,
            reset => reset,
            hash => hash,
            treg => reg,
            tround_mode => round_mode,
            we => we,
            addr => addr,
            din => din,
            dout => dout,
            dataset_addr => dataset_addr,
            dataset_r0 => dataset_r0,
            dataset_r1 => dataset_r1,
            dataset_r2 => dataset_r2,
            dataset_r3 => dataset_r3,
            dataset_r4 => dataset_r4,
            dataset_r5 => dataset_r5,
            dataset_r6 => dataset_r6,
            dataset_r7 => dataset_r7,
            is_valid => run_is_valid,
            is_done => run_is_done
        );


    load_scratchpad : process(clk)
        variable rdline : line;
        variable res : std_logic_vector(511 downto 0);
    begin
        if rising_edge(clk) and not is_ready then

            if not spad then
                spad <= true;
                report "Loading Scratchpad...";
            end if;

            if not endfile(fin) then
                readline(fin, rdline);
                hread(rdline, res);

                load_din <= res;
                load_addr <= std_logic_vector(to_unsigned(load_count, load_addr'length));

                load_count <= load_count + 1;
            else
                load_we <= '0';
                is_ready <= true;
            end if;

        end if;
    end process;


    runp : process(clk)
        variable rdline : line;
        variable t_registerUsage : registerUsage_t;
        variable t_program : instructions;
        variable ins : std_logic_vector(63 downto 0);
    begin
        if is_ready then
            if not run_is_valid then
                run_is_valid <= true;
            end if;

            if run_is_done and not hash_is_valid then
                -- Check Registers
                assert reg.r(0) = x"4faea185f1d50998" report "REG.R(0) Failed" severity FAILURE;
                assert reg.r(1) = x"84ffd47c7275e2cf" report "REG.R(1) Failed" severity FAILURE;
                assert reg.r(2) = x"f6e74cddfb6d1b35" report "REG.R(2) Failed" severity FAILURE;
                assert reg.r(3) = x"c9920419fa17bd2f" report "REG.R(3) Failed" severity FAILURE;
                assert reg.r(4) = x"7f53c2cbd3fd117f" report "REG.R(4) Failed" severity FAILURE;
                assert reg.r(5) = x"4957427314bba04a" report "REG.R(5) Failed" severity FAILURE;
                assert reg.r(6) = x"5f8cd07085f012ff" report "REG.R(6) Failed" severity FAILURE;
                assert reg.r(7) = x"5b889c58c47c119b" report "REG.R(7) Failed" severity FAILURE;

                assert reg.a(0)(0) = 31430029.802061666 report "REG.A(0)(0) Failed" severity FAILURE;
                assert reg.a(0)(1) = 7.978672918727796 report "REG.A(0)(1) Failed" severity FAILURE;
                assert reg.a(1)(0) = 58.946201627971135 report "REG.A(1)(0) Failed" severity FAILURE;
                assert reg.a(1)(1) = 211830.6867284296 report "REG.A(1)(1) Failed" severity FAILURE;
                assert reg.a(2)(0) = 1516039.8544361123 report "REG.A(2)(0) Failed" severity FAILURE;
                assert reg.a(2)(1) = 14019.284281697002 report "REG.A(2)(1) Failed" severity FAILURE;
                assert reg.a(3)(0) = 12340809.321521737 report "REG.A(3)(0) Failed" severity FAILURE;
                assert reg.a(3)(1) = 222305.79304463434 report "REG.A(3)(1) Failed" severity FAILURE;

                assert reg.e(0)(0) = 4.957799835265979e+16 report "REG.E(0)(0) Failed" severity FAILURE;
                assert reg.e(0)(1) = 150692088149572.9 report "REG.E(0)(1) Failed" severity FAILURE;
                assert reg.e(1)(0) = 1.1566588279481032e+53 report "REG.E(1)(0) Failed" severity FAILURE;
                assert reg.e(1)(1) = 4.508499750460232e-15 report "REG.E(1)(1) Failed" severity FAILURE;
                assert reg.e(2)(0) = 4.652402267219711e+42 report "REG.E(2)(0) Failed" severity FAILURE;
                assert reg.e(2)(1) = 6.421454145667884e-52 report "REG.E(2)(1) Failed" severity FAILURE;
                assert reg.e(3)(0) = 2.964539478724925e+37 report "REG.E(3)(0) Failed" severity FAILURE;
                assert reg.e(3)(1) = 3.9160589097904755e+35 report "REG.E(3)(1) Failed" severity FAILURE;
                
                assert reg.f(0)(0) = -7.376792372334384e-299 report "REG.F(0)(0) Failed" severity FAILURE;
                assert reg.f(0)(1) = -4.707374147794689e-290 report "REG.F(0)(1) Failed" severity FAILURE;
                assert reg.f(1)(0) = -1.1287317213193921e-253 report "REG.F(1)(0) Failed" severity FAILURE;
                assert reg.f(1)(1) = -1.2020873956586769e+297 report "REG.F(1)(1) Failed" severity FAILURE;
                assert reg.f(2)(0) = 1.6133452152379503e-264 report "REG.F(2)(0) Failed" severity FAILURE;
                assert reg.f(2)(1) = -4.313181139194064e+253 report "REG.F(2)(1) Failed" severity FAILURE;
                assert reg.f(3)(0) = 5.954174658403189e-278 report "REG.F(3)(0) Failed" severity FAILURE;
                assert reg.f(3)(1) = -3.1697203905832086e-277 report "REG.F(3)(1) Failed" severity FAILURE;

                -- Check Round Mode
                assert round_mode = round_nearest report "Round Mode Failed" severity FAILURE;

                report "Registers [OK]";

                hash_is_valid <= true;
            end if;
        end if;
    end process;


    hash_scratchpad : process(hash_is_done)
    begin
        if hash_is_done then
            finish <= true;

            if final_hash /= x"50b8661c84a5e99ef7a202f132fd88a2eb74b98eb8f6307c85c8a75fa7a64b38d5509b385a09d87e59ee1ab264f1ba293fdfed329321663cdd7a94d988db27d6" then
                report "Final Hash doesn't match" severity FAILURE;
            else
                report "Scratchpad Final Hash [OK]";
            end if;
        end if;
    end process;


    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;

        if finish then
            wait;
        end if;
    end process;

end test;