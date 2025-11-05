library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity imem is
  port(
    addr  : in  unsigned(15 downto 0);
    instr : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of imem is
  type mem_array is array (0 to 255) of unsigned(15 downto 0);
  signal ROM : mem_array := (
    others => (others => '0')
  );
begin
  -- word-aligned addressing (ignore LSB)
  instr <= ROM(to_integer(addr(15 downto 1)));
end architecture;
