library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity register_file is
  port(
    clk       : in  std_logic;
    RegWr     : in  std_logic;
    Rw, Ra, Rb: in  unsigned(4 downto 0);
    busW      : in  unsigned(31 downto 0);
    busA, busB: out unsigned(31 downto 0)
  );
end entity;

architecture rtl of register_file is
  type reg_array is array(0 to 31) of unsigned(31 downto 0);
  signal Regs : reg_array := (
    0  => x"00000005",  -- register 0 = 5
    1  => x"0000000A",  -- register 1 = 10
    2  => x"00000003",  -- register 2 = 3
    others => (others => '0')
  );
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if RegWr = '1' then
        Regs(to_integer(Rw)) <= busW;
      end if;
    end if;
  end process;

  busA <= Regs(to_integer(Ra));
  busB <= Regs(to_integer(Rb));
end architecture;

