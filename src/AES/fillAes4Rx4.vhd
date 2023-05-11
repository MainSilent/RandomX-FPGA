-- Compile and Initialize program


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
use work.aes_core.all;
use work.common.all;
use work.compiler.all;


entity fillAes4Rx4 is
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
end fillAes4Rx4;


architecture fillAes4Rx4Arch of fillAes4Rx4 is
    type inst_holder_t is array (7 downto 0) of instruction;

    constant AES_GEN_4R_KEY0 : std_logic_vector(127 downto 0) := x"99e5d23f2f546d2bd1833ddb6421aadd";
    constant AES_GEN_4R_KEY1 : std_logic_vector(127 downto 0) := x"a5dfcde506f79d53b6913f55b20e3450";
    constant AES_GEN_4R_KEY2 : std_logic_vector(127 downto 0) := x"171c02bf0aa4679f515e7baf5c3ed904";
    constant AES_GEN_4R_KEY3 : std_logic_vector(127 downto 0) := x"d8ded291cd673785e78f5d0885623763";
    constant AES_GEN_4R_KEY4 : std_logic_vector(127 downto 0) := x"229effb43d518b6de3d6a7a6b5826f73";
    constant AES_GEN_4R_KEY5 : std_logic_vector(127 downto 0) := x"b272b7d2e9024d4e9c10b3d9c7566bf3";
    constant AES_GEN_4R_KEY6 : std_logic_vector(127 downto 0) := x"f63befa72ba9660af765a38bf273c9e7";
    constant AES_GEN_4R_KEY7 : std_logic_vector(127 downto 0) := x"c0b0762d0c06d1fd915839de7a7cd609";

    constant count : integer := 33;
    constant regZio : std_logic_vector(63 downto 0) := x"0000000000000001";

    signal ptr : integer := 0;
    signal registerUsage : registerUsage_t := (others => -1);
    signal state : std_logic_vector(511 downto 0) := hash;
begin
    
    process(clk, reset)
        variable inst_holder : inst_holder_t;
        variable t_registerUsage : registerUsage_t;
        variable t_state : std_logic_vector(511 downto 0) := (others => '0');
        variable addressRegisters : std_logic_vector(63 downto 0) := (others => '0');
    begin
        if reset = '1' then
            ptr <= 0;
            state <= hash;
            registerUsage <= (others => -1);
            is_done <= false;

        elsif rising_edge(clk) and is_valid and not is_done then
            t_state := state;

            t_state(127 downto 0) := aesdec(AES_GEN_4R_KEY0, t_state(127 downto 0));
            t_state(255 downto 128) := aesenc(AES_GEN_4R_KEY0, t_state(255 downto 128));
            t_state(383 downto 256) := aesdec(AES_GEN_4R_KEY4, t_state(383 downto 256));
            t_state(511 downto 384) := aesenc(AES_GEN_4R_KEY4, t_state(511 downto 384));

            t_state(127 downto 0) := aesdec(AES_GEN_4R_KEY1, t_state(127 downto 0));
            t_state(255 downto 128) := aesenc(AES_GEN_4R_KEY1, t_state(255 downto 128));
            t_state(383 downto 256) := aesdec(AES_GEN_4R_KEY5, t_state(383 downto 256));
            t_state(511 downto 384) := aesenc(AES_GEN_4R_KEY5, t_state(511 downto 384));

            t_state(127 downto 0) := aesdec(AES_GEN_4R_KEY2, t_state(127 downto 0));
            t_state(255 downto 128) := aesenc(AES_GEN_4R_KEY2, t_state(255 downto 128));
            t_state(383 downto 256) := aesdec(AES_GEN_4R_KEY6, t_state(383 downto 256));
            t_state(511 downto 384) := aesenc(AES_GEN_4R_KEY6, t_state(511 downto 384));

            t_state(127 downto 0) := aesdec(AES_GEN_4R_KEY3, t_state(127 downto 0));
            t_state(255 downto 128) := aesenc(AES_GEN_4R_KEY3, t_state(255 downto 128));
            t_state(383 downto 256) := aesdec(AES_GEN_4R_KEY7, t_state(383 downto 256));
            t_state(511 downto 384) := aesenc(AES_GEN_4R_KEY7, t_state(511 downto 384));

            state <= t_state;


            if ptr = 0 then
                reg_a(0)(0) <= getSmallPositiveFloatBits(t_state(63 downto 0));
                reg_a(0)(1) <= getSmallPositiveFloatBits(t_state(127 downto 64));
                reg_a(1)(0) <= getSmallPositiveFloatBits(t_state(191 downto 128));
                reg_a(1)(1) <= getSmallPositiveFloatBits(t_state(255 downto 192));
                reg_a(2)(0) <= getSmallPositiveFloatBits(t_state(319 downto 256));
                reg_a(2)(1) <= getSmallPositiveFloatBits(t_state(383 downto 320));
                reg_a(3)(0) <= getSmallPositiveFloatBits(t_state(447 downto 384));
                reg_a(3)(1) <= getSmallPositiveFloatBits(t_state(511 downto 448));

            elsif ptr = 1 then
                ma <= t_state(31 downto 0) and CacheLineAlignMask;
                mx <= t_state(159 downto 128);

                addressRegisters := t_state(319 downto 256);
                readReg(0) <= to_integer(unsigned(addressRegisters and regZio));
                addressRegisters := addressRegisters srl 1;
                readReg(1) <= 2 + to_integer(unsigned(addressRegisters and regZio));
                addressRegisters := addressRegisters srl 1;
                readReg(2) <= 4 + to_integer(unsigned(addressRegisters and regZio));
                addressRegisters := addressRegisters srl 1;
                readReg(3) <= 6 + to_integer(unsigned(addressRegisters and regZio));

                datasetOffset <= to_integer(unsigned(t_state(383 downto 320)) mod (DatasetExtraItems + 1)) * CacheLineSize;

                eMask(0) <= to_float(getFloatMask(t_state(447 downto 384)), FLOAT_EXP, FLOAT_FRAC);
                eMask(1) <= to_float(getFloatMask(t_state(511 downto 448)), FLOAT_EXP, FLOAT_FRAC);

            else
                t_registerUsage := registerUsage;

                compile((ptr-2)*8, t_state(63 downto 0), t_registerUsage, inst_holder(0));
                compile(((ptr-2)*8)+1, t_state(127 downto 64), t_registerUsage, inst_holder(1));
                compile(((ptr-2)*8)+2, t_state(191 downto 128), t_registerUsage, inst_holder(2));
                compile(((ptr-2)*8)+3, t_state(255 downto 192), t_registerUsage, inst_holder(3));
                compile(((ptr-2)*8)+4, t_state(319 downto 256), t_registerUsage, inst_holder(4));
                compile(((ptr-2)*8)+5, t_state(383 downto 320), t_registerUsage, inst_holder(5));
                compile(((ptr-2)*8)+6, t_state(447 downto 384), t_registerUsage, inst_holder(6));
                compile(((ptr-2)*8)+7, t_state(511 downto 448), t_registerUsage, inst_holder(7));

                program(((ptr-2)*8)) <= inst_holder(0);
                program(((ptr-2)*8)+1) <= inst_holder(1);
                program(((ptr-2)*8)+2) <= inst_holder(2);
                program(((ptr-2)*8)+3) <= inst_holder(3);
                program(((ptr-2)*8)+4) <= inst_holder(4);
                program(((ptr-2)*8)+5) <= inst_holder(5);
                program(((ptr-2)*8)+6) <= inst_holder(6);
                program(((ptr-2)*8)+7) <= inst_holder(7);

                registerUsage <= t_registerUsage;
            end if;


            if ptr < count then
                ptr <= ptr + 1;
            else
                is_done <= true;
            end if;

            report integer'image(ptr) & "/" & integer'image(count);
        end if;
    end process;

end fillAes4Rx4Arch;