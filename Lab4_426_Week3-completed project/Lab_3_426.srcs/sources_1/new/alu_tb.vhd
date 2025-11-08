library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu_tb is
end entity;

architecture test of alu_tb is
  component alu
    port(
      A, B      : in  unsigned(15 downto 0);
      ALUctr    : in  unsigned(3 downto 0);
      shamt     : in  unsigned(2 downto 0);
      Result    : out unsigned(15 downto 0);
      Zero      : out std_logic;
      Overflow  : out std_logic;
      Carryout  : out std_logic
    );
  end component;
  
  signal A, B, Result : unsigned(15 downto 0) := (others => '0');
  signal ALUctr       : unsigned(3 downto 0) := (others => '0');
  signal shamt        : unsigned(2 downto 0) := (others => '0');
  signal Zero, Overflow, Carryout : std_logic;
  
begin
  UUT: alu
    port map(
      A        => A,
      B        => B,
      ALUctr   => ALUctr,
      shamt    => shamt,
      Result   => Result,
      Zero     => Zero,
      Overflow => Overflow,
      Carryout => Carryout
    );
  
  process
  begin
    report "Starting ALU Testbench...";
    
    -- Test 1: ADD (0x0005 + 0x000A = 0x000F)
    report "Test 1: ADD";
    A <= x"0005";
    B <= x"000A";
    ALUctr <= "0000";
    shamt <= "000";
    wait for 10 ns;
    assert Result = x"000F" report "ADD failed!" severity error;
    assert Zero = '0' report "Zero flag wrong for ADD" severity error;
    report "ADD: " & integer'image(to_integer(A)) & " + " & 
           integer'image(to_integer(B)) & " = " & integer'image(to_integer(Result));
    
    -- Test 2: SUB (0x0010 - 0x0005 = 0x000B)
    report "Test 2: SUB";
    A <= x"0010";
    B <= x"0005";
    ALUctr <= "0001";
    wait for 10 ns;
    assert Result = x"000B" report "SUB failed!" severity error;
    report "SUB: " & integer'image(to_integer(A)) & " - " & 
           integer'image(to_integer(B)) & " = " & integer'image(to_integer(Result));
    
    -- Test 3: AND (0xFFFF AND 0x00FF = 0x00FF)
    report "Test 3: AND";
    A <= x"FFFF";
    B <= x"00FF";
    ALUctr <= "0010";
    wait for 10 ns;
    assert Result = x"00FF" report "AND failed!" severity error;
    report "AND: Result = " & integer'image(to_integer(Result));
    
    -- Test 4: OR (0x00F0 OR 0x000F = 0x00FF)
    report "Test 4: OR";
    A <= x"00F0";
    B <= x"000F";
    ALUctr <= "0011";
    wait for 10 ns;
    assert Result = x"00FF" report "OR failed!" severity error;
    report "OR: Result = " & integer'image(to_integer(Result));
    
    -- Test 5: XOR (0xFFFF XOR 0x00FF = 0xFF00)
    report "Test 5: XOR";
    A <= x"FFFF";
    B <= x"00FF";
    ALUctr <= "0100";
    wait for 10 ns;
    assert Result = x"FF00" report "XOR failed!" severity error;
    report "XOR: Result = " & integer'image(to_integer(Result));
    
    -- Test 6: SLL (0x0001 << 2 = 0x0004)
    report "Test 6: SLL (Shift Left Logical)";
    A <= x"0001";
    B <= x"0000";
    ALUctr <= "0101";
    shamt <= "010";  -- Shift by 2
    wait for 10 ns;
    assert Result = x"0004" report "SLL failed!" severity error;
    report "SLL: 0x0001 << 2 = " & integer'image(to_integer(Result));
    
    -- Test 7: SRL (0x0008 >> 2 = 0x0002)
    report "Test 7: SRL (Shift Right Logical)";
    A <= x"0008";
    ALUctr <= "0110";
    shamt <= "010";  -- Shift by 2
    wait for 10 ns;
    assert Result = x"0002" report "SRL failed!" severity error;
    report "SRL: 0x0008 >> 2 = " & integer'image(to_integer(Result));
    
    -- Test 8: SRA (0x8000 >>> 1 = 0xC000) - sign extend
    report "Test 8: SRA (Shift Right Arithmetic)";
    A <= x"8000";
    ALUctr <= "0111";
    shamt <= "001";  -- Shift by 1
    wait for 10 ns;
    assert Result = x"C000" report "SRA failed!" severity error;
    report "SRA: 0x8000 >>> 1 = " & integer'image(to_integer(Result));
    
    -- Test 9: SLT (0x0005 < 0x000A = 1)
    report "Test 9: SLT (Set Less Than)";
    A <= x"0005";
    B <= x"000A";
    ALUctr <= "1000";
    shamt <= "000";
    wait for 10 ns;
    assert Result = x"0001" report "SLT failed!" severity error;
    report "SLT: 5 < 10 = " & integer'image(to_integer(Result));
    
    -- Test 10: SLT (0x000A < 0x0005 = 0)
    report "Test 10: SLT (Set Less Than - false)";
    A <= x"000A";
    B <= x"0005";
    ALUctr <= "1000";
    wait for 10 ns;
    assert Result = x"0000" report "SLT false case failed!" severity error;
    report "SLT: 10 < 5 = " & integer'image(to_integer(Result));
    
    -- Test 11: NOR (0x00FF NOR 0x0F00 = 0xF0F0)
    report "Test 11: NOR";
    A <= x"00FF";
    B <= x"0F00";
    ALUctr <= "1010";
    wait for 10 ns;
    assert Result = x"F0F0" report "NOR failed!" severity error;
    report "NOR: Result = " & integer'image(to_integer(Result));
    
    -- Test 12: Zero flag (0x0005 - 0x0005 = 0)
    report "Test 12: Zero Flag Test";
    A <= x"0005";
    B <= x"0005";
    ALUctr <= "0001";  -- SUB
    wait for 10 ns;
    assert Result = x"0000" report "Zero result failed!" severity error;
    assert Zero = '1' report "Zero flag not set!" severity error;
    report "Zero Flag: " & std_logic'image(Zero);
    
    -- Test 13: Overflow (0x7FFF + 0x0001 = overflow)
    report "Test 13: Overflow Test";
    A <= x"7FFF";  -- Max positive signed 16-bit
    B <= x"0001";
    ALUctr <= "0000";  -- ADD
    wait for 10 ns;
    assert Overflow = '1' report "Overflow not detected!" severity error;
    report "Overflow: " & std_logic'image(Overflow);
    
    -- Test 14: Multiply by 4 using shift (Phase 1 test program)
    report "Test 14: Multiply by 4 (0x000F << 2)";
    A <= x"000F";  -- $v2 initial value
    ALUctr <= "0101";  -- SLL
    shamt <= "010";    -- Shift by 2
    wait for 10 ns;
    assert Result = x"003C" report "Multiply by 4 failed!" severity error;
    report "0x000F * 4 = " & integer'image(to_integer(Result));
    
    -- Test 15: Divide by 8 using shift (Phase 1 test program)
    report "Test 15: Divide by 8 (0x0040 >> 3)";
    A <= x"0040";  -- $v0 initial value (64)
    ALUctr <= "0110";  -- SRL
    shamt <= "011";    -- Shift by 3
    wait for 10 ns;
    assert Result = x"0008" report "Divide by 8 failed!" severity error;
    report "0x0040 / 8 = " & integer'image(to_integer(Result));
    
    report "ALU Testbench Complete!";
    wait;
  end process;
end architecture;