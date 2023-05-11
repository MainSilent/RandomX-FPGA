library ieee;
library std;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;


entity tb_scratchpad is
end tb_scratchpad;


architecture test of tb_scratchpad is

    constant bram_WIDTH  : integer := 512;
    constant bram_DEPTH  : integer := 32768;
    constant bram_ADDR_W : integer := 15;
    signal addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');

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

    component fillAes1Rx4 is
        port (
            clk      : in  std_logic;
            reset    : in  std_logic;

            hash     : in std_logic_vector(511 downto 0);
            data     : out std_logic_vector(511 downto 0);
            addr     : out std_logic_vector(14 downto 0);

            is_valid : in boolean := false;
            is_done  : out boolean := false
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

    signal finish : boolean := false;
    signal reset : std_logic := '0';
    signal clk : std_logic := '0';
    constant clk_period : time := 1 fs;

    signal we   : std_logic := '1';
    signal din  : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');
    signal dout : std_logic_vector(bram_WIDTH - 1 downto 0)  := (others => '0');

    signal hash : std_logic_vector(511 downto 0) := x"ca68baa8dcc6d3837335cdb36dca9737f2d2f9805ce084a8bf275b42cf9d0a8022dce447134369d302543c691f8e467a939fa8af8513b9afd0110c6593625f96";
    signal final_hash : std_logic_vector(511 downto 0);
    
    signal gen_is_valid : boolean := true;
    signal gen_is_done  : boolean := false;
    signal gen_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');

    signal hash_is_valid : boolean := false;
    signal hash_is_done  : boolean := false;
    signal hash_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');

    constant read_count : integer := 32768;
    signal read_num : integer := 0;
    signal read_rate : integer := 0;
    signal read_addr : std_logic_vector(bram_ADDR_W - 1 downto 0) := (others => '0');

    file fin : text open read_mode is "sch.dat";
begin

    scratchpad : bram
        port map (
            clk => clk,
            we => we,
            addr => addr,
            din => din,
            dout => dout
        );

    scratchpad_generator : fillAes1Rx4
        port map (
            clk => clk,
            reset => reset,
            hash => hash,
            data => din,
            addr => gen_addr,
            is_valid => gen_is_valid,
            is_done => gen_is_done
        );

    scratchpad_hash : hashAes1Rx4
        port map (
            clk => clk,
            reset => reset,
            hash => final_hash,
            data => dout,
            addr => hash_addr,
            is_valid => hash_is_valid,
            is_done => hash_is_done
        );

    addr <= hash_addr when hash_is_valid else
            gen_addr when gen_is_valid else
            read_addr;


    init : process(clk)
    begin
        if rising_edge(clk) then
            if gen_is_done and we = '1' then
                if din /= x"375198c011775b86c4cc98d6e0919e63ffbe63b237ffb160fbf791cbae76509864ae6e106a7352c0347f1322f4a70bad3b9ef87d7bede5a4a2eda891266ef129" then
                    report "Hash doesn't match" severity FAILURE;
                else
                    report "Scratchpad Hash [OK]";
                end if;
    
                we <= '0';
                gen_is_valid <= false;
            end if;
        end if;
    end process;


    check : process(clk)
        variable rdline : line;
        variable res : std_logic_vector(511 downto 0);
    begin
        if we = '0' and rising_edge(clk) and not hash_is_valid then
            if read_rate < 2 then
                read_rate <= read_rate + 1;
                read_num <= read_num + 1;
                read_addr <= std_logic_vector(to_unsigned(read_num, 15));
            else
                readline(fin, rdline);
                hread(rdline, res);

                if dout = res then
                    report integer'image(read_num) & " checked";
                else
                    report "Expected value: " & to_hstring(res);
                    report "Received value: " & to_hstring(dout);
                    report integer'image(read_num) & " Doesn't match" severity FAILURE;
                end if;

                if read_num < read_count then
                    read_num <= read_num + 1;
                    read_addr <= std_logic_vector(to_unsigned(read_num, 15));
                else
                    hash_is_valid <= true;
                end if;
            end if;
        end if;
    end process;


    hash_check : process(hash_is_done)
    begin
        if hash_is_done then
            finish <= true;

            if final_hash /= x"0ce46cf87b5e8d4e1d38e61cd1c904917d8ce7427360b90a899d3041bd47e9af3a94ed1f924e5106577ef422bc1b3717dbfec54034c0f723ff9af4fb817f34c9" then
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