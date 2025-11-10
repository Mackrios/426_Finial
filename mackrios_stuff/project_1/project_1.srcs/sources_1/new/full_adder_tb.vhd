library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder_tb is
end entity;

architecture test of full_adder_tb is
  component full_adder
    port(
      A, B, Cin : in  std_logic;
      Sum, Cout : out std_logic
    );
  end component;

  signal s_A, s_B, s_Cin, s_Sum, s_Cout : std_logic;
begin
  UUT: full_adder port map(A => s_A, B => s_B, Cin => s_Cin, Sum => s_Sum, Cout => s_Cout);

  process
  begin
    -- input combinations
    (s_A, s_B, s_Cin) <= ('0', '0', '0'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('0', '0', '1'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('0', '1', '0'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('0', '1', '1'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('1', '0', '0'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('1', '0', '1'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('1', '1', '0'); wait for 10 ns;
    (s_A, s_B, s_Cin) <= ('1', '1', '1'); wait for 10 ns;
    wait;
  end process;
end architecture;