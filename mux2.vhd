library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mux2 is
  generic(WIDTH : integer := 16);
  port(
    a, b : in  unsigned(WIDTH-1 downto 0);
    sel  : in  std_logic;
    y    : out unsigned(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of mux2 is
begin
  y <= b when sel = '1' else a;
end architecture;
