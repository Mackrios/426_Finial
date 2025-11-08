library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu_control_tb is
end entity;

architecture test of alu_control_tb is
  component alu_control
    port(
      opcode    : in  unsigned(3 downto 0);
      ALU_OP    : in  unsigned(1 downto 0);
      ALUctr    : out unsigned(3 downto 0)
    );
  end component;
  
  signal opcode : unsigned(3 downto 0) := (others => '0');
  signal ALU_OP : unsigned(1 downto 0) := (others => '0');
  signal ALUctr : unsigned(3 downto 0);
  
begin
  UUT: alu_control
    port map(
      opcode => opcode,
      ALU_OP => ALU_OP,
      ALUctr => ALUctr
    );
  
  process
  begin
    report "Starting ALU Control Testbench...";
    
    -- Test Memory Operations (ALU_OP = 00)
    report "Test 1: Memory Operations (LW/SW/ADDI)";
    ALU_OP <= "00";
    opcode <= "1000";  -- Don't care for memory ops
    wait for 10 ns;
    assert ALUctr = "0000" report "Memory op should give ADD!" severity error;
    report "Memory Op -> ALUctr = " & integer'image(to_integer(ALUctr)) & " (ADD)";
    
    -- Test Branch Operations (ALU_OP = 01)
    report "Test 2: Branch Operations";
    ALU_OP <= "01";
    opcode <= "1011";  -- Don't care for branch
    wait for 10 ns;
    assert ALUctr = "0001" report "Branch op should give SUB!" severity error;
    report "Branch Op -> ALUctr = " & integer'image(to_integer(ALUctr)) & " (SUB)";
    
    -- Test R-Type Operations (ALU_OP = 10)
    report "Test 3: R-Type ADD (opcode = 0000)";
    ALU_OP <= "10";
    opcode <= "0000";
    wait for 10 ns;
    assert ALUctr = "0000" report "ADD opcode failed!" severity error;
    report "ADD -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 4: R-Type SUB (opcode = 0001)";
    opcode <= "0001";
    wait for 10 ns;
    assert ALUctr = "0001" report "SUB opcode failed!" severity error;
    report "SUB -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 5: R-Type AND (opcode = 0010)";
    opcode <= "0010";
    wait for 10 ns;
    assert ALUctr = "0010" report "AND opcode failed!" severity error;
    report "AND -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 6: R-Type OR (opcode = 0011)";
    opcode <= "0011";
    wait for 10 ns;
    assert ALUctr = "0011" report "OR opcode failed!" severity error;
    report "OR -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 7: R-Type SLL (opcode = 0100)";
    opcode <= "0100";
    wait for 10 ns;
    assert ALUctr = "0101" report "SLL opcode failed!" severity error;
    report "SLL -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 8: R-Type SRL (opcode = 0101)";
    opcode <= "0101";
    wait for 10 ns;
    assert ALUctr = "0110" report "SRL opcode failed!" severity error;
    report "SRL -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 9: R-Type SRA (opcode = 0110)";
    opcode <= "0110";
    wait for 10 ns;
    assert ALUctr = "0111" report "SRA opcode failed!" severity error;
    report "SRA -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "Test 10: R-Type XOR (opcode = 0111)";
    opcode <= "0111";
    wait for 10 ns;
    assert ALUctr = "0100" report "XOR opcode failed!" severity error;
    report "XOR -> ALUctr = " & integer'image(to_integer(ALUctr));
    
    report "ALU Control Testbench Complete!";
    wait;
  end process;
end architecture;