library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu_tb is
end entity;

architecture test of alu_tb is
  component alu
    port(
      A, B      : in  unsigned(31 downto 0);
      ALUctr    : in  unsigned(2 downto 0);
      Result    : out unsigned(31 downto 0);
      Zero, Overflow, Carryout : out std_logic
    );
  end component;

  signal s_A, s_B, s_Result : unsigned(31 downto 0);
  signal s_ALUctr           : unsigned(2 downto 0);
  signal s_Zero, s_Overflow, s_Carryout : std_logic;
begin
  UUT: alu port map (A => s_A, B => s_B, ALUctr => s_ALUctr, Result => s_Result, Zero => s_Zero, Overflow => s_Overflow, Carryout => s_Carryout);

  process
  begin
    s_A <= to_unsigned(25, 32);
    s_B <= to_unsigned(10, 32);
    wait for 20 ns;

    -- (25 + 10 = 35)
    s_ALUctr <= "000"; wait for 20 ns;
    
    -- (25 - 10 = 15)
    s_ALUctr <= "001"; wait for 20 ns;
    
    -- Zero flag (10 - 10 = 0)
    s_A <= to_unsigned(10, 32); wait for 20 ns;
    s_ALUctr <= "001"; wait for 20 ns;
    
    -- Overflow 
    s_A <= x"7FFFFFFF";
    s_B <= x"00000001"; 
    s_ALUctr <= "000"; wait for 20 ns;
    
    -- Test AND
    s_A <= x"0000FFFF";
    s_B <= x"FFFF0000";
    s_ALUctr <= "010"; wait for 20 ns;
    
    -- Test OR
    s_ALUctr <= "011"; wait for 20 ns;
    
    -- Test SLL
    s_A <= to_unsigned(1, 32);
    s_ALUctr <= "100"; wait for 20 ns;
    
    -- Test SRL
    s_A <= to_unsigned(8, 32);
    s_ALUctr <= "101"; wait for 20 ns;
    
    -- Test SRA on negative number
    s_A <= x"F0000000"; --negative number
    s_ALUctr <= "111"; wait for 20 ns;
    
    wait;
  end process;
end architecture;