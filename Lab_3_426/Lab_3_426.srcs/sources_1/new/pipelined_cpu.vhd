-- CRITICAL FIXES:
-- 1. Changed imm_4bit to imm_6bit (bits 5:0, not 3:0)
-- 2. Added proper function field extraction for R-type
-- 3. Fixed sign extension to use 6-bit immediate

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pipelined_cpu is
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
    reg7   : out unsigned(15 downto 0);
    -- DEBUG PORTS (simulation only)
    dbg_if_id_instr      : out unsigned(15 downto 0);
    dbg_id_ex_opcode     : out unsigned(3 downto 0);
    dbg_ex_mem_alu_res   : out unsigned(15 downto 0);
    dbg_mem_wb_write_reg : out unsigned(2 downto 0)
  );
end entity;

architecture rtl of pipelined_cpu is
  
  signal pc          : unsigned(15 downto 0) := (others => '0');
  signal pc_next     : unsigned(15 downto 0);
  signal pc_plus_2   : unsigned(15 downto 0);
  signal instruction : unsigned(15 downto 0);
  
  signal if_id_pc    : unsigned(15 downto 0);
  signal if_id_instr : unsigned(15 downto 0);
  
  signal opcode      : unsigned(3 downto 0);
  signal opcode_for_alu : unsigned(3 downto 0);  -- ADDED: Opcode or function for ALU control
  signal rs, rt, rd  : unsigned(2 downto 0);
  signal imm_6bit    : unsigned(5 downto 0);  -- FIXED: Was imm_4bit
  signal funct       : unsigned(2 downto 0);  -- ADDED: Function field for R-type
  signal imm_extended: unsigned(15 downto 0);
  signal shamt       : unsigned(2 downto 0);
  signal jump_addr   : unsigned(11 downto 0);
  signal read_data1, read_data2 : unsigned(15 downto 0);
  
  signal reg_dst, jump, branch, mem_read, mem_to_reg : std_logic;
  signal alu_op      : unsigned(1 downto 0);
  signal mem_write, alu_src, reg_write : std_logic;
  
  signal branch_offset : signed(15 downto 0);
  signal branch_target : unsigned(15 downto 0);
  signal branch_condition : std_logic;
  
  signal id_ex_reg_write, id_ex_mem_to_reg, id_ex_mem_write : std_logic;
  signal id_ex_mem_read, id_ex_branch, id_ex_alu_src, id_ex_reg_dst : std_logic;
  signal id_ex_alu_op : unsigned(1 downto 0);
  signal id_ex_pc, id_ex_rd1, id_ex_rd2, id_ex_imm : unsigned(15 downto 0);
  signal id_ex_rs, id_ex_rt, id_ex_rd : unsigned(2 downto 0);
  signal id_ex_opcode : unsigned(3 downto 0);
  signal id_ex_shamt : unsigned(2 downto 0);
  
  signal alu_input_a, alu_input_b : unsigned(15 downto 0);
  signal alu_control_signal : unsigned(3 downto 0);
  signal alu_result : unsigned(15 downto 0);
  signal alu_zero, alu_overflow, alu_carryout : std_logic;
  signal forward_a, forward_b : unsigned(1 downto 0);
  signal forwarded_a, forwarded_b : unsigned(15 downto 0);
  signal write_reg_ex : unsigned(2 downto 0);
  
  signal ex_mem_reg_write, ex_mem_mem_to_reg : std_logic;
  signal ex_mem_mem_write, ex_mem_mem_read, ex_mem_branch : std_logic;
  signal ex_mem_alu_result, ex_mem_write_data : unsigned(15 downto 0);
  signal ex_mem_write_reg : unsigned(2 downto 0);
  signal ex_mem_zero : std_logic;
  signal ex_mem_branch_addr : unsigned(15 downto 0);
  
  signal mem_read_data : unsigned(15 downto 0);
  signal branch_taken : std_logic;
  signal jump_taken : std_logic;
  
  signal mem_wb_reg_write, mem_wb_mem_to_reg : std_logic;
  signal mem_wb_mem_data, mem_wb_alu_result : unsigned(15 downto 0);
  signal mem_wb_write_reg : unsigned(2 downto 0);
  
  signal write_back_data : unsigned(15 downto 0);
  
  signal stall, flush_if_id, flush_id_ex : std_logic;
  
  -- Component declarations (unchanged)
  component register_file
    port(
      clk       : in  std_logic;
      rst       : in  std_logic;
      RegWr     : in  std_logic;
      Rw        : in  unsigned(2 downto 0);
      Ra        : in  unsigned(2 downto 0);
      Rb        : in  unsigned(2 downto 0);
      busW      : in  unsigned(15 downto 0);
      busA      : out unsigned(15 downto 0);
      busB      : out unsigned(15 downto 0);
      reg0_out  : out unsigned(15 downto 0);
      reg1_out  : out unsigned(15 downto 0);
      reg2_out  : out unsigned(15 downto 0);
      reg3_out  : out unsigned(15 downto 0);
      reg4_out  : out unsigned(15 downto 0);
      reg5_out  : out unsigned(15 downto 0);
      reg6_out  : out unsigned(15 downto 0);
      reg7_out  : out unsigned(15 downto 0)
    );
  end component;
  
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
  
  component alu_control
    port(
      opcode : in  unsigned(3 downto 0);
      ALU_OP : in  unsigned(1 downto 0);
      ALUctr : out unsigned(3 downto 0)
    );
  end component;
  
  component alu
    port(
      A        : in  unsigned(15 downto 0);
      B        : in  unsigned(15 downto 0);
      ALUctr   : in  unsigned(3 downto 0);
      shamt    : in  unsigned(2 downto 0);
      Result   : out unsigned(15 downto 0);
      Zero     : out std_logic;
      Overflow : out std_logic;
      Carryout : out std_logic
    );
  end component;
  
  component instruction_memory
    port(
      address     : in  unsigned(15 downto 0);
      instruction : out unsigned(15 downto 0)
    );
  end component;
  
  component data_memory
    port(
      clk        : in  std_logic;
      address    : in  unsigned(15 downto 0);
      write_data : in  unsigned(15 downto 0);
      mem_write  : in  std_logic;
      mem_read   : in  std_logic;
      read_data  : out unsigned(15 downto 0)
    );
  end component;
  
  component IF_ID_reg
    port(
      clk       : in  std_logic;
      rst       : in  std_logic;
      stall     : in  std_logic;
      flush     : in  std_logic;
      pc_in     : in  unsigned(15 downto 0);
      instr_in  : in  unsigned(15 downto 0);
      pc_out    : out unsigned(15 downto 0);
      instr_out : out unsigned(15 downto 0)
    );
  end component;
  
  component ID_EX_reg
    port(
      clk             : in  std_logic;
      rst             : in  std_logic;
      stall           : in  std_logic;
      flush           : in  std_logic;
      reg_write_in    : in  std_logic;
      mem_to_reg_in   : in  std_logic;
      mem_write_in    : in  std_logic;
      mem_read_in     : in  std_logic;
      branch_in       : in  std_logic;
      alu_src_in      : in  std_logic;
      reg_dst_in      : in  std_logic;
      alu_op_in       : in  unsigned(1 downto 0);
      pc_in           : in  unsigned(15 downto 0);
      read_data1_in   : in  unsigned(15 downto 0);
      read_data2_in   : in  unsigned(15 downto 0);
      imm_in          : in  unsigned(15 downto 0);
      rs_in           : in  unsigned(2 downto 0);
      rt_in           : in  unsigned(2 downto 0);
      rd_in           : in  unsigned(2 downto 0);
      opcode_in       : in  unsigned(3 downto 0);
      shamt_in        : in  unsigned(2 downto 0);
      reg_write_out   : out std_logic;
      mem_to_reg_out  : out std_logic;
      mem_write_out   : out std_logic;
      mem_read_out    : out std_logic;
      branch_out      : out std_logic;
      alu_src_out     : out std_logic;
      reg_dst_out     : out std_logic;
      alu_op_out      : out unsigned(1 downto 0);
      pc_out          : out unsigned(15 downto 0);
      read_data1_out  : out unsigned(15 downto 0);
      read_data2_out  : out unsigned(15 downto 0);
      imm_out         : out unsigned(15 downto 0);
      rs_out          : out unsigned(2 downto 0);
      rt_out          : out unsigned(2 downto 0);
      rd_out          : out unsigned(2 downto 0);
      opcode_out      : out unsigned(3 downto 0);
      shamt_out       : out unsigned(2 downto 0)
    );
  end component;
  
  component EX_MEM_reg
    port(
      clk             : in  std_logic;
      rst             : in  std_logic;
      reg_write_in    : in  std_logic;
      mem_to_reg_in   : in  std_logic;
      mem_write_in    : in  std_logic;
      mem_read_in     : in  std_logic;
      branch_in       : in  std_logic;
      alu_result_in   : in  unsigned(15 downto 0);
      write_data_in   : in  unsigned(15 downto 0);
      write_reg_in    : in  unsigned(2 downto 0);
      zero_in         : in  std_logic;
      branch_addr_in  : in  unsigned(15 downto 0);
      reg_write_out   : out std_logic;
      mem_to_reg_out  : out std_logic;
      mem_write_out   : out std_logic;
      mem_read_out    : out std_logic;
      branch_out      : out std_logic;
      alu_result_out  : out unsigned(15 downto 0);
      write_data_out  : out unsigned(15 downto 0);
      write_reg_out   : out unsigned(2 downto 0);
      zero_out        : out std_logic;
      branch_addr_out : out unsigned(15 downto 0)
    );
  end component;
  
  component MEM_WB_reg
    port(
      clk            : in  std_logic;
      rst            : in  std_logic;
      reg_write_in   : in  std_logic;
      mem_to_reg_in  : in  std_logic;
      mem_data_in    : in  unsigned(15 downto 0);
      alu_result_in  : in  unsigned(15 downto 0);
      write_reg_in   : in  unsigned(2 downto 0);
      reg_write_out  : out std_logic;
      mem_to_reg_out : out std_logic;
      mem_data_out   : out unsigned(15 downto 0);
      alu_result_out : out unsigned(15 downto 0);
      write_reg_out  : out unsigned(2 downto 0)
    );
  end component;
  
component hazard_unit
  port(
    rs_id          : in  unsigned(2 downto 0);
    rt_id          : in  unsigned(2 downto 0);
    rs_ex          : in  unsigned(2 downto 0);
    rt_ex          : in  unsigned(2 downto 0);
    write_reg_ex   : in  unsigned(2 downto 0);
    write_reg_mem  : in  unsigned(2 downto 0);
    write_reg_wb   : in  unsigned(2 downto 0);
    mem_read_ex    : in  std_logic;
    reg_write_ex   : in  std_logic;
    reg_write_mem  : in  std_logic;
    reg_write_wb   : in  std_logic;
    branch_taken   : in  std_logic;
    jump_taken     : in  std_logic;
    stall          : out std_logic;
    flush_if_id    : out std_logic;
    flush_id_ex    : out std_logic;
    forward_a      : out unsigned(1 downto 0);
    forward_b      : out unsigned(1 downto 0)
  );
end component;

  
begin
  
  IMEM: instruction_memory 
    port map(
      address => pc,
      instruction => instruction
    );
  
  pc_plus_2 <= pc + 2;
  
  process(clk, rst)
  begin
    if rst = '1' then
      pc <= (others => '0');
    elsif rising_edge(clk) then
      if stall = '0' then
        pc <= pc_next;
      end if;
    end if;
  end process;
  
  pc_next <= branch_target when branch_taken = '1' else
             ("0000" & jump_addr) when jump_taken = '1' else
             pc_plus_2;
  
  IF_ID: IF_ID_reg 
    port map(
      clk => clk,
      rst => rst,
      stall => stall,
      flush => flush_if_id,
      pc_in => pc,
      instr_in => instruction,
      pc_out => if_id_pc,
      instr_out => if_id_instr
    );
  
-- ====================================================================
-- FIXED INSTRUCTION FIELD EXTRACTION
-- ====================================================================
opcode     <= if_id_instr(15 downto 12);
rs         <= if_id_instr(11 downto 9);
rt         <= if_id_instr(8 downto 6);
rd         <= if_id_instr(5 downto 3);
funct      <= if_id_instr(2 downto 0);    -- Function field for R-type
shamt      <= if_id_instr(2 downto 0);    -- Same as funct, used for shifts
imm_6bit   <= if_id_instr(5 downto 0);    -- 6-bit immediate
jump_addr  <= if_id_instr(11 downto 0);

-- For ALU control: R-type instructions need function field, others need opcode
-- When opcode = "0000" (R-type), use zero-extended funct[2:0]
with opcode select
  opcode_for_alu <=
    unsigned("0" & std_logic_vector(funct)) when "0000",  -- R-type
    opcode                                   when others;

  
  -- FIXED: Sign extension for 6-bit immediate
imm_extended <= (15 downto 6 => imm_6bit(5)) & imm_6bit;

  
  branch_offset <= signed(imm_extended);
  branch_target <= unsigned(signed(if_id_pc) + shift_left(branch_offset, 1));
  
  process(opcode, read_data1, read_data2)
  begin
    branch_condition <= '0';
    case opcode is
      when "0100" =>
        branch_condition <= '1';
      when "0101" =>
        if signed(read_data1) > signed(read_data2) then
          branch_condition <= '1';
        end if;
      when "0110" =>
        if signed(read_data1) >= signed(read_data2) then
          branch_condition <= '1';
        end if;
      when "0111" =>
        if read_data1 = read_data2 then
          branch_condition <= '1';
        end if;
      when others =>
        branch_condition <= '0';
    end case;
  end process;
  
  branch_taken <= branch and branch_condition;
  
  RF: register_file 
    port map(
      clk => clk,
      rst => rst,
      RegWr => mem_wb_reg_write,
      Rw => mem_wb_write_reg,
      Ra => rs,
      Rb => rt,
      busW => write_back_data,
      busA => read_data1,
      busB => read_data2,
      reg0_out => reg0,
      reg1_out => reg1,
      reg2_out => reg2,
      reg3_out => reg3,
      reg4_out => reg4,
      reg5_out => reg5,
      reg6_out => reg6,
      reg7_out => reg7
    );
  
  CTRL: control_unit 
    port map(
      opcode => opcode,
      reg_dst => reg_dst,
      jump => jump,
      branch => branch,
      mem_read => mem_read,
      mem_to_reg => mem_to_reg,
      ALU_OP => alu_op,
      mem_write => mem_write,
      alu_src => alu_src,
      reg_write => reg_write
    );
  
  jump_taken <= jump;
  
  ID_EX: ID_EX_reg 
    port map(
      clk => clk,
      rst => rst,
      stall => stall,
      flush => flush_id_ex,
      reg_write_in => reg_write,
      mem_to_reg_in => mem_to_reg,
      mem_write_in => mem_write,
      mem_read_in => mem_read,
      branch_in => branch,
      alu_src_in => alu_src,
      reg_dst_in => reg_dst,
      alu_op_in => alu_op,
      pc_in => if_id_pc,
      read_data1_in => read_data1,
      read_data2_in => read_data2,
      imm_in => imm_extended,
      rs_in => rs,
      rt_in => rt,
      rd_in => rd,
      opcode_in => opcode_for_alu,
      shamt_in => shamt,


      reg_write_out => id_ex_reg_write,
      mem_to_reg_out => id_ex_mem_to_reg,
      mem_write_out => id_ex_mem_write,
      mem_read_out => id_ex_mem_read,
      branch_out => id_ex_branch,
      alu_src_out => id_ex_alu_src,
      reg_dst_out => id_ex_reg_dst,
      alu_op_out => id_ex_alu_op,
      pc_out => id_ex_pc,
      read_data1_out => id_ex_rd1,
      read_data2_out => id_ex_rd2,
      imm_out => id_ex_imm,
      rs_out => id_ex_rs,
      rt_out => id_ex_rt,
      rd_out => id_ex_rd,
      opcode_out => id_ex_opcode,
      shamt_out => id_ex_shamt
    );
  
  with forward_a select forwarded_a <=
    id_ex_rd1 when "00",
    write_back_data when "01",
    ex_mem_alu_result when "10",
    (others => '0') when others;
    
  with forward_b select forwarded_b <=
    id_ex_rd2 when "00",
    write_back_data when "01",
    ex_mem_alu_result when "10",
    (others => '0') when others;
  
  alu_input_a <= forwarded_a;
  alu_input_b <= id_ex_imm when id_ex_alu_src = '1' else forwarded_b;
  write_reg_ex <= id_ex_rd when id_ex_reg_dst = '1' else id_ex_rt;
  
  ALU_CTRL: alu_control 
    port map(
      opcode => id_ex_opcode,
      ALU_OP => id_ex_alu_op,
      ALUctr => alu_control_signal
    );
  
  ALU_UNIT: alu 
    port map(
      A => alu_input_a,
      B => alu_input_b,
      ALUctr => alu_control_signal,
      shamt => id_ex_shamt,
      Result => alu_result,
      Zero => alu_zero,
      Overflow => alu_overflow,
      Carryout => alu_carryout
    );
  
  EX_MEM: EX_MEM_reg 
    port map(
      clk => clk,
      rst => rst,
      reg_write_in => id_ex_reg_write,
      mem_to_reg_in => id_ex_mem_to_reg,
      mem_write_in => id_ex_mem_write,
      mem_read_in => id_ex_mem_read,
      branch_in => id_ex_branch,
      alu_result_in => alu_result,
      write_data_in => id_ex_rd2,
      write_reg_in => write_reg_ex,
      zero_in => alu_zero,
      branch_addr_in => branch_target,
      reg_write_out => ex_mem_reg_write,
      mem_to_reg_out => ex_mem_mem_to_reg,
      mem_write_out => ex_mem_mem_write,
      mem_read_out => ex_mem_mem_read,
      branch_out => ex_mem_branch,
      alu_result_out => ex_mem_alu_result,
      write_data_out => ex_mem_write_data,
      write_reg_out => ex_mem_write_reg,
      zero_out => ex_mem_zero,
      branch_addr_out => ex_mem_branch_addr
    );
  
  DMEM: data_memory 
    port map(
      clk => clk,
      address => ex_mem_alu_result,
      write_data => ex_mem_write_data,
      mem_write => ex_mem_mem_write,
      mem_read => ex_mem_mem_read,
      read_data => mem_read_data
    );
  
  MEM_WB: MEM_WB_reg 
    port map(
      clk => clk,
      rst => rst,
      reg_write_in => ex_mem_reg_write,
      mem_to_reg_in => ex_mem_mem_to_reg,
      mem_data_in => mem_read_data,
      alu_result_in => ex_mem_alu_result,
      write_reg_in => ex_mem_write_reg,
      reg_write_out => mem_wb_reg_write,
      mem_to_reg_out => mem_wb_mem_to_reg,
      mem_data_out => mem_wb_mem_data,
      alu_result_out => mem_wb_alu_result,
      write_reg_out => mem_wb_write_reg
    );
  
  write_back_data <= mem_wb_mem_data when mem_wb_mem_to_reg = '1' 
                     else mem_wb_alu_result;
  
HAZARD: hazard_unit 
  port map(
    -- ID stage regs (for load-use stall)
    rs_id        => rs,
    rt_id        => rt,
    -- EX stage regs (for forwarding)
    rs_ex        => id_ex_rs,
    rt_ex        => id_ex_rt,
    -- dest registers / control
    write_reg_ex => write_reg_ex,
    mem_read_ex  => id_ex_mem_read,
    reg_write_ex => id_ex_reg_write,
    write_reg_mem=> ex_mem_write_reg,
    reg_write_mem=> ex_mem_reg_write,
    write_reg_wb => mem_wb_write_reg,
    reg_write_wb => mem_wb_reg_write,
    branch_taken => branch_taken,
    jump_taken   => jump_taken,
    stall        => stall,
    flush_if_id  => flush_if_id,
    flush_id_ex  => flush_id_ex,
    forward_a    => forward_a,
    forward_b    => forward_b
  );

  
  pc_out <= pc;
    -- DEBUG PORT ASSIGNMENTS (for testbench visibility only)
  dbg_if_id_instr      <= if_id_instr;
  dbg_id_ex_opcode     <= id_ex_opcode;
  dbg_ex_mem_alu_res   <= ex_mem_alu_result;
  dbg_mem_wb_write_reg <= mem_wb_write_reg;


end architecture rtl;