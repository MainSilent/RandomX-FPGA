library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


package compiler is

    procedure compile(
        constant i : integer;
        variable hash : std_logic_vector(63 downto 0);
        variable registerUsage : out registerUsage_t;
        variable inst : out instruction
    );

end package;


package body compiler is

    procedure compile(
        constant i : integer;
        variable hash : std_logic_vector(63 downto 0);
        variable registerUsage : out registerUsage_t;
        variable inst : out instruction
    ) is
        variable opcode : std_logic_vector(7 downto 0);
        variable mode : std_logic_vector(7 downto 0);
        variable imm : unsigned(63 downto 0);
        variable src : integer;
        variable dst : integer range 0 to 8;
        variable memMask : integer;
        variable shift: integer;
    begin
        opcode := hash(7 downto 0);
        dst := to_int(hash(15 downto 8)) mod RegistersCount;
        src := to_int(hash(23 downto 16)) mod RegistersCount;
        mode := hash(31 downto 24);
        inst.src := src;
        inst.dst := dst;
        imm := con_u64(unsigned((hash(63 downto 32))));

        
        if opcode < x"10" then -- IADD_RS
            registerUsage(dst) := i;

            if dst /= RegisterNeedsDisplacement then
                imm := (others => '0');
            end if;

            inst.op := IADD_RS;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.shift := getModShift(mode);


        elsif opcode < x"17" then -- IADD_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := IADD_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"27" then -- ISUB_R
            registerUsage(dst) := i;

            if src = dst then
                inst.imm := imm;
                inst.src := -1;
            else
                inst.src := src;
            end if;

            inst.op := ISUB_R;
            inst.dst := dst;


        elsif opcode < x"2e" then -- ISUB_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := ISUB_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"3e" then -- IMUL_R
            registerUsage(dst) := i;

            if src = dst then
                inst.imm := imm;
                inst.src := -1;
            else
                inst.src := src;
            end if;

            inst.op := IMUL_R;
            inst.dst := dst;


        elsif opcode < x"42" then -- IMUL_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := IMUL_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"46" then -- IMULH_R
            registerUsage(dst) := i;

            inst.op := IMULH_R;
            inst.src := src;
            inst.dst := dst;


        elsif opcode < x"47" then -- IMULH_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := IMULH_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"4b" then -- ISMULH_R
            registerUsage(dst) := i;

            inst.op := ISMULH_R;
            inst.src := src;
            inst.dst := dst;


        elsif opcode < x"4c" then -- ISMULH_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := ISMULH_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"54" then -- IMUL_RCP
            if not ((imm(31 downto 0) and imm(31 downto 0) - 1) = 0) then
                imm := unsigned(reciprocal(resize(unsigned(imm(31 downto 0)), 64)));
                registerUsage(dst) := i;

                inst.op := IMUL_RCP;
                inst.src := -1;
                inst.dst := dst;
                inst.imm := imm;
            else
                inst.op := NOP;
            end if;


        elsif opcode < x"56" then -- INEG_R
            registerUsage(dst) := i;

            inst.op := INEG_R;
            inst.dst := dst;


        elsif opcode < x"65" then -- IXOR_R
            registerUsage(dst) := i;

            if src = dst then
                inst.imm := imm;
                inst.src := -1;
            else
                inst.src := src;
            end if;

            inst.op := IXOR_R;
            inst.dst := dst;


        elsif opcode < x"6a" then -- IXOR_M
            registerUsage(dst) := i;

            if (src /= dst) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                src := -1;
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := IXOR_M;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"72" then -- IROR_R
            registerUsage(dst) := i;

            if src = dst then
                inst.imm := imm;
                inst.src := -1;
            else
                inst.src := src;
            end if;

            inst.op := IROR_R;
            inst.dst := dst;
            inst.imm := imm;


        elsif opcode < x"74" then -- IROL_R
            registerUsage(dst) := i;

            if src = dst then
                inst.imm := imm;
                inst.src := -1;
            else
                inst.src := src;
            end if;

            inst.op := IROL_R;
            inst.dst := dst;
            inst.imm := imm;


        elsif opcode < x"78" then -- ISWAP_R
            if (src /= dst) then
                registerUsage(src) := i;
                registerUsage(dst) := i;

                inst.op := ISWAP_R;
                inst.src := src;
                inst.dst := dst;
            else
                inst.op := NOP;
            end if;


        elsif opcode < x"7c" then -- FSWAP_R
            if (dst < RegisterCountFlt) then  
                -- F
                inst.dst := dst + 6;
            else
                -- E
                inst.dst := dst - RegisterCountFlt;
            end if;
    
            inst.op := FSWAP_R;


        elsif opcode < x"8c" then -- FADD_R
            inst.op := FADD_R;
            inst.src := src mod RegisterCountFlt;
            inst.dst := dst mod RegisterCountFlt;
            

        elsif opcode < x"91" then -- FADD_M
            if getModMem(mode) /= 0 then
                memMask := ScratchpadL1Mask;
            else
                memMask := ScratchpadL2Mask;
            end if;

            inst.op := FADD_M;
            inst.src := src;
            inst.dst := dst mod RegisterCountFlt;
            inst.imm := imm;
            inst.memMask := memMask;
        

        elsif opcode < x"a1" then -- FSUB_R
            inst.op := FSUB_R;
            inst.src := src mod RegisterCountFlt;
            inst.dst := dst mod RegisterCountFlt;
        
        
        elsif opcode < x"a6" then -- FSUB_M
            if getModMem(mode) /= 0 then
                memMask := ScratchpadL1Mask;
            else
                memMask := ScratchpadL2Mask;
            end if;

            inst.op := FSUB_M;
            inst.src := src;
            inst.dst := dst mod RegisterCountFlt;
            inst.imm := imm;
            inst.memMask := memMask;
        

        elsif opcode < x"ac" then -- FSCAL_R
            inst.op := FSCAL_R;
            inst.dst := dst mod RegisterCountFlt;
        

        elsif opcode < x"cc" then -- FMUL_R
            inst.op := FMUL_R;
            inst.src := src mod RegisterCountFlt;
            inst.dst := dst mod RegisterCountFlt;
        

        elsif opcode < x"d0" then -- FDIV_M
            if getModMem(mode) /= 0 then
                memMask := ScratchpadL1Mask;
            else
                memMask := ScratchpadL2Mask;
            end if;

            inst.op := FDIV_M;
            inst.src := src;
            inst.dst := dst mod RegisterCountFlt;
            inst.imm := imm;
            inst.memMask := memMask;
        

        elsif opcode < x"d6" then -- FSQRT_R
            inst.op := FSQRT_R;
            inst.dst := dst mod RegisterCountFlt;
        

        elsif opcode < x"ef" then -- CBRANCH
            inst.target := registerUsage(dst);
            shift := getModCond(mode) + ConditionOffset;
            imm(31 downto 0) := imm(31 downto 0) or unsigned(std_logic_vector(to_unsigned(1, 32) sll shift));
            imm(31 downto 0) := imm(31 downto 0) and unsigned(std_logic_vector(not (to_unsigned(1, 32) sll (shift - 1))));
            memMask := to_integer(to_unsigned(ConditionMask, 32) sll shift);

            for j in 0 to RegistersCount-1 loop
                registerUsage(j) := i;
            end loop;

            inst.op := CBRANCH;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;


        elsif opcode < x"f0" then -- CFROUND
            inst.op := CFROUND;
            inst.src := src;
            inst.imm(31 downto 0) := imm(31 downto 0) and x"0000003f";


        else -- ISTORE
            if (getModCond(mode) < StoreL3Condition) then
                memMask := ScratchpadL1Mask when getModMem(mode) /= 0 else ScratchpadL2Mask;
            else
                memMask := ScratchpadL3Mask;
            end if;

            inst.op := ISTORE;
            inst.src := src;
            inst.dst := dst;
            inst.imm := imm;
            inst.memMask := memMask;

        end if;

    end procedure;

end compiler;