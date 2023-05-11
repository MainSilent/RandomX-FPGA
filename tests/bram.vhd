library ieee;
library std;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;


entity bram is
    generic(
        WIDTH  : integer := 8;   -- data width of each memory location
        DEPTH  : integer := 256; -- depth of memory
        ADDR_W : integer := 8    -- address width
    );
    port(
        clk  : in  std_logic;
        we   : in  std_logic;
        addr : in  std_logic_vector(ADDR_W - 1 downto 0);
        din  : in  std_logic_vector(WIDTH - 1 downto 0);
        dout : out std_logic_vector(WIDTH - 1 downto 0)
    );
end bram;


architecture behavioral of bram is
    type mem_t is array(0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);
    signal memory : mem_t;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                memory(to_integer(unsigned(addr))) <= din;
            end if;
            
            dout <= memory(to_integer(unsigned(addr)));
        end if;
    end process;

end behavioral;