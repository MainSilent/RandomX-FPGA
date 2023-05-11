library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;


package common is

    constant FLOAT_EXP : integer := 11;
    constant FLOAT_FRAC : integer := 52;

    constant EightByte : unsigned(63 downto 0) := (others => '1');
    constant SCRATCHPAD_SIZE : integer := 16777215;
    constant RANDOMX_PROGRAM_SIZE : integer := 256;
    -- constant mantissaSize : integer := 52;
    -- constant exponentBias : integer := 1023;
    -- constant mantissaMask : integer := 4503599627370495;
    -- constant exponentMask : integer := 2047;
    -- constant RANDOMX_JUMP_BITS : integer := 8;
    constant RANDOMX_JUMP_OFFSET : integer := 8;
    -- constant RANDOMX_DATASET_BASE_SIZE : integer  := 2147483648;
    -- constant RANDOMX_DATASET_EXTRA_SIZE : integer := 33554368;
    -- constant RANDOMX_DATASET_ITEM_SIZE : integer := 64;
    constant RANDOMX_SCRATCHPAD_L3 : integer := 2097152;
    constant RANDOMX_SCRATCHPAD_L2 : integer := 262144;
    constant RANDOMX_SCRATCHPAD_L1 : integer := 16384;
    -- constant RANDOMX_PROGRAM_COUNT : integer := 7;
    constant RANDOMX_PROGRAM_ITERATIONS : integer := 2048;
    -- constant ScratchpadSize : integer := RANDOMX_SCRATCHPAD_L3;
    constant CacheLineSize : integer := 64;
    constant CacheLineAlignMask : std_logic_vector(31 downto 0) := x"7fffffc0";
    constant DatasetExtraItems : integer := 524287;
    constant RegistersCount : integer := 8;
    constant RegisterCountFlt : integer := 4;
    
    constant ScratchpadL1 : integer := RANDOMX_SCRATCHPAD_L1 / 8;
    constant ScratchpadL2 : integer := RANDOMX_SCRATCHPAD_L2 / 8;
    constant ScratchpadL3 : integer := RANDOMX_SCRATCHPAD_L3 / 8;
    constant ScratchpadL1Mask : integer := (ScratchpadL1 - 1) * 8;
    constant ScratchpadL2Mask : integer := (ScratchpadL2 - 1) * 8;
    constant ScratchpadL1Mask16 : integer := (ScratchpadL1 / 2 - 1) * 16;
    constant ScratchpadL2Mask16 : integer := (ScratchpadL2 / 2 - 1) * 16;
    constant ScratchpadL3Mask : integer := (ScratchpadL3 - 1) * 8;
    constant ScratchpadL3Mask64 : std_logic_vector := std_logic_vector(to_unsigned((ScratchpadL3 / 8 - 1) * 64, 32));
    constant RegisterNeedsDisplacement : integer := 5;
    -- constant RegisterNeedsSib : integer := 4;
    constant StoreL3Condition : integer := 14;
    -- constant dynamicExponentBits : integer := 4;
    constant ConditionOffset : integer := RANDOMX_JUMP_OFFSET;
    constant ConditionMask : integer := 255;
    constant dynamicMantissaMask : float64 :=  to_float(7.291122019556397e-304, FLOAT_EXP, FLOAT_FRAC);


    type instruction_type is (
        IADD_RS,
		IADD_M,
		ISUB_R,
		ISUB_M,
		IMUL_R,
		IMUL_M,
		IMULH_R,
		IMULH_M,
		ISMULH_R,
		ISMULH_M,
		IMUL_RCP,
		INEG_R,
		IXOR_R,
		IXOR_M,
		IROR_R,
		IROL_R,
		ISWAP_R,
		FSWAP_R,
		FADD_R,
		FADD_M,
		FSUB_R,
		FSUB_M,
		FSCAL_R,
		FMUL_R,
		FDIV_M,
		FSQRT_R,
		CBRANCH,
		CFROUND,
		ISTORE,
		NOP
    );

    type instruction is
    record
        op: instruction_type;

        memMask: integer;

        src: integer;
        dst: integer;

        shift: integer;
        target: integer;
        imm: unsigned(63 downto 0);
    end record;

    type regt_r is array (7 downto 0) of unsigned(63 downto 0);
    type regt_float is array (1 downto 0) of float64;
    type regt_f is array (3 downto 0) of regt_float;
    type regt_e is array (3 downto 0) of regt_float;
    type regt_a is array (3 downto 0) of regt_float;

    type register_file is
    record
        r: regt_r;
        f: regt_f;
        e: regt_e;
        a: regt_a;
    end record;

    type instructions is array (RANDOMX_PROGRAM_SIZE-1 downto 0) of instruction;

	type readReg_t is array (3 downto 0) of integer range 0 to 8;

	type registerUsage_t is array (RegistersCount-1 downto 0) of integer range -1 to 256;

    function reciprocal (divisor : in unsigned(63 downto 0))
        return std_logic_vector;

    function maskRegisterExponentMantissa (
        pad : unsigned(31 downto 0);
        eMask : float64
    )
        return float64;

	function getSmallPositiveFloatBits (
        data : std_logic_vector(63 downto 0)
    )
        return float64;

    function getScratchpadAddress (
        imm : unsigned(63 downto 0);
        src : unsigned(63 downto 0);
        memMask : integer
    )
        return integer;

    function getFloatMask (
        data : std_logic_vector(63 downto 0)
    )
        return std_logic_vector;

    function getModMem (val : in std_logic_vector)
        return integer;

    function getModShift (val : in std_logic_vector)
        return integer;

    function getModCond (val : in std_logic_vector)
        return integer;

    function con_u64 (data : unsigned(31 downto 0))
        return unsigned;

    function c_float (data : real)
        return float64;

    function si_float (data : unsigned)
        return float64;

    function to_int (val : in std_logic_vector)
        return integer;

    ---------------------------- mulh ----------------------------
    function LO (data : unsigned(63 downto 0)) return unsigned;

    function HI (data : unsigned(63 downto 0)) return unsigned;

    function mulh (
        src : unsigned(63 downto 0);
        dst : unsigned(63 downto 0)
    ) return unsigned;

    function smulh (
        src : unsigned(63 downto 0);
        dst : unsigned(63 downto 0)
    ) return unsigned;

end package;


package body common is

    function reciprocal (divisor : in unsigned(63 downto 0))
    return std_logic_vector is 
        constant p2exp63 : unsigned(63 downto 0) := "1000000000000000000000000000000000000000000000000000000000000000";
        variable bsr : integer := 0;
        variable shift : integer := 0;
        variable bit_tmp : unsigned(63 downto 0);
        variable quotient : unsigned(63 downto 0);
        variable remainder : unsigned(63 downto 0);
    begin
        quotient := p2exp63 / divisor;
        remainder := p2exp63 mod divisor;

        bit_tmp := divisor;
        for i in 1 to 32 loop
            if bit_tmp > 0 then
                bsr := bsr + 1;
                bit_tmp := bit_tmp srl 1;
            end if;
        end loop;

        for i in 1 to 32 loop
            if shift < bsr then
                if remainder >= (divisor - remainder) then
                    quotient := resize(quotient * 2 + 1, 64);
                    remainder := resize(remainder * 2 - divisor, 64);
                else
                    quotient := resize(quotient * 2, 64);
                    remainder := resize(remainder * 2, 64);
                end if;
    
                shift := shift + 1;
            end if;
        end loop;

        return std_logic_vector(quotient);
    end;


    function maskRegisterExponentMantissa (
        pad : unsigned(31 downto 0);
        eMask : float64
    )
    return float64 is
        variable t : float64;
    begin
        t := to_float(signed(pad), FLOAT_EXP, FLOAT_FRAC);
        t := t and dynamicMantissaMask;
        t := t or eMask;

        return t;
    end;
    

    function getSmallPositiveFloatBits (
        data : std_logic_vector(63 downto 0)
    )
    return float64 is 
        variable output : float64;
        variable exponent : std_logic_vector(63 downto 0);
        variable mantissa : std_logic_vector(63 downto 0);
        constant mantissaMask : std_logic_vector(63 downto 0) := x"000fffffffffffff";
        constant exponentMask : std_logic_vector(63 downto 0) := x"00000000000007ff";
    begin
        exponent := data srl 59;
        mantissa := data and mantissaMask;
        exponent := std_logic_vector(unsigned(exponent) + x"000003ff");
        exponent := exponent and exponentMask;
        exponent := exponent sll 52;

        output := to_float(exponent or mantissa, FLOAT_EXP, FLOAT_FRAC);

        return output;
    end;


    function getScratchpadAddress (
        imm : unsigned(63 downto 0);
        src : unsigned(63 downto 0);
        memMask : integer
    )
    return integer is 
        variable output : integer;
    begin
        output := to_integer((src + imm) and to_unsigned(memMask, imm'length));

        return output / 8;
    end;


    function getFloatMask (
        data : std_logic_vector(63 downto 0)
    )
    return std_logic_vector is 
        variable output : std_logic_vector(63 downto 0);
        variable cool : std_logic_vector(63 downto 0);
        variable exponent : std_logic_vector(63 downto 0);
        variable mask22bit : std_logic_vector(63 downto 0) := x"00000000003fffff";
    begin
        cool := data and mask22bit;
        exponent := x"0000000000000300";
        exponent := exponent or (data srl 60) sll 4;
        exponent := exponent sll 52;

        output := cool or exponent;

        return output;
    end;


    function getModMem (val : in std_logic_vector)
    return integer is 
        variable output : integer;
    begin
        output := to_integer(unsigned(val(1 downto 0)));
        return output;
    end;


    function getModShift (val : in std_logic_vector)
    return integer is 
        variable output : integer;
    begin
        output := to_integer(unsigned(val(3 downto 2)));
        return output;
    end;


    function getModCond (val : in std_logic_vector)
    return integer is 
        variable output : integer;
    begin
        output := to_integer(unsigned(val(7 downto 4)));
        return output;
    end;


    function con_u64(data : unsigned(31 downto 0))
    return unsigned is
        variable output : unsigned(63 downto 0) := (others => '0');
    begin
        if data > x"7fffffff" then
            output(31 downto 0) := data;
            output := output or x"ffffffff00000000";
        else
            output(31 downto 0) := data;
        end if;

        return output;
    end;


    function c_float(data : real)
    return float64 is
    begin
        return to_float(data, FLOAT_EXP, FLOAT_FRAC);
    end;


    function si_float(data : unsigned)
    return float64 is
    begin
        return to_float(to_integer(signed(data)), FLOAT_EXP, FLOAT_FRAC);
    end;


    function to_int (val : in std_logic_vector)
    return integer is 
        variable output : integer;
    begin
        output := to_integer(unsigned(val));
        return output;
    end;


    ---------------------------- mulh ----------------------------
    function LO (data : unsigned(63 downto 0))
    return unsigned is 
        variable output : unsigned(63 downto 0);
    begin
        output := data and x"00000000ffffffff";

        return output;
    end;


    function HI (data : unsigned(63 downto 0))
    return unsigned is 
        variable output : unsigned(63 downto 0);
    begin
        output := data srl 32;

        return output;
    end;


    function mulh (
        src : unsigned(63 downto 0);
        dst : unsigned(63 downto 0)
    )
    return unsigned is 
        variable ah : unsigned(63 downto 0);
        variable al : unsigned(63 downto 0);
        variable bh : unsigned(63 downto 0);
        variable bl : unsigned(63 downto 0);
        variable x00 : unsigned(63 downto 0);
        variable x01 : unsigned(63 downto 0);
        variable x10 : unsigned(63 downto 0);
        variable x11 : unsigned(63 downto 0);
        variable m1 : unsigned(63 downto 0);
        variable m2 : unsigned(63 downto 0);
        variable m3 : unsigned(63 downto 0);
    begin
        ah := HI(src);
        al := LO(src);
        bh := HI(dst);
        bl := LO(dst);

        x00 := resize(al * bl, 64);
        x01 := resize(al * bh, 64);
        x10 := resize(ah * bl, 64);
        x11 := resize(ah * bh, 64);

        m1 := resize(LO(x10) + LO(x01) + HI(x00), 64);
        m2 := resize(HI(x10) + HI(x01) + LO(x11) + HI(m1), 64);
        m3 := resize(HI(x11) + HI(m2), 64);

        return resize((m3 sll 32) + LO(m2), 64);
    end;


    function smulh (
        src : unsigned(63 downto 0);
        dst : unsigned(63 downto 0)
    )
    return unsigned is 
        variable output : unsigned(63 downto 0);
    begin
        output := resize(unsigned(signed(src) * signed(dst)) srl 64, 64);

        return output;
    end;

end common;