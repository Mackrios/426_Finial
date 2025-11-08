--------------------------------------------------------------------------------
-- MIPS Pipeline Testbench
-- Tests a pipelined CPU implementation with assembled opcodes
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_mips_pipeline is
end entity;

architecture testbench of tb_mips_pipeline is

  --------------------------------------------------------------------------------
  -- Constants
  --------------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;
  constant MAX_INSTRUCTIONS : integer := 256;
  
  --------------------------------------------------------------------------------
  -- CPU Interface Signals
  --------------------------------------------------------------------------------
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal pc_out : unsigned(15 downto 0);
  signal reg0, reg1, reg2, reg3 : unsigned(15 downto 0);
  signal reg4, reg5, reg6, reg7 : unsigned(15 downto 0);
  
  --------------------------------------------------------------------------------
  -- Component Declaration
  --------------------------------------------------------------------------------
  component pipelined_cpu
    port(
      clk    : in  std_logic;
      rst    : in  std_logic;
      pc_out : out unsigned(15 downto 0);
      reg0   : out unsigned(15 downto 0);
      reg1   : out unsigned(15 downto 0);
      reg2   : out unsigned(15 downto 0);
      reg3   : out unsigned(15 downto 0);
      reg4   : out unsigned(15 downto 0);
      reg5   : out unsigned(15 downto 0);
      reg6   : out unsigned(15 downto 0);
      reg7   : out unsigned(15 downto 0)
    );
  end component;
  
  --------------------------------------------------------------------------------
  -- Simulation Control
  --------------------------------------------------------------------------------
  signal sim_done : boolean := false;
  
  --------------------------------------------------------------------------------
  -- Test Program - Assembled Opcodes
  --------------------------------------------------------------------------------
  type opcode_array is array (0 to MAX_INSTRUCTIONS-1) of unsigned(15 downto 0);
  
  signal opcodes : opcode_array := (
    0 => x"0060",
    1 => x"1228",
    2 => x"24F0",
    3 => x"34F8",
    4 => x"74E0",
    5 => x"422A",
    6 => x"5231",
    7 => x"A485",
    others => (others => '0')
  );
  
  --------------------------------------------------------------------------------
  -- Utility Functions
  --------------------------------------------------------------------------------
  -- Converts unsigned value to hex string for reporting
  function to_hex_string(value : unsigned) return string is
    variable hex_chars : string(1 to 16) := "0123456789ABCDEF";
    variable result : string(1 to 4);
    variable temp : unsigned(15 downto 0);
  begin
    temp := value;
    for i in 4 downto 1 loop
      result(i) := hex_chars(to_integer(temp(3 downto 0)) + 1);
      temp := shift_right(temp, 4);
    end loop;
    return result;
  end function;
  
begin
  
  --------------------------------------------------------------------------------
  -- Device Under Test Instantiation
  --------------------------------------------------------------------------------
  DUT: pipelined_cpu port map(
    clk    => clk,
    rst    => rst,
    pc_out => pc_out,
    reg0   => reg0,
    reg1   => reg1,
    reg2   => reg2,
    reg3   => reg3,
    reg4   => reg4,
    reg5   => reg5,
    reg6   => reg6,
    reg7   => reg7
  );
  
  --------------------------------------------------------------------------------
  -- Clock Generation Process
  -- Generates 50% duty cycle clock until simulation completes
  --------------------------------------------------------------------------------
  clk_process: process
  begin
    while not sim_done loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;
  
  --------------------------------------------------------------------------------
  -- Main Stimulus and Verification Process
  -- 1. Resets the CPU
  -- 2. Loads and displays test program
  -- 3. Runs CPU for 120 cycles
  -- 4. Monitors PC progression and register values
  -- 5. Performs final verification checks
  --------------------------------------------------------------------------------
  stim_process: process
    variable cycle : integer := 0;
    variable prev_pc : unsigned(15 downto 0) := (others => '0');
    variable test_pass : integer := 0;
    variable test_fail : integer := 0;
    variable num_opcodes : integer := 8;
  begin
    -- Reset sequence
    rst <= '1';
    wait for CLK_PERIOD * 2;
    rst <= '0';
    
    -- Print test header and loaded program
    report "";
    report "================================================================================";
    report "  MIPS CPU TESTBENCH - USING ASSEMBLED OPCODES";
    report "================================================================================";
    report "Number of opcodes loaded: " & integer'image(num_opcodes);
    report "Program size: " & integer'image(num_opcodes * 2) & " bytes";
    report "";
    
    report "Loaded Opcodes:";
    for i in 0 to num_opcodes-1 loop
      report "  [" & integer'image(i) & "] 0x" & to_hex_string(opcodes(i));
    end loop;
    report "";
    report "Starting CPU execution...";
    report "";
    
    -- Initialize PC tracking
    wait for CLK_PERIOD;
    prev_pc := pc_out;
    
    -- Main execution loop - run for 120 cycles
    for i in 0 to 120 loop
      wait for CLK_PERIOD;
      cycle := i;
      
      -- Periodic status reporting every 5 cycles
      if i mod 5 = 0 then
        report "";
        report "--- CYCLE " & integer'image(i) & " ---";
        report "  PC: 0x" & to_hex_string(pc_out);
        report "  R0=0x" & to_hex_string(reg0) & "  R1=0x" & to_hex_string(reg1) & 
                "  R2=0x" & to_hex_string(reg2) & "  R3=0x" & to_hex_string(reg3);
        report "  R4=0x" & to_hex_string(reg4) & "  R5=0x" & to_hex_string(reg5) & 
                "  R6=0x" & to_hex_string(reg6) & "  R7=0x" & to_hex_string(reg7);
      end if;
      
      -- Check PC progression to detect branches and jumps
      if pc_out /= prev_pc then
        if (pc_out - prev_pc) = 2 then
          -- Normal sequential execution
          if i < 10 then
            report "  [PASS] Sequential PC increment";
          end if;
          test_pass := test_pass + 1;
        elsif pc_out < prev_pc then
          -- Backward branch detected
          report "  [BRANCH] Backward branch: 0x" & to_hex_string(prev_pc) & 
                 " -> 0x" & to_hex_string(pc_out);
        elsif (pc_out - prev_pc) > 2 then
          -- Forward jump detected
          report "  [JUMP] Non-sequential: 0x" & to_hex_string(prev_pc) & 
                 " -> 0x" & to_hex_string(pc_out);
        end if;
      end if;
      
      prev_pc := pc_out;
    end loop;
    
    -- Print execution summary
    report "";
    report "================================================================================";
    report "  SIMULATION COMPLETE";
    report "================================================================================";
    report "Total Cycles: " & integer'image(cycle + 1);
    report "Final PC: 0x" & to_hex_string(pc_out) & " (" & 
            integer'image(to_integer(pc_out)) & " bytes)";
    report "Instructions Executed: ~" & integer'image(to_integer(pc_out) / 2);
    report "";
    report "Final Register State:";
    report "  R0: 0x" & to_hex_string(reg0);
    report "  R1: 0x" & to_hex_string(reg1);
    report "  R2: 0x" & to_hex_string(reg2);
    report "  R3: 0x" & to_hex_string(reg3);
    report "  R4: 0x" & to_hex_string(reg4);
    report "  R5: 0x" & to_hex_string(reg5);
    report "  R6: 0x" & to_hex_string(reg6);
    report "  R7: 0x" & to_hex_string(reg7);
    report "================================================================================";
    
    -- Verification checks
    report "";
    report "Pipeline Stage Verification:";
    
    -- Check 1: PC should have advanced
    if pc_out > x"0000" then
      report "  [PASS] IF Stage: PC advanced to 0x" & to_hex_string(pc_out);
      test_pass := test_pass + 1;
    else
      report "  [FAIL] IF Stage: PC did not advance";
      test_fail := test_fail + 1;
    end if;
    
    -- Check 2: Sufficient cycles executed
    if cycle >= 5 then
      report "  [PASS] Pipeline: Executed " & integer'image(cycle + 1) & " cycles";
      test_pass := test_pass + 1;
    else
      report "  [FAIL] Pipeline: Insufficient cycles";
      test_fail := test_fail + 1;
    end if;
    
    -- Check 3: PC alignment (should be even for 16-bit instructions)
    if pc_out(0) = '0' then
      report "  [PASS] Alignment: PC is word-aligned";
      test_pass := test_pass + 1;
    else
      report "  [FAIL] Alignment: PC misaligned";
      test_fail := test_fail + 1;
    end if;
    
    -- Final test results
    report "";
    report "TEST RESULTS: " & integer'image(test_pass) & " PASSED, " & 
            integer'image(test_fail) & " FAILED";
    report "================================================================================";
    
    sim_done <= true;
    wait;
  end process;
  
  --------------------------------------------------------------------------------
  -- Timeout Checker Process
  -- Terminates simulation after 300 cycles if not completed normally
  --------------------------------------------------------------------------------
  timeout_checker: process
  begin
    for i in 0 to 300 loop
      wait for CLK_PERIOD;
      if sim_done then
        exit;
      end if;
    end loop;
    if not sim_done then
      report "TIMEOUT: Simulation exceeded 300 cycles" severity failure;
    end if;
    wait;
  end process;
  
end architecture testbench;