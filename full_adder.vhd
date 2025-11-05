library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder is
  port(
    A, B, Cin : in  std_logic;
    Sum, Cout : out std_logic
  );
end entity;

architecture rtl of full_adder is
begin
  Sum  <= A xor B xor Cin;
  Cout <= (A and B) or (B and Cin) or (A and Cin);
end architecture;
