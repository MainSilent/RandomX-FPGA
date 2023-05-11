library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use work.common.all;


entity run is
    port(
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
end run;


architecture runArch of run is

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
            treg : inout register_file;
            tround_mode : inout round_type;

            out_reg : out register_file;
            out_round_mode : out round_type;
    
            is_valid : in boolean := false;
            is_done  : out boolean := false
        );
    end component;

    type state_type is (
        STATE_COMPILE,

        STATE_PRE_0,
        STATE_PRE_1,
        STATE_PRE_2,
        STATE_PRE_3,

        STATE_EXEC,
        STATE_DATASET,
        
        STATE_POST_1,
        STATE_POST_2,
        STATE_POST_3,

        STATE_CHECK
	);
    signal state : state_type := STATE_COMPILE;

    -- Compile
    signal comp_reg_a : regt_a;
    signal eMask : regt_float;
    signal readReg : readReg_t;
    signal program : instructions;
    signal datasetOffset : integer;
    signal ma, mx : std_logic_vector(31 downto 0) := (others => '0');
    signal spAddr0, spAddr1 : std_logic_vector(31 downto 0) := (others => '0');

    signal comp_ma, comp_mx : std_logic_vector(31 downto 0) := (others => '0');

    signal comp_is_valid : boolean := false;
    signal comp_is_done  : boolean := false;

    -- Execute
    signal reset_exec : std_logic := '1';
    signal reg : register_file := treg;
    signal round_mode : round_type := tround_mode;

    signal exec_reg : register_file := treg;
    signal exec_round_mode : round_type := tround_mode;

    signal exec_is_valid : boolean := false;
    signal exec_is_done : boolean := false;

    signal run_addr : integer := 0;
    signal run_din  : unsigned(63 downto 0)  := (others => '0');

    signal exec_addr : integer := 0;
    signal exec_din  : unsigned(63 downto 0)  := (others => '0');

    signal regc : integer := 0;
    signal count : integer := 0;
    signal delay : integer := 0;

    signal exec_we, run_we : std_logic;

begin
    -- Divide them separately because of overflow issues
    dataset_addr <= (
        (datasetOffset / CacheLineSize) + 
        (to_integer(unsigned(ma)) / CacheLineSize)
    );

    we <= exec_we when exec_is_valid else run_we;
    addr <= exec_addr when exec_is_valid else run_addr;
    din <= exec_din when exec_is_valid else run_din;

    compile : fillAes4Rx4
        port map (
            clk => clk,
            reset => reset,
            hash => hash,
            reg_a => comp_reg_a,
            eMask => eMask,
            readReg => readReg,
            program => program,
            datasetOffset => datasetOffset,
            ma => comp_ma,
            mx => comp_mx,
            is_valid => comp_is_valid,
            is_done => comp_is_done
        );

    execute_com : execute
        port map (
            clk => clk,
            reset => reset_exec,
            we => exec_we,
            addr => exec_addr,
            din => exec_din,
            dout => dout,
            eMask => eMask,
            program => program,
            treg => reg,
            tround_mode => round_mode,
            out_reg => exec_reg,
            out_round_mode => exec_round_mode,
            is_valid => exec_is_valid,
            is_done => exec_is_done
        );


    process(clk, reset)
        variable taddr : integer := 0;
        variable spMix : std_logic_vector(63 downto 0);
    begin
        if reset = '1' then
            regc <= 0;
            count <= 0;
            delay <= 0;
            reset_exec <= '1';
            is_done <= false;
            reg <= treg;
            round_mode <= tround_mode;

		elsif rising_edge(clk) and is_valid and not is_done then

            case state is
                when STATE_COMPILE =>
                    if not comp_is_valid then
                        comp_is_valid <= true;

                    elsif comp_is_done then
                        mx <= comp_mx;
                        ma <= comp_ma;

                        spAddr0 <= comp_mx;
                        spAddr1 <= comp_ma;

                        reg.a <= comp_reg_a;
                        reg.r <= (others => (others => '0'));
                        
                        state <= STATE_PRE_0;
                    end if;


                when STATE_PRE_0 =>
                    spMix := std_logic_vector(reg.r(readReg(0))) xor std_logic_vector(reg.r(readReg(1)));
                    spAddr0 <= (spAddr0 xor spMix(31 downto 0)) and ScratchpadL3Mask64;
                    spAddr1 <= (spAddr1 xor (spMix(31 downto 0) srl 32)) and ScratchpadL3Mask64;

                    state <= STATE_PRE_1;


                when STATE_PRE_1 =>
                    run_addr <= (to_integer(unsigned(spAddr0)) + 8 * regc) / 8;        

                    if delay = 3 then
                        delay <= 0;

                        reg.r(regc) <= reg.r(regc) xor dout;
                        
                        if regc = 7 then
                            regc <= 0;
                            state <= STATE_PRE_2;
                        else
                            regc <= regc + 1;
                        end if;
                    else
                        delay <= delay + 1;
                    end if;


                when STATE_PRE_2 =>
                    run_addr <= (to_integer(unsigned(spAddr1)) + 8 * regc) / 8;        

                    if delay = 3 then
                        delay <= 0;

                        reg.f(regc)(0) <= si_float(dout(31 downto 0));
                        reg.f(regc)(1) <= si_float(dout(63 downto 32));
                        
                        if regc = 3 then
                            regc <= 0;
                            state <= STATE_PRE_3;
                        else
                            regc <= regc + 1;
                        end if;
                    else
                        delay <= delay + 1;
                    end if;


                when STATE_PRE_3 =>
                    run_addr <= (to_integer(unsigned(spAddr1)) + 8 * (RegisterCountFlt + regc)) / 8;        

                    if delay = 3 then
                        delay <= 0;

                        reg.e(regc)(0) <= maskRegisterExponentMantissa(dout(31 downto 0), eMask(0));
                        reg.e(regc)(1) <= maskRegisterExponentMantissa(dout(63 downto 32), eMask(1));
                        
                        if regc = 3 then
                            regc <= 0;
                            state <= STATE_EXEC;
                        else
                            regc <= regc + 1;
                        end if;
                    else
                        delay <= delay + 1;
                    end if;


                when STATE_EXEC =>
                    if not exec_is_valid then
                        reset_exec <= '0';
                        exec_is_valid <= true;
                    elsif exec_is_done then
                        reset_exec <= '1';
                        exec_is_valid <= false;

                        reg <= exec_reg;
                        round_mode <= exec_round_mode;

                        state <= STATE_DATASET;
                    end if;


                when STATE_DATASET =>
                    spMix := std_logic_vector((reg.r(readReg(2)) xor reg.r(readReg(3))));
                    spMix(31 downto 0) := (mx xor spMix(31 downto 0)) and CacheLineAlignMask;

                    reg.r(0) <= reg.r(0) xor dataset_r0;
                    reg.r(1) <= reg.r(1) xor dataset_r1;
                    reg.r(2) <= reg.r(2) xor dataset_r2;
                    reg.r(3) <= reg.r(3) xor dataset_r3;
                    reg.r(4) <= reg.r(4) xor dataset_r4;
                    reg.r(5) <= reg.r(5) xor dataset_r5;
                    reg.r(6) <= reg.r(6) xor dataset_r6;
                    reg.r(7) <= reg.r(7) xor dataset_r7;

                    mx <= ma;
                    ma <= spMix(31 downto 0);

                    state <= STATE_POST_1;


                when STATE_POST_1 =>
                    run_addr <= (to_integer(unsigned(spAddr1)) + 8 * regc) / 8; 
                    run_din <= reg.r(regc);

                    if delay = 4 then
                        run_we <= '0';
                        delay <= 0;

                        if regc = 7 then
                            regc <= 0;
                            state <= STATE_POST_2;
                        else
                            regc <= regc + 1;
                        end if;
                    else
                        if delay = 3 then
                            run_we <= '1';
                        end if;

                        delay <= delay + 1;
                    end if;


                when STATE_POST_2 =>
                    if regc = 4 then
                        regc <= 0;
                        state <= STATE_POST_3;
                    else
                        reg.f(regc)(0) <= reg.f(regc)(0) xor reg.e(regc)(0);
                        reg.f(regc)(1) <= reg.f(regc)(1) xor reg.e(regc)(1);

                        regc <= regc + 1;
                    end if;


                when STATE_POST_3 =>
                    taddr := 0 when regc = 0 or regc = 1 else
                             1 when regc = 2 or regc = 3 else
                             2 when regc = 4 or regc = 5 else
                             3;

                    if regc = 1 or regc = 3 or regc = 5 or regc = 7 then
                        run_addr <= ((to_integer(unsigned(spAddr0)) + 16 * taddr) / 8) + 1;
                    else
                        run_addr <= (to_integer(unsigned(spAddr0)) + 16 * taddr) / 8;
                    end if;
                    
                    if delay = 4 then
                        run_we <= '0';
                        delay <= 0;

                        if regc = 7 then
                            regc <= 0;
                            run_addr <= 0;
                            state <= STATE_CHECK;
                        else
                            regc <= regc + 1;
                        end if;
                    else
                        if delay = 3 then
                            run_we <= '1';
                        end if;

                        case regc is
                            when 0 => run_din <= unsigned(to_stdlogicvector(reg.f(0)(0)));
                            when 1 => run_din <= unsigned(to_stdlogicvector(reg.f(0)(1)));
                            when 2 => run_din <= unsigned(to_stdlogicvector(reg.f(1)(0)));
                            when 3 => run_din <= unsigned(to_stdlogicvector(reg.f(1)(1)));
                            when 4 => run_din <= unsigned(to_stdlogicvector(reg.f(2)(0)));
                            when 5 => run_din <= unsigned(to_stdlogicvector(reg.f(2)(1)));
                            when 6 => run_din <= unsigned(to_stdlogicvector(reg.f(3)(0)));
                            when 7 => run_din <= unsigned(to_stdlogicvector(reg.f(3)(1)));
                            when others => null;
                        end case;                

                        delay <= delay + 1;
                    end if;


                when STATE_CHECK =>
                    report "Exec Iter: " & integer'image(count);

                    if count < (RANDOMX_PROGRAM_ITERATIONS-1) then
                        spAddr0 <= (others => '0');
                        spAddr1 <= (others => '0');

                        count <= count + 1;

                        state <= STATE_PRE_0;
                    else
                        treg <= reg;
                        tround_mode <= round_mode;

                        run_addr <= 0;
                        is_done <= true;
                    end if;
            end case;

        end if;
    end process;

end runArch;