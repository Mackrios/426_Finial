library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_level is
  port(
    clk, rst : in  std_logic;
    Zero, Overflow, Carryout : out std_logic
  );
end entity;

architecture structural of top_level is
  --------------------------------------------------------------------------
  -- SIGNALS
  --------------------------------------------------------------------------
  -- PC path
  signal PC_out       : unsigned(15 downto 0);
  signal PC_in        : unsigned(15 downto 0);
  signal PCSrc_sig    : std_logic;                 -- selects external next PC
  signal pc_plus2     : unsigned(15 downto 0);

  -- Instruction
  signal instr        : unsigned(15 downto 0);

  -- Control
  signal reg_dst      : std_logic;
  signal jump         : std_logic;
  signal branch       : std_logic;
  signal mem_read     : std_logic;
  signal mem_to_reg   : std_logic;
  signal ALU_OP       : unsigned(1 downto 0);
  signal mem_write    : std_logic;
  signal alu_src      : std_logic;
  signal reg_write    : std_logic;

  -- ALU control
  signal ALUctr       : unsigned(3 downto 0);
  signal shamt        : unsigned(2 downto 0);

  -- Register file
  signal write_reg    : unsigned(2 downto 0);
  signal rs_data      : unsigned(15 downto 0);
  signal rt_data      : unsigned(15 downto 0);

  -- Immediate & branch shift
  signal imm6         : unsigned(5 downto 0);
  signal sign_ext_out : unsigned(15 downto 0);
  signal imm_sl1      : unsigned(15 downto 0);

  -- ALU datapath
  signal alu_B        : unsigned(15 downto 0);
  signal ALU_result   : unsigned(15 downto 0);

  -- ALU flags (internal)
  signal Zero_i, Overflow_i, Carryout_i : std_logic;

  -- Data memory
  signal mem_read_data : unsigned(15 downto 0);

  -- Write-back
  signal write_data    : unsigned(15 downto 0);

  -- Targets
  signal branch_target : unsigned(15 downto 0);
  signal jump_target   : unsigned(15 downto 0);

  -- small constants
  constant TWO16 : unsigned(15 downto 0) := to_unsigned(2, 16);

begin
  --------------------------------------------------------------------------
  -- PROGRAM COUNTER (internal +2 when pc_src='0', external PC_in when '1')
  --------------------------------------------------------------------------
  PC_REG: entity work.pc
    port map(
      clk    => clk,
      rst    => rst,
      pc_in  => PC_in,
      pc_src => PCSrc_sig,
      pc_out => PC_out
    );

  --------------------------------------------------------------------------
  -- INSTRUCTION MEMORY
  --------------------------------------------------------------------------
  INSTR_MEM: entity work.imem
    port map(
      addr  => PC_out,
      instr => instr
    );

  --------------------------------------------------------------------------
  -- MAIN CONTROL
  --------------------------------------------------------------------------
  CTRL: entity work.control_unit
    port map(
      opcode      => instr(15 downto 12),
      reg_dst     => reg_dst,
      jump        => jump,
      branch      => branch,
      mem_read    => mem_read,
      mem_to_reg  => mem_to_reg,
      ALU_OP      => ALU_OP,
      mem_write   => mem_write,
      alu_src     => alu_src,
      reg_write   => reg_write
    );

  --------------------------------------------------------------------------
  -- ALU CONTROL (funct/opcode-low field)
  --------------------------------------------------------------------------
  ALUCTRL: entity work.alu_control
    port map(
      opcode  => instr(3 downto 0),
      ALU_OP  => ALU_OP,
      ALUctr  => ALUctr
    );

  --------------------------------------------------------------------------
  -- REGISTER FILE
  --------------------------------------------------------------------------
  REGFILE: entity work.register_file
    port map(
      clk   => clk,
      rst   => rst,
      RegWr => reg_write,
      Rw    => write_reg,
      Ra    => instr(11 downto 9),  -- rs
      Rb    => instr(8 downto 6),   -- rt
      busW  => write_data,
      busA  => rs_data,
      busB  => rt_data
    );

  --------------------------------------------------------------------------
  -- REGDST MUX (select rd vs rt)
  --------------------------------------------------------------------------
  REGDST_MUX: entity work.mux2
    generic map(WIDTH => 3)
    port map(
      a   => instr(8 downto 6),     -- rt
      b   => instr(5 downto 3),     -- rd
      sel => reg_dst,
      y   => write_reg
    );

  --------------------------------------------------------------------------
  -- SIGN-EXTEND & SHIFT-LEFT-1 (branch offset)
  --------------------------------------------------------------------------
  imm6 <= instr(5 downto 0);

  SIGN_EXT: entity work.sign_extend
    port map(
      imm_in  => imm6,
      imm_out => sign_ext_out
    );

  SHIFT1: entity work.shift_left_1
    port map(
      in_val  => sign_ext_out,
      out_val => imm_sl1
    );

  --------------------------------------------------------------------------
  -- ALU SRC MUX (select rt_data vs sign-extended imm)
  --------------------------------------------------------------------------
  ALUSRC_MUX: entity work.mux2
    generic map(WIDTH => 16)
    port map(
      a   => rt_data,
      b   => sign_ext_out,
      sel => alu_src,
      y   => alu_B
    );

  --------------------------------------------------------------------------
  -- ALU
  --------------------------------------------------------------------------
  shamt <= instr(2 downto 0);  -- shift amount field
  ALU_CORE: entity work.alu
    port map(
      A        => rs_data,
      B        => alu_B,
      ALUctr   => ALUctr,
      shamt    => shamt,
      Result   => ALU_result,
      Zero     => Zero_i,
      Overflow => Overflow_i,
      Carryout => Carryout_i
    );

  -- drive entity outputs from internal flags (avoids reading OUT ports inside)
  Zero     <= Zero_i;
  Overflow <= Overflow_i;
  Carryout <= Carryout_i;

  --------------------------------------------------------------------------
  -- DATA MEMORY
  --------------------------------------------------------------------------
  DMEM: entity work.dmem
    port map(
      clk       => clk,
      addr      => ALU_result,
      writeData => rt_data,
      memRead   => mem_read,
      memWrite  => mem_write,
      readData  => mem_read_data
    );

  --------------------------------------------------------------------------
  -- MEM-TO-REG MUX (select ALU vs DMEM for write-back)
  --------------------------------------------------------------------------
  MEM2REG_MUX: entity work.mux2
    generic map(WIDTH => 16)
    port map(
      a   => ALU_result,
      b   => mem_read_data,
      sel => mem_to_reg,
      y   => write_data
    );

  --------------------------------------------------------------------------
  -- PC + 2 (for normal next PC and as base for branch/jump)
  --------------------------------------------------------------------------
  PC_INC: entity work.adder_16bit
    port map(
      A   => PC_out,
      B   => TWO16,
      Cin => '0',
      Sum => pc_plus2,
      Cout=> open
    );

  --------------------------------------------------------------------------
  -- BRANCH TARGET = (PC + 2) + (imm << 1)
  --------------------------------------------------------------------------
  BRANCH_ADD: entity work.adder_16bit
    port map(
      A   => pc_plus2,
      B   => imm_sl1,
      Cin => '0',
      Sum => branch_target,
      Cout=> open
    );

  -- Branch decision (classic beq-style; extend later for bgt/bge logic)
  -- Note: use internal Zero_i (not the OUT port)
  -- PCSrc_sig is only the "use external PC" selector if branch taken or jump
  PCSrc_sig <= (branch and Zero_i) or jump;

  --------------------------------------------------------------------------
  -- JUMP TARGET (use upper bits of PC+2 with instr[11:0])
  --------------------------------------------------------------------------
  jump_target <= pc_plus2(15 downto 12) & instr(11 downto 0);

  --------------------------------------------------------------------------
  -- EXTERNAL NEXT PC SELECTION WHEN PCSrc_sig = '1'
  -- (branch_target vs jump_target)
  --------------------------------------------------------------------------
  NEXTPC_MUX: entity work.mux2
    generic map(WIDTH => 16)
    port map(
      a   => branch_target,
      b   => jump_target,
      sel => jump,
      y   => PC_in
    );

end architecture;
