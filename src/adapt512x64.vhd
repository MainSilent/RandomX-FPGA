library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity adapt512x64 is
    port(
        clk  : in  std_logic;

        mem_addr : out  std_logic_vector(14 downto 0);
        mem_din  : out  std_logic_vector(511 downto 0);
        mem_dout : in std_logic_vector(511 downto 0);

        addr : in  integer;
        din  : in  unsigned(63 downto 0);
        dout : out unsigned(63 downto 0)
    );
end adapt512x64;


architecture adapt512x64Arch of adapt512x64 is
begin

    process (clk)
        variable i, m : integer;
        variable tin : std_logic_vector(511 downto 0);
    begin
        i := addr / 8;
        m := addr mod 8;

        -- Read
        mem_addr <= std_logic_vector(to_unsigned(i, mem_addr'length));
        dout <= unsigned(mem_dout(((m+1)*64)-1 downto m*64));

        -- Write
        tin := mem_dout;
        tin(((m+1)*64)-1 downto m*64) := std_logic_vector(din);
        mem_din <= tin;
    end process;

end adapt512x64Arch;