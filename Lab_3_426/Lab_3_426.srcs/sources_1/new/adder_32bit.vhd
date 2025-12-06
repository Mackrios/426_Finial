library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder_16bit is
  port(
    A, B : in  unsigned(15 downto 0);
    Cin  : in  std_logic;
    Sum  : out unsigned(15 downto 0);
    Cout : out std_logic
  );
end entity;

architecture structural of adder_16bit is
  component full_adder
    port(
      A, B, Cin : in  std_logic;
      Sum, Cout : out std_logic
    );
  end component;
  
  signal carry : std_logic_vector(16 downto 0);
  
begin
  carry(0) <= Cin;
  
  gen_adders: for i in 0 to 15 generate
    FA: full_adder
      port map(
        A    => A(i),
        B    => B(i),
        Cin  => carry(i),
        Sum  => Sum(i),
        Cout => carry(i+1)
      );
  end generate;
  
  Cout <= carry(16);  -- the 17th bit holds carry out bit, which is why it was changed
  
end architecture;