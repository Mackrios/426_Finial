library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity hazard_unit is
  port(
    -- ID stage
    rs_id          : in  unsigned(2 downto 0);
    rt_id          : in  unsigned(2 downto 0);
    -- EX stage
    rs_ex          : in  unsigned(2 downto 0);
    rt_ex          : in  unsigned(2 downto 0);
    -- EX dest / control
    write_reg_ex   : in  unsigned(2 downto 0);
    mem_read_ex    : in  std_logic;
    reg_write_ex   : in  std_logic;
    -- MEM stage
    write_reg_mem  : in  unsigned(2 downto 0);
    reg_write_mem  : in  std_logic;
    -- WB stage
    write_reg_wb   : in  unsigned(2 downto 0);
    reg_write_wb   : in  std_logic;
    -- Control hazards
    branch_taken   : in  std_logic;
    jump_taken     : in  std_logic;
    -- Outputs
    stall          : out std_logic;
    flush_if_id    : out std_logic;
    flush_id_ex    : out std_logic;
    forward_a      : out unsigned(1 downto 0);
    forward_b      : out unsigned(1 downto 0)
  );
end entity;


architecture rtl of hazard_unit is
begin
  process(rs_id, rt_id, rs_ex, rt_ex,
          write_reg_ex, mem_read_ex, reg_write_ex,
          write_reg_mem, reg_write_mem,
          write_reg_wb, reg_write_wb,
          branch_taken, jump_taken)
  begin
    -- defaults
    stall       <= '0';
    flush_if_id <= '0';
    flush_id_ex <= '0';
    forward_a   <= "00";
    forward_b   <= "00";

    -- ------------ load-use stall (ID vs EX) ------------
    if (mem_read_ex = '1') and 
       (write_reg_ex /= "000") and
       ((write_reg_ex = rs_id) or (write_reg_ex = rt_id)) then
      stall       <= '1';
      flush_id_ex <= '1';
    end if;

    -- ------------ branch / jump flush ------------
    if (branch_taken = '1') or (jump_taken = '1') then
      flush_if_id <= '1';
      flush_id_ex <= '1';
    end if;

    -- ------------ forwarding (EX vs MEM/WB) ------------
    -- A input (using rs_ex)
    if (reg_write_mem = '1') and (write_reg_mem /= "000") and
       (write_reg_mem = rs_ex) then
      forward_a <= "10";      -- from EX/MEM
    elsif (reg_write_wb = '1') and (write_reg_wb /= "000") and
          (write_reg_wb = rs_ex) then
      forward_a <= "01";      -- from MEM/WB
    end if;

    -- B input (using rt_ex)
    if (reg_write_mem = '1') and (write_reg_mem /= "000") and
       (write_reg_mem = rt_ex) then
      forward_b <= "10";
    elsif (reg_write_wb = '1') and (write_reg_wb /= "000") and
          (write_reg_wb = rt_ex) then
      forward_b <= "01";
    end if;
  end process;
end architecture;


---- code to test
--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;

--entity hazard_unit is
--  port(
--    -- ID stage
--    rs_id          : in  unsigned(2 downto 0);
--    rt_id          : in  unsigned(2 downto 0);
--    -- EX stage
--    rs_ex          : in  unsigned(2 downto 0);
--    rt_ex          : in  unsigned(2 downto 0);
--    -- EX dest / control
--    write_reg_ex   : in  unsigned(2 downto 0);
--    mem_read_ex    : in  std_logic;
--    reg_write_ex   : in  std_logic;
--    -- MEM stage
--    write_reg_mem  : in  unsigned(2 downto 0);
--    reg_write_mem  : in  std_logic;
--    -- WB stage
--    write_reg_wb   : in  unsigned(2 downto 0);
--    reg_write_wb   : in  std_logic;
--    -- Control hazards
--    branch_taken   : in  std_logic;
--    jump_taken     : in  std_logic;
--    -- Outputs
--    stall          : out std_logic;
--    flush_if_id    : out std_logic;
--    flush_id_ex    : out std_logic;
--    forward_a      : out unsigned(1 downto 0);
--    forward_b      : out unsigned(1 downto 0)
--  );
--end entity;

--architecture rtl of hazard_unit is
--begin
--  process(rs_id, rt_id, rs_ex, rt_ex,
--          write_reg_ex, mem_read_ex, reg_write_ex,
--          write_reg_mem, reg_write_mem,
--          write_reg_wb, reg_write_wb,
--          branch_taken, jump_taken)
--  begin
--    -- Defaults
--    stall       <= '0';
--    flush_if_id <= '0';
--    flush_id_ex <= '0';
--    forward_a   <= "00";
--    forward_b   <= "00";
    
--    -- ============================================================
--    -- LOAD-USE HAZARD DETECTION (ID stage vs EX stage)
--    -- ============================================================
--    -- Stall if:
--    --   1. EX stage has a LOAD instruction (mem_read_ex = '1')
--    --   2. EX stage will write to a register (reg_write_ex = '1')
--    --   3. ID stage instruction needs that register (rs_id or rt_id matches)
--    -- 
--    -- When this happens: stall PC and IF/ID, insert bubble in ID/EX
    
--    if (mem_read_ex = '1') and (reg_write_ex = '1') and
--       ((write_reg_ex = rs_id) or (write_reg_ex = rt_id)) then
--      stall       <= '1';
--      flush_id_ex <= '1';  -- Insert NOP into EX stage
--    end if;
    
--    -- ============================================================
--    -- CONTROL HAZARD HANDLING (Branch/Jump Flush)
--    -- ============================================================
--    -- When branch or jump is taken:
--    --   - Flush IF/ID (kill the instruction we just fetched)
--    --   - Flush ID/EX (kill the instruction in decode)
    
--    if (branch_taken = '1') or (jump_taken = '1') then
--      flush_if_id <= '1';
--      flush_id_ex <= '1';
--    end if;
    
--    -- ============================================================
--    -- DATA FORWARDING (EX stage vs MEM/WB stages)
--    -- ============================================================
--    -- Forward to ALU input A (which uses rs_ex in EX stage)
--    -- Priority: MEM stage > WB stage
    
--    -- Forward from MEM stage (EX/MEM pipeline register)
--    if (reg_write_mem = '1') and (write_reg_mem = rs_ex) then
--      forward_a <= "10";  -- Forward from EX/MEM
--    -- Forward from WB stage (MEM/WB pipeline register) 
--    elsif (reg_write_wb = '1') and (write_reg_wb = rs_ex) then
--      forward_a <= "01";  -- Forward from MEM/WB
--    end if;
    
--    -- Forward to ALU input B (which uses rt_ex in EX stage)
--    -- Priority: MEM stage > WB stage
    
--    -- Forward from MEM stage
--    if (reg_write_mem = '1') and (write_reg_mem = rt_ex) then
--      forward_b <= "10";  -- Forward from EX/MEM
--    -- Forward from WB stage
--    elsif (reg_write_wb = '1') and (write_reg_wb = rt_ex) then
--      forward_b <= "01";  -- Forward from MEM/WB
--    end if;
    
--  end process;
--end architecture;
