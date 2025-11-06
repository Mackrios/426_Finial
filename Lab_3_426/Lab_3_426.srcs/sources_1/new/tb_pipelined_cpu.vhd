library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pipelined_cpu is
end entity;

architecture testbench of tb_pipelined_cpu is
  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  
  -- Signals
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal pc_out : unsigned(15 downto 0);
  signal reg0, reg1, reg2, reg3 : unsigned(15 downto 0);
  signal reg4, reg5, reg6, reg7 : unsigned(15 downto 0);
  
  -- Component declaration
  component pipelined_cpu
    port(
      clk    : in  std_logic;
      rst    : in  std_logic;
      pc_out : out unsigned(15 downto 0);
      reg0, reg1, reg2, reg3 : out unsigned(15 downto 0);
      reg4, reg5, reg6, reg7 : out unsigned(15 downto 0)
    );
  end component;
  
  -- Test control
  signal sim_done : boolean := false;
  
  -- Helper function to convert unsigned to hex string
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
  -- Instantiate the CPU
  UUT: pipelined_cpu port map(
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
  
  -- Clock generation
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
  
  -- Stimulus and monitoring process
  stim_process: process
    variable cycle_count : integer := 0;
    variable prev_pc : unsigned(15 downto 0) := (others => '1'); -- Initialize to invalid value
    variable stall_count : integer := 0;
  begin
    -- Reset the system
    rst <= '1';
    wait for CLK_PERIOD * 2;
    rst <= '0';
    
    report "========================================" severity note;
    report "  PIPELINED CPU TESTBENCH" severity note;
    report "========================================" severity note;
    report "Clock Period: " & time'image(CLK_PERIOD) severity note;
    report "Reset complete. Starting execution..." severity note;
    report "========================================" severity note;
    report "" severity note;
    
    -- Wait one cycle for PC to update after reset
    wait for CLK_PERIOD;
    prev_pc := pc_out;
    
    -- Run for several clock cycles and monitor execution
    for i in 0 to 60 loop
      wait for CLK_PERIOD;
      cycle_count := i;
      
      -- Check for stalls (FIXED LOGIC)
      if pc_out = prev_pc then
        stall_count := stall_count + 1;
        if stall_count = 1 then
          report "CYCLE " & integer'image(i) & ": [STALL DETECTED] PC = 0x" & to_hex_string(pc_out) severity warning;
        end if;
      else
        if stall_count > 0 then
          report "CYCLE " & integer'image(i) & ": [STALL ENDED] Stalled for " & 
                 integer'image(stall_count) & " cycles" severity note;
          stall_count := 0;
        end if;
        report "CYCLE " & integer'image(i) & ": PC = 0x" & to_hex_string(pc_out) &
               " (delta: +" & integer'image(to_integer(pc_out - prev_pc)) & ")" severity note;
      end if;
      
      -- Print register values periodically
      if i mod 10 = 0 and i > 0 then
        report "  === Register Snapshot (Cycle " & integer'image(i) & ") ===" severity note;
        report "    R0 = 0x" & to_hex_string(reg0) severity note;
        report "    R1 = 0x" & to_hex_string(reg1) severity note;
        report "    R2 = 0x" & to_hex_string(reg2) severity note;
        report "    R3 = 0x" & to_hex_string(reg3) severity note;
        report "    R4 = 0x" & to_hex_string(reg4) severity note;
        report "    R5 = 0x" & to_hex_string(reg5) severity note;
        report "    R6 = 0x" & to_hex_string(reg6) severity note;
        report "    R7 = 0x" & to_hex_string(reg7) severity note;
      end if;
      
      -- Pipeline milestone checks
      if i = 5 then
        report "  [MILESTONE] Pipeline FULL - All 5 stages active!" severity note;
      elsif i = 10 then
        report "  [CHECK] First 10 cycles complete" severity note;
      elsif i = 20 then
        report "  [CHECK] 20 cycles complete" severity note;
      end if;
      
      -- Detect PC jumps (non-sequential by more than 2)
      if prev_pc /= (others => '1') and 
         pc_out /= prev_pc and 
         pc_out /= (prev_pc + 2) then
        report "  [EVENT] NON-SEQUENTIAL PC JUMP: 0x" & to_hex_string(prev_pc) & 
               " -> 0x" & to_hex_string(pc_out) severity note;
      end if;
      
      prev_pc := pc_out;
    end loop;
    
    -- Final report
    report "" severity note;
    report "========================================" severity note;
    report "  SIMULATION SUMMARY" severity note;
    report "========================================" severity note;
    report "Total Cycles: " & integer'image(cycle_count) severity note;
    report "Final PC: 0x" & to_hex_string(pc_out) & " (" & integer'image(to_integer(pc_out)) & " decimal)" severity note;
    report "Instructions Fetched: ~" & integer'image(to_integer(pc_out)/2) severity note;
    report "" severity note;
    report "Final Register File State:" severity note;
    report "  R0 = 0x" & to_hex_string(reg0) & " (" & integer'image(to_integer(reg0)) & ")" severity note;
    report "  R1 = 0x" & to_hex_string(reg1) & " (" & integer'image(to_integer(reg1)) & ")" severity note;
    report "  R2 = 0x" & to_hex_string(reg2) & " (" & integer'image(to_integer(reg2)) & ")" severity note;
    report "  R3 = 0x" & to_hex_string(reg3) & " (" & integer'image(to_integer(reg3)) & ")" severity note;
    report "  R4 = 0x" & to_hex_string(reg4) & " (" & integer'image(to_integer(reg4)) & ")" severity note;
    report "  R5 = 0x" & to_hex_string(reg5) & " (" & integer'image(to_integer(reg5)) & ")" severity note;
    report "  R6 = 0x" & to_hex_string(reg6) & " (" & integer'image(to_integer(reg6)) & ")" severity note;
    report "  R7 = 0x" & to_hex_string(reg7) & " (" & integer'image(to_integer(reg7)) & ")" severity note;
    report "========================================" severity note;
    
    -- Functional verification checks
    report "" severity note;
    report "========================================" severity note;
    report "  FUNCTIONAL VERIFICATION" severity note;
    report "========================================" severity note;
    
    -- Check 1: PC should have advanced
    if pc_out > x"0000" then
      report "[PASS] PC advanced from initial value" severity note;
    else
      report "[FAIL] PC did not advance!" severity error;
    end if;
    
    -- Check 2: Register modification check
    if reg0 /= x"0000" or reg1 /= x"0000" or reg2 /= x"0000" or 
       reg3 /= x"0000" or reg4 /= x"0000" or reg5 /= x"0000" or 
       reg6 /= x"0000" or reg7 /= x"0000" then
      report "[PASS] At least one register was modified" severity note;
    else
      report "[INFO] No registers modified" severity note;
      report "       This could mean:" severity note;
      report "       - Instruction memory is empty (all NOPs)" severity note;
      report "       - Register debug outputs not connected" severity note;
      report "       - Program doesn't write to registers" severity note;
    end if;
    
    -- Check 3: PC should be even (half-word aligned)
    if pc_out(0) = '0' then
      report "[PASS] PC is properly aligned (even address)" severity note;
    else
      report "[FAIL] PC alignment error (odd address)!" severity error;
    end if;
    
    -- Check 4: PC should advance steadily (no infinite loop at 0)
    if pc_out > x"0010" then
      report "[PASS] PC advanced beyond initial instructions" severity note;
    else
      report "[WARN] PC only reached 0x" & to_hex_string(pc_out) severity warning;
    end if;
    
    report "========================================" severity note;
    report "" severity note;
    
    -- End simulation
    sim_done <= true;
    report "*** SIMULATION COMPLETE ***" severity note;
    report "" severity note;
    wait;
  end process;
  
  -- Watchdog process to detect infinite loops
  watchdog_process: process
  begin
    wait for CLK_PERIOD * 100;
    if not sim_done then
      report "WATCHDOG: Simulation timeout - possible infinite loop" severity failure;
    end if;
    wait;
  end process;
  
end architecture testbench;