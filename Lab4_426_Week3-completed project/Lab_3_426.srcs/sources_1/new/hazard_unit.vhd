library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity hazard_unit is
  port(
    -- ID stage (instruction decode)
    rs_id          : in  unsigned(2 downto 0);
    rt_id          : in  unsigned(2 downto 0);
    -- EX stage (execute)
    write_reg_ex   : in  unsigned(2 downto 0);
    mem_read_ex    : in  std_logic;
    reg_write_ex   : in  std_logic;
    -- MEM stage (memory access)
    write_reg_mem  : in  unsigned(2 downto 0);
    reg_write_mem  : in  std_logic;
    -- WB stage (write back)
    write_reg_wb   : in  unsigned(2 downto 0);
    reg_write_wb   : in  std_logic;
    -- Control hazards
    branch_taken   : in  std_logic;
    jump_taken     : in  std_logic;
    -- Outputs
    stall          : out std_logic;
    flush_if_id    : out std_logic;
    flush_id_ex    : out std_logic;
    forward_a      : out unsigned(1 downto 0);  -- 00=no fwd, 01=WB, 10=MEM
    forward_b      : out unsigned(1 downto 0)
  );
end entity;

architecture rtl of hazard_unit is
begin
  process(rs_id, rt_id, write_reg_ex, mem_read_ex, reg_write_ex, 
          write_reg_mem, reg_write_mem, write_reg_wb, reg_write_wb, 
          branch_taken, jump_taken)
  begin
    -- Default values
    stall <= '0';
    flush_if_id <= '0';
    flush_id_ex <= '0';
    forward_a <= "00";
    forward_b <= "00";
    
    -- ========== DATA HAZARD DETECTION ==========
    
    
    
    -- Load-Use Hazard: Need to stall if next instruction uses loaded data
    if (mem_read_ex = '1') and 
       ((write_reg_ex = rs_id) or (write_reg_ex = rt_id)) and
       (write_reg_ex /= "000") then
      stall <= '1';           -- Stall IF and ID stages
      flush_id_ex <= '1';     -- Insert bubble (NOP) in EX stage
    end if;
    
    -- ========== CONTROL HAZARD DETECTION ==========
    
    -- Branch or Jump taken: Flush wrong instructions
    if (branch_taken = '1') or (jump_taken = '1') then
      flush_if_id <= '1';     -- Flush IF/ID register
      flush_id_ex <= '1';     -- Flush ID/EX register
    end if;
    
    -- ========== FORWARDING LOGIC ==========
    
    -- Forward to operand A (Rs source)
    -- Priority: EX hazard (from MEM stage) > MEM hazard (from WB stage)
    if (reg_write_mem = '1') and (write_reg_mem /= "000") and 
       (write_reg_mem = rs_id) then
      forward_a <= "10";  -- Forward from MEM stage (EX/MEM pipeline reg)
    elsif (reg_write_wb = '1') and (write_reg_wb /= "000") and 
          (write_reg_wb = rs_id) then
      forward_a <= "01";
    else
      forward_a <= "00";
    end if;
    
    -- Forward to operand B (Rt source)
    if (reg_write_mem = '1') and (write_reg_mem /= "000") and 
       (write_reg_mem = rt_id) then
      forward_b <= "10";  -- Forward from MEM stage
    elsif (reg_write_wb = '1') and (write_reg_wb /= "000") and 
          (write_reg_wb = rt_id) then
      forward_b <= "01"; 
    else
      forward_b <= "00"; 
    end if;
    
  end process;
end architecture;