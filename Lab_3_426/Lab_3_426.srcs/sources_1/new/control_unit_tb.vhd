library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_unit_tb is
end entity;

architecture test of control_unit_tb is
  component control_unit
    port(
      opcode      : in  unsigned(3 downto 0);
      reg_dst     : out std_logic;
      jump        : out std_logic;
      branch      : out std_logic;
      mem_read    : out std_logic;
      mem_to_reg  : out std_logic;
      ALU_OP      : out unsigned(1 downto 0);
      mem_write   : out std_logic;
      alu_src     : out std_logic;
      reg_write   : out std_logic
    );
  end component;
  
  signal opcode : unsigned(3 downto 0) := (others => '0');
  signal reg_dst, jump, branch, mem_read, mem_to_reg : std_logic;
  signal mem_write, alu_src, reg_write : std_logic;
  signal ALU_OP : unsigned(1 downto 0);
  
begin
  UUT: control_unit
    port map(
      opcode     => opcode,
      reg_dst    => reg_dst,
      jump       => jump,
      branch     => branch,
      mem_read   => mem_read,
      mem_to_reg => mem_to_reg,
      ALU_OP     => ALU_OP,
      mem_write  => mem_write,
      alu_src    => alu_src,
      reg_write  => reg_write
    );
  
  process
  begin
    report "Starting Control Unit Testbench...";
    
    -- Test ADD (R-Type)
    report "Test 1: ADD Instruction (opcode = 0000)";
    opcode <= "0000";
    wait for 10 ns;
    assert reg_dst = '1' report "ADD: reg_dst should be 1" severity error;
    assert ALU_OP = "10" report "ADD: ALU_OP should be 10" severity error;
    assert reg_write = '1' report "ADD: reg_write should be 1" severity error;
    assert alu_src = '0' report "ADD: alu_src should be 0" severity error;
    assert mem_write = '0' report "ADD: mem_write should be 0" severity error;
    report "ADD Control Signals: reg_dst=" & std_logic'image(reg_dst) & 
           ", ALU_OP=" & integer'image(to_integer(ALU_OP)) &
           ", reg_write=" & std_logic'image(reg_write);
    
    -- Test LW (Load Word)
    report "Test 2: LW Instruction (opcode = 1000)";
    opcode <= "1000";
    wait for 10 ns;
    assert reg_dst = '0' report "LW: reg_dst should be 0" severity error;
    assert alu_src = '1' report "LW: alu_src should be 1" severity error;
    assert mem_to_reg = '1' report "LW: mem_to_reg should be 1" severity error;
    assert reg_write = '1' report "LW: reg_write should be 1" severity error;
    assert mem_read = '1' report "LW: mem_read should be 1" severity error;
    assert ALU_OP = "00" report "LW: ALU_OP should be 00" severity error;
    report "LW Control Signals: mem_read=" & std_logic'image(mem_read) &
           ", mem_to_reg=" & std_logic'image(mem_to_reg);
    
    -- Test SW (Store Word)
    report "Test 3: SW Instruction (opcode = 1001)";
    opcode <= "1001";
    wait for 10 ns;
    assert alu_src = '1' report "SW: alu_src should be 1" severity error;
    assert mem_write = '1' report "SW: mem_write should be 1" severity error;
    assert ALU_OP = "00" report "SW: ALU_OP should be 00" severity error;
    assert reg_write = '0' report "SW: reg_write should be 0" severity error;
    report "SW Control Signals: mem_write=" & std_logic'image(mem_write);
    
    -- Test ADDI
    report "Test 4: ADDI Instruction (opcode = 1010)";
    opcode <= "1010";
    wait for 10 ns;
    assert reg_dst = '0' report "ADDI: reg_dst should be 0" severity error;
    assert alu_src = '1' report "ADDI: alu_src should be 1" severity error;
    assert reg_write = '1' report "ADDI: reg_write should be 1" severity error;
    assert ALU_OP = "00" report "ADDI: ALU_OP should be 00" severity error;
    report "ADDI Control Signals OK";
    
    -- Test BEQ (Branch Equal)
    report "Test 5: BEQ Instruction (opcode = 1011)";
    opcode <= "1011";
    wait for 10 ns;
    assert branch = '1' report "BEQ: branch should be 1" severity error;
    assert alu_src = '1' report "BEQ: alu_src should be 1" severity error;
    assert ALU_OP = "01" report "BEQ: ALU_OP should be 01" severity error;
    assert reg_write = '0' report "BEQ: reg_write should be 0" severity error;
    report "BEQ Control Signals: branch=" & std_logic'image(branch);
    
    -- Test BGT (Branch Greater Than)
    report "Test 6: BGT Instruction (opcode = 1100)";
    opcode <= "1100";
    wait for 10 ns;
    assert branch = '1' report "BGT: branch should be 1" severity error;
    assert ALU_OP = "01" report "BGT: ALU_OP should be 01" severity error;
    report "BGT Control Signals OK";
    
    -- Test Jump
    report "Test 7: JUMP Instruction (opcode = 1111)";
    opcode <= "1111";
    wait for 10 ns;
    assert jump = '1' report "JUMP: jump should be 1" severity error;
    assert reg_write = '0' report "JUMP: reg_write should be 0" severity error;
    assert mem_write = '0' report "JUMP: mem_write should be 0" severity error;
    report "JUMP Control Signals: jump=" & std_logic'image(jump);
    
    -- Test all R-Type instructions
    report "Test 8-14: All R-Type Instructions";
    for i in 0 to 7 loop
      opcode <= to_unsigned(i, 4);
      wait for 10 ns;
      assert reg_dst = '1' report "R-Type: reg_dst failed" severity error;
      assert ALU_OP = "10" report "R-Type: ALU_OP failed" severity error;
      assert reg_write = '1' report "R-Type: reg_write failed" severity error;
    end loop;
    report "All R-Type instructions OK";
    
    report "Control Unit Testbench Complete!";
    wait;
  end process;
end architecture;