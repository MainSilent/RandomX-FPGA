library ieee;
library std;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.float_pkg.all;
use work.common.all;
use work.cc_opcode.all;
use work.cc_regn.all;
use work.cc_other.all;


entity tb_compile is
end tb_compile;


architecture test of tb_compile is

    component fillAes4Rx4 is
        port (
            clk      : in  std_logic;
            reset    : in  std_logic;

            hash           : in std_logic_vector(511 downto 0) := (others => '0');
            reg_a          : out regt_a;
            eMask          : out regt_float;
            readReg        : out readReg_t;
            program        : out instructions;
            datasetOffset  : out integer;
            ma             : out std_logic_vector(31 downto 0) := (others => '0');
            mx             : out std_logic_vector(31 downto 0) := (others => '0');

            is_valid : in boolean := false;
            is_done  : out boolean := false
        );
	end component;

    signal finish : boolean := false;
    signal reset : std_logic := '1';
    signal clk : std_logic := '0';
    constant clk_period : time := 1 fs;

    signal comp_is_valid : boolean := false;
    signal comp_is_done  : boolean := false;

    signal reg_a : regt_a;
    signal eMask : regt_float;
    signal readReg : readReg_t;
    signal program : instructions;
    signal datasetOffset : integer;
    signal ma, mx : std_logic_vector(31 downto 0) := (others => '0');

    signal hash : std_logic_vector(511 downto 0) := x"375198c011775b86c4cc98d6e0919e63ffbe63b237ffb160fbf791cbae76509864ae6e106a7352c0347f1322f4a70bad3b9ef87d7bede5a4a2eda891266ef129";
begin

    compile : fillAes4Rx4
        port map (
            clk => clk,
            reset => reset,
            hash => hash,
            reg_a => reg_a,
            eMask => eMask,
            readReg => readReg,
            program => program,
            datasetOffset => datasetOffset,
            ma => ma,
            mx => mx,
            is_valid => comp_is_valid,
            is_done => comp_is_done
        );


    init : process(clk)
    begin
        if not comp_is_valid then
            reset <= '0';
            comp_is_valid <= true;
        end if;

        if comp_is_done and not finish then
            assert reg_a(0)(0) = 31430029.802061666 report "reg.a(0)(0) Failed" severity FAILURE;
            assert reg_a(0)(1) = 7.978672918727796 report "reg.a(0)(1) Failed" severity FAILURE;
            assert reg_a(1)(0) = 58.946201627971135 report "reg.a(1)(0) Failed" severity FAILURE;
            assert reg_a(1)(1) = 211830.6867284296 report "reg.a(1)(1) Failed" severity FAILURE;
            assert reg_a(2)(0) = 1516039.854436112 report "reg.a(2)(0) Failed" severity FAILURE;
            assert reg_a(2)(1) = 14019.284281697002 report "reg.a(2)(1) Failed" severity FAILURE;
            assert reg_a(3)(0) = 12340809.321521737 report "reg.a(3)(0) Failed" severity FAILURE;
            assert reg_a(3)(1) = 222305.79304463434 report "reg.a(3)(1) Failed" severity FAILURE;

            assert ma = x"53c5b600" report "ma Failed" severity FAILURE;
            assert mx = x"fa78ebcb" report "mx Failed" severity FAILURE;

            assert readReg(0) = 0 report "readReg(0) Failed" severity FAILURE;
            assert readReg(1) = 3 report "readReg(1) Failed" severity FAILURE;
            assert readReg(2) = 5 report "readReg(2) Failed" severity FAILURE;
            assert readReg(3) = 6 report "readReg(3) Failed" severity FAILURE;

            assert datasetOffset = 25697344 report "datasetOffset Failed" severity FAILURE;

            assert eMask(0) = 1.7272337119812983e-77 report "eMask(0) Failed" severity FAILURE;
            assert eMask(1) = 3.051757813443954e-05 report "eMask(1) Failed" severity FAILURE;


            -------------------------- Check OpCode --------------------------
            opcode_check(program);

            -------------------------- Check Register Number --------------------------
            regn_check(program);

            -------------------------- Check Shift --------------------------
            shift_check(program);

            -------------------------- Check Target --------------------------
            target_check(program);

            -------------------------- Check memMask --------------------------
            mask_check(program);

            -------------------------- Check memMask --------------------------
            imm_check(program);

            finish <= true;
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