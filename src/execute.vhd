library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use work.common.all;


entity execute is
    port(
        clk  : in  std_logic;
        reset : in  std_logic;

        we   : out  std_logic := '0';
        addr : out integer := 0;
        din  : out unsigned(63 downto 0)  := (others => '0');
        dout : in unsigned(63 downto 0)  := (others => '0');

        eMask : in regt_float;
        program : in instructions;
        treg : in register_file;
        tround_mode : in round_type;

        out_reg : out register_file;
        out_round_mode : out round_type;

        is_valid : in boolean := false;
        is_done  : out boolean := false
    );
end execute;


architecture executeArch of execute is
    signal ic : integer := 0;
    signal delay : integer := 0;
    signal reg : register_file := treg;
    signal round_mode : round_type := tround_mode;
begin

    process(clk, reset)
        variable target : integer := -1;
        variable skip : boolean := true;
        variable op : instruction_type;
        variable p : instruction;
        variable tmpr : unsigned(63 downto 0);
    begin
        if reset = '1' then
            ic <= 0;
            delay <= 0;
            is_done <= false;
            reg <= treg;
            round_mode <= tround_mode;

		elsif rising_edge(clk) and is_valid and not is_done then

            --------- Setup ---------
            if ic /= 256 then
                p := program(ic);
                op := p.op;
                tmpr := reg.r(p.src) when p.src /= -1 else p.imm;
            else
                op := NOP;
            end if;

            if op = FADD_M or op = FSUB_M or op = FDIV_M then
                addr <= getScratchpadAddress(reg.r(p.src), p.imm, p.memMask);
            elsif op = IADD_M or op = ISUB_M or op = IMUL_M or op = IMULH_M or op = ISMULH_M or op = IXOR_M then
                tmpr := reg.r(p.src) when p.src /= -1 else (others => '0');
                addr <= getScratchpadAddress(tmpr, p.imm, p.memMask);
            end if;


            --------- Check OP ---------
            if op = IADD_RS then
                tmpr := (reg.r(p.src) sll p.shift) + p.imm;
                reg.r(p.dst) <= reg.r(p.dst) + tmpr;
            end if;

            if op = IADD_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= reg.r(p.dst) + dout;
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = ISUB_R then
                reg.r(p.dst) <= reg.r(p.dst) - tmpr;
            end if;

            if op = ISUB_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= reg.r(p.dst) - dout;
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = IMUL_R or op = IMUL_RCP then
                reg.r(p.dst) <= resize(reg.r(p.dst) * tmpr, 64);
            end if;

            if op = IMUL_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= resize(reg.r(p.dst) * dout, 64);
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = IMULH_R then
                reg.r(p.dst) <= mulh(reg.r(p.dst), reg.r(p.src));
            end if;

            if op = IMULH_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= mulh(reg.r(p.dst), dout);
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = ISMULH_R then
                reg.r(p.dst) <= smulh(reg.r(p.dst), reg.r(p.src));
            end if;

            if op = ISMULH_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= smulh(reg.r(p.dst), dout);
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = INEG_R then
                reg.r(p.dst) <= not reg.r(p.dst) + 1;
            end if;

            if op = IXOR_R then
                reg.r(p.dst) <= reg.r(p.dst) xor tmpr;
            end if;

            if op = IXOR_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.r(p.dst) <= reg.r(p.dst) xor dout;
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = IROR_R then
                reg.r(p.dst) <= reg.r(p.dst) ror to_integer(tmpr and x"000000000000003f");
            end if;

            if op = IROL_R then
                reg.r(p.dst) <= reg.r(p.dst) rol to_integer(tmpr and x"000000000000003f");
            end if;

            if op = ISWAP_R then
                reg.r(p.dst) <= reg.r(p.src);
                reg.r(p.src) <= reg.r(p.dst);
            end if;

            if op = FSWAP_R then
                if p.dst < 6 then
                    reg.e(p.dst)(0) <= reg.e(p.dst)(1);
                    reg.e(p.dst)(1) <= reg.e(p.dst)(0);
                else
                    reg.f(p.dst - 6)(0) <= reg.f(p.dst - 6)(1);
                    reg.f(p.dst - 6)(1) <= reg.f(p.dst - 6)(0);
                end if;
            end if;

            if op = FADD_R then
                reg.f(p.dst)(0) <= add(reg.f(p.dst)(0), reg.a(p.src)(0), round_mode);
                reg.f(p.dst)(1) <= add(reg.f(p.dst)(1), reg.a(p.src)(1), round_mode);
            end if;

            if op = FADD_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.f(p.dst)(0) <= add(reg.f(p.dst)(0), si_float(dout(31 downto 0)), round_mode);
                    reg.f(p.dst)(1) <= add(reg.f(p.dst)(1), si_float(dout(63 downto 32)), round_mode);
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = FSUB_R then
                reg.f(p.dst)(0) <= subtract(reg.f(p.dst)(0), reg.a(p.src)(0), round_mode);
                reg.f(p.dst)(1) <= subtract(reg.f(p.dst)(1), reg.a(p.src)(1), round_mode);
            end if;

            if op = FSUB_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.f(p.dst)(0) <= subtract(reg.f(p.dst)(0), si_float(dout(31 downto 0)), round_mode);
                    reg.f(p.dst)(1) <= subtract(reg.f(p.dst)(1), si_float(dout(63 downto 32)), round_mode);
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = FSCAL_R then
                reg.f(p.dst)(0) <= reg.f(p.dst)(0) xor c_float(-3.645561009778199e-304);
                reg.f(p.dst)(1) <= reg.f(p.dst)(1) xor c_float(-3.645561009778199e-304);
            end if;

            if op = FMUL_R then
                reg.e(p.dst)(0) <= multiply(reg.e(p.dst)(0), reg.a(p.src)(0), round_mode);
                reg.e(p.dst)(1) <= multiply(reg.e(p.dst)(1), reg.a(p.src)(1), round_mode);
            end if;

            if op = FDIV_M then
                if delay = 3 then
                    delay <= 0;
                    skip := true;

                    reg.e(p.dst)(0) <= divide(
                        reg.e(p.dst)(0),
                        maskRegisterExponentMantissa(dout(31 downto 0), eMask(0)),
                        round_mode
                    );
                    reg.e(p.dst)(1) <= divide(
                        reg.e(p.dst)(1),
                        maskRegisterExponentMantissa(dout(63 downto 32), eMask(1)),
                        round_mode
                    );
                else
                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;

            if op = FSQRT_R then
                reg.e(p.dst)(0) <= sqrt(reg.e(p.dst)(0), round_mode);
                reg.e(p.dst)(1) <= sqrt(reg.e(p.dst)(1), round_mode);
            end if;

            if op = CFROUND then
                tmpr := (reg.r(p.src) ror to_integer(p.imm(31 downto 0))) mod 4;

                case tmpr(1 downto 0) is
                    when "00" =>
                        round_mode <= round_nearest;
                    when "01" =>
                        round_mode <= round_neginf;
                    when "10" =>
                        round_mode <= round_inf;
                    when "11" =>
                        round_mode <= round_zero;
                    when others => 
                        round_mode <= round_nearest;
                end case;
            end if;

            if op = CBRANCH then
                tmpr := reg.r(p.dst) + p.imm;
                reg.r(p.dst) <= tmpr;
                tmpr := tmpr and to_unsigned(p.memMask, reg.r(p.dst)'length);
        
                if tmpr = x"0000000000000000" then
                    target := p.target;
                end if;
            end if;

            if op = ISTORE then
                if delay = 4 then
                    we <= '0';
                    delay <= 0;
                    skip := true;
                else
                    if delay = 3 then
                        we <= '1';
                    end if;

                    din <= reg.r(p.src);
                    addr <= getScratchpadAddress(reg.r(p.dst), p.imm, p.memMask);

                    delay <= delay + 1;
                    skip := false;
                end if;
            end if;


            --------- Increase IC ---------
            if skip then
                if ic < RANDOMX_PROGRAM_SIZE then
                    ic <= ic + 1;

                    if target /= -1 then
                        ic <= target+1;
                        target := -1;
                    end if;

                    if (ic + 1) = 256 then
                        addr <= 0;
                    end if;
                else
                    out_reg <= reg;
                    out_round_mode <= round_mode;
                    is_done <= true;
                end if;
            end if;

        end if;
    end process;

end executeArch;