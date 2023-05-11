-- Scratchpad Generator


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_core.all;


entity fillAes1Rx4 is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;

        hash     : in std_logic_vector(511 downto 0) := (others => '0');
        data     : out std_logic_vector(511 downto 0) := (others => '0');
        addr     : out std_logic_vector(14 downto 0) := (others => '0');

        is_valid : in boolean := false;
        is_done  : out boolean := false
    );
end fillAes1Rx4;


architecture fillAes1Rx4Arch of fillAes1Rx4 is
    constant AES_GEN_1R_KEY0 : std_logic_vector(127 downto 0) := x"b4f44917dbb5552b627166096daca553";
    constant AES_GEN_1R_KEY1 : std_logic_vector(127 downto 0) := x"0da1dc4e1725d378846a710d6d7caf07";
    constant AES_GEN_1R_KEY2 : std_logic_vector(127 downto 0) := x"3e20e345f4c0794f9f947ec63f1262f1";
    constant AES_GEN_1R_KEY3 : std_logic_vector(127 downto 0) := x"4916915416314c88b1ba317c6aef8135";

    constant count : integer := 32767; -- 32768

    signal ptr : integer := 0;
    signal init : boolean := true;
    signal state : std_logic_vector(511 downto 0);

    function calc (
        der : std_logic_vector(511 downto 0)
    )
    return std_logic_vector is
        variable res : std_logic_vector(511 downto 0);
    begin
        res(127 downto 0) := aesdec(AES_GEN_1R_KEY0, der(127 downto 0));
        res(255 downto 128) := aesenc(AES_GEN_1R_KEY1, der(255 downto 128));
        res(383 downto 256) := aesdec(AES_GEN_1R_KEY2, der(383 downto 256));
        res(511 downto 384) := aesenc(AES_GEN_1R_KEY3, der(511 downto 384));

        return res;
    end;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            ptr <= 0;
            init <= true;
            is_done <= false;

		elsif rising_edge(clk) and is_valid and not is_done then
            if init then
                init <= false;
                state <= calc(hash);
            else
                state <= calc(state);
            end if;

            data <= state;
            addr <= std_logic_vector(to_unsigned(ptr, 15));
        
            if not init then
                if ptr < count then
                    ptr <= ptr + 1;
                else
                    is_done <= true;
                end if;
            end if;
        
            report integer'image(ptr) & "/" & integer'image(count);
        end if;
    end process;

end fillAes1Rx4Arch;