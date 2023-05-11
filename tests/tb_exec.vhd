library ieee;
library std;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use work.common.all;
use work.compiler.all;


entity tb_exec is
end tb_exec;


architecture test of tb_exec is

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

    component execute is
        port(
            clk  : in  std_logic;
            reset : in  std_logic;
    
            we   : out  std_logic;
            addr : out integer := 0;
            din  : out unsigned(63 downto 0)  := (others => '0');
            dout : in unsigned(63 downto 0)  := (others => '0');
    
            eMask : in regt_float;
            program : in instructions;
            treg : in register_file;
            tround_mode : in round_type := round_nearest;

            out_reg : out register_file;
            out_round_mode : out round_type;
    
            is_valid : in boolean := false;
            is_done  : out boolean := false
        );
    end component;
    

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

    constant dm_reg_r : regt_r := (
        x"90aa2c4ae1d8f3e9",
        x"6452754188ca2a20",
        x"538eb885e2c1bb95",
        x"df42885314caa186",
        x"5a7bc3f257c8ffeb",
        x"b54b9f5a4df778e7",
        x"9553c0127b9d86e5",
        x"acccea1a4506d89b"
    );
    constant dm_reg_f : regt_f := (
        (c_float(-103741411.0), c_float(1295936336.0)),
        (c_float(365347374.0), c_float(-1607407057.0)), 
        (c_float(1699794988.0), c_float(-1924801852.0)),
        (c_float(1001006115.0), c_float(1493110116.0))
    );
    constant dm_reg_e : regt_e := (
        (c_float(0.2715236321864939), c_float(3.4026533635081425e-74)),
        (c_float(0.49607190148255886), c_float(2.7361304676484144e-73)),
        (c_float(0.1834349823570955), c_float(2.2637307707610225e-73)),
        (c_float(0.29586068478695216), c_float(2.6757709433315063e-73))
    );
    constant dm_reg_a : regt_a := (
        (c_float(222305.79304463434), c_float(12340809.321521737)),
        (c_float(14019.284281697002), c_float(1516039.854436112)),
        (c_float(211830.6867284296), c_float(58.946201627971135)),
        (c_float(7.978672918727796), c_float(31430029.802061666))
    );

    signal reg : register_file := (dm_reg_r, dm_reg_f, dm_reg_e, dm_reg_a);
    signal program : instructions;
    signal round_mode : round_type := round_nearest;
    signal eMask : regt_float := (
        to_float(3.051757813443954e-05, 11, 52),
        to_float(1.7272337119812983e-77, 11, 52)
    );

    signal ex_reg : register_file;
    signal ex_round_mode : round_type;

    signal exec_is_valid : boolean := false;
    signal exec_is_done : boolean := false;

    file fin : text open read_mode is "sch.dat";
    file pin : text open read_mode is "program.dat";
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

    execute_com : execute
        port map (
            clk => clk,
            reset => reset,
            we => we,
            addr => addr,
            din => din,
            dout => dout,
            eMask => eMask,
            program => program,
            treg => reg,
            tround_mode => round_mode,
            out_reg => ex_reg,
            out_round_mode => ex_round_mode,
            is_valid => exec_is_valid,
            is_done => exec_is_done
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


    executep : process(clk)
        variable rdline : line;
        variable t_registerUsage : registerUsage_t;
        variable t_program : instructions;
        variable ins : std_logic_vector(63 downto 0);
    begin
        if is_ready then
            if state = STATE_COMPILE then
                state <= STATE_EXEC;

                for i in 0 to 255 loop
                    readline(pin, rdline);
                    hread(rdline, ins);

                    compile(i, ins, t_registerUsage, t_program(i));
                end loop;

                program <= t_program;
            end if;

            if state = STATE_EXEC then
                if not exec_is_valid then
                    exec_is_valid <= true;
                end if;

                if exec_is_done and not hash_is_valid then
                    -- Check Registers
                    assert ex_reg.r(0) = x"effac1a54549ce00" report "REG.R(0) Failed" severity FAILURE;
                    assert ex_reg.r(1) = x"a8e165f886397691" report "REG.R(1) Failed" severity FAILURE;
                    assert ex_reg.r(2) = x"b4a0cf675915a10c" report "REG.R(2) Failed" severity FAILURE;
                    assert ex_reg.r(3) = x"c2d906fe93dca707" report "REG.R(3) Failed" severity FAILURE;
                    assert ex_reg.r(4) = x"badc892bc565b600" report "REG.R(4) Failed" severity FAILURE;
                    assert ex_reg.r(5) = x"1f562fff6688b806" report "REG.R(5) Failed" severity FAILURE;
                    assert ex_reg.r(6) = x"3acd676097b2ddce" report "REG.R(6) Failed" severity FAILURE;
                    assert ex_reg.r(7) = x"bd03c560d68b27f8" report "REG.R(7) Failed" severity FAILURE;

                    assert ex_reg.e(0)(0) = 3.347315821957958e+17 report "REG.E(0)(0) Failed" severity FAILURE;
                    assert ex_reg.e(0)(1) = 651134751457078.9 report "REG.E(0)(1) Failed" severity FAILURE;
                    assert ex_reg.e(1)(0) = 1.1122516114228345e+53 report "REG.E(1)(0) Failed" severity FAILURE;
                    assert ex_reg.e(1)(1) = 4.6743973781881254e-15 report "REG.E(1)(1) Failed" severity FAILURE;
                    assert ex_reg.e(2)(0) = 2.575133276912482e+43 report "REG.E(2)(0) Failed" severity FAILURE;
                    assert ex_reg.e(2)(1) = 1.2862344178204426e-51 report "REG.E(2)(1) Failed" severity FAILURE;
                    assert ex_reg.e(3)(0) = 1.8511829782174654e+37 report "REG.E(3)(0) Failed" severity FAILURE;
                    assert ex_reg.e(3)(1) = 3.0340629896686587e+35 report "REG.E(3)(1) Failed" severity FAILURE;
                    
                    assert ex_reg.f(0)(0) = -14318327.146655116 report "REG.F(0)(0) Failed" severity FAILURE;
                    assert ex_reg.f(0)(1) = -945446.1424747697 report "REG.F(0)(1) Failed" severity FAILURE;
                    assert ex_reg.f(1)(0) = -27514481.09270586 report "REG.F(1)(0) Failed" severity FAILURE;
                    assert ex_reg.f(1)(1) = 2427952.0910133827 report "REG.F(1)(1) Failed" severity FAILURE;
                    assert ex_reg.f(2)(0) = 725939436.1081715 report "REG.F(2)(0) Failed" severity FAILURE;
                    assert ex_reg.f(2)(1) = -690708112.554101 report "REG.F(2)(1) Failed" severity FAILURE;
                    assert ex_reg.f(3)(0) = -2713151482.266226 report "REG.F(3)(0) Failed" severity FAILURE;
                    assert ex_reg.f(3)(1) = 2712600594.932393 report "REG.F(3)(1) Failed" severity FAILURE;

                    -- Check Round Mode
                    assert ex_round_mode = round_zero report "Round Mode Failed" severity FAILURE;

                    report "Registers [OK]";

                    hash_is_valid <= true;
                end if;
            end if;
        end if;
    end process;


    hash_scratchpad : process(hash_is_done)
    begin
        if hash_is_done then
            finish <= true;

            if final_hash /= x"4b1c37395885fe3b41943f46d62c0bda71307a177178b74eff1da37b569ee2205f2c4df85b39e07a09aaf08a58f57bb1c77f7d83c9a16abbe3286d863408e9fe" then
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