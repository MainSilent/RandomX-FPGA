library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_core.all;


entity hashAes1Rx4 is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;

        hash : out std_logic_vector(511 downto 0);
        data : in std_logic_vector(511 downto 0);
        addr : out std_logic_vector(14 downto 0) := (others => '0');

        is_valid : in boolean := false;
        is_done  : out boolean := false
    );
end hashAes1Rx4;


architecture hashAes1Rx4Arch of hashAes1Rx4 is
    constant AES_HASH_1R_STATE0 : std_logic_vector(127 downto 0) := x"d7983aadcc82db479fa856de92b52c0d";
    constant AES_HASH_1R_STATE1 : std_logic_vector(127 downto 0) := x"ace78057f59e125a15c7b798338d996e";
    constant AES_HASH_1R_STATE2 : std_logic_vector(127 downto 0) := x"e8a07ce45079506bae62c7d06a770017";
    constant AES_HASH_1R_STATE3 : std_logic_vector(127 downto 0) := x"7e99494879a1000507ad828d630a240c";

    constant AES_HASH_1R_XKEY0 : std_logic_vector(127 downto 0) := x"0689020190dc56bf8b24949ff6fa8389";
    constant AES_HASH_1R_XKEY1 : std_logic_vector(127 downto 0) := x"ed18f99bee1043c651f4e03c61b263d1";

    constant INIT_STATE : std_logic_vector(511 downto 0) := AES_HASH_1R_STATE3 & AES_HASH_1R_STATE2 & AES_HASH_1R_STATE1 & AES_HASH_1R_STATE0;
    
    constant count : integer := 32769; -- 32768

    signal ptr : integer := 0;
    signal init : boolean := true;
    signal temp_state : std_logic_vector(511 downto 0) := INIT_STATE;
begin

    process(clk, reset)
        variable state : std_logic_vector(511 downto 0);
    begin
        if reset = '1' then
            ptr <= 0;
            init <= true;
            addr <= (others => '0');
            is_done <= false;
        
        elsif rising_edge(clk) and is_valid and not is_done then
            if init then
                ptr <= 1;
                init <= false;
                temp_state <= INIT_STATE;
                addr <= "000000000000001";
            else
                state := temp_state;

                if ptr < count then
                    ptr <= ptr + 1;

                    state(127 downto 0) := aesenc(data(127 downto 0), state(127 downto 0));
                    state(255 downto 128) := aesdec(data(255 downto 128), state(255 downto 128));
                    state(383 downto 256) := aesenc(data(383 downto 256), state(383 downto 256));
                    state(511 downto 384) := aesdec(data(511 downto 384), state(511 downto 384));
    
                    addr <= std_logic_vector(to_unsigned(ptr+1, 15)) when (ptr+1) < 32767 else (others => '1');

                    temp_state <= state;
                else
                    state(127 downto 0) := aesenc(AES_HASH_1R_XKEY0, state(127 downto 0));
                    state(255 downto 128) := aesdec(AES_HASH_1R_XKEY0, state(255 downto 128));
                    state(383 downto 256) := aesenc(AES_HASH_1R_XKEY0, state(383 downto 256));
                    state(511 downto 384) := aesdec(AES_HASH_1R_XKEY0, state(511 downto 384));

                    state(127 downto 0) := aesenc(AES_HASH_1R_XKEY1, state(127 downto 0));
                    state(255 downto 128) := aesdec(AES_HASH_1R_XKEY1, state(255 downto 128));
                    state(383 downto 256) := aesenc(AES_HASH_1R_XKEY1, state(383 downto 256));
                    state(511 downto 384) := aesdec(AES_HASH_1R_XKEY1, state(511 downto 384));

                    hash <= state;

                    is_done <= true;
                end if;
            end if;
        end if;
    end process;

end hashAes1Rx4Arch;