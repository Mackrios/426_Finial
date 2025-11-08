library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder_32bit_tb is
end entity;

architecture test of adder_32bit_tb is
  component adder_32bit
    port(
      A, B : in  unsigned(31 downto 0);
      Cin  : in  std_logic;
      Sum  : out unsigned(31 downto 0);
      Cout : out std_logic
    );
  end component;

  signal s_A, s_B, s_Sum : unsigned(31 downto 0);
  signal s_Cin, s_Cout   : std_logic;
begin
  UUT: adder_32bit port map(A => s_A, B => s_B, Cin => s_Cin, Sum => s_Sum, Cout => s_Cout);

  process
  begin
    -- Test 1: Simple addition
    s_A <= to_unsigned(15, 32);
    s_B <= to_unsigned(20, 32);
    s_Cin <= '0';
    wait for 20 ns;

    -- Test 2: Addition with carry 
    s_A <= x"0000FFFF";
    s_B <= x"00000001";
    wait for 20 ns;

    -- Test 3: Addition with final carry out
    s_A <= x"FFFFFFFF";
    s_B <= x"00000001";
    wait for 20 ns;

    -- Test 4: Addition with Cin
    s_A <= to_unsigned(5, 32);
    s_B <= to_unsigned(10, 32);
    s_Cin <= '1';
    wait for 20 ns;

    wait;
  end process;
end architecture;