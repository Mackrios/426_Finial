library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity shift_left_1 is
  port(
    in_val  : in  unsigned(15 downto 0);
    out_val : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of shift_left_1 is
begin
  out_val <= shift_left(in_val, 1);
end architecture;
