library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- ============================================================================
-- IF/ID Pipeline Register
-- ============================================================================
entity IF_ID_reg is
  port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    stall       : in  std_logic;
    flush       : in  std_logic;
    pc_in       : in  unsigned(15 downto 0);
    instr_in    : in  unsigned(15 downto 0);
    pc_out      : out unsigned(15 downto 0);
    instr_out   : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of IF_ID_reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      pc_out    <= (others => '0');
      instr_out <= (others => '0');

    elsif rising_edge(clk) then

      if flush = '1' then
        instr_out <= (others => '0');

      elsif stall = '0' then
        pc_out    <= pc_in;
        instr_out <= instr_in;
      end if;
    end if;
  end process;
end architecture;


-- ============================================================================
-- ID/EX Pipeline Register
-- ============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity ID_EX_reg is
  port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    stall       : in  std_logic;
    flush       : in  std_logic;
    -- Control signals in
    reg_write_in   : in  std_logic;
    mem_to_reg_in  : in  std_logic;
    mem_write_in   : in  std_logic;
    mem_read_in    : in  std_logic;
    branch_in      : in  std_logic;
    alu_op_in      : in  unsigned(1 downto 0);
    alu_src_in     : in  std_logic;
    reg_dst_in     : in  std_logic;
    -- Data in
    pc_in          : in  unsigned(15 downto 0);
    read_data1_in  : in  unsigned(15 downto 0);
    read_data2_in  : in  unsigned(15 downto 0);
    imm_in         : in  unsigned(15 downto 0);
    rs_in          : in  unsigned(2 downto 0);
    rt_in          : in  unsigned(2 downto 0);
    rd_in          : in  unsigned(2 downto 0);
    opcode_in      : in  unsigned(3 downto 0);
    shamt_in       : in  unsigned(2 downto 0);
    -- Control signals out
    reg_write_out  : out std_logic;
    mem_to_reg_out : out std_logic;
    mem_write_out  : out std_logic;
    mem_read_out   : out std_logic;
    branch_out     : out std_logic;
    alu_op_out     : out unsigned(1 downto 0);
    alu_src_out    : out std_logic;
    reg_dst_out    : out std_logic;
    -- Data out
    pc_out         : out unsigned(15 downto 0);
    read_data1_out : out unsigned(15 downto 0);
    read_data2_out : out unsigned(15 downto 0);
    imm_out        : out unsigned(15 downto 0);
    rs_out         : out unsigned(2 downto 0);
    rt_out         : out unsigned(2 downto 0);
    rd_out         : out unsigned(2 downto 0);
    opcode_out     : out unsigned(3 downto 0);
    shamt_out      : out unsigned(2 downto 0)
  );
end entity;

architecture rtl of ID_EX_reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      reg_write_out <= '0';
      mem_to_reg_out <= '0';
      mem_write_out <= '0';
      mem_read_out <= '0';
      branch_out <= '0';
      alu_op_out <= "00";
      alu_src_out <= '0';
      reg_dst_out <= '0';
      pc_out <= (others => '0');
      read_data1_out <= (others => '0');
      read_data2_out <= (others => '0');
      imm_out <= (others => '0');
      rs_out <= (others => '0');
      rt_out <= (others => '0');
      rd_out <= (others => '0');
      opcode_out <= "0000";
      shamt_out <= "000";

    elsif rising_edge(clk) then

      if flush = '1' then
        -- COMPLETE NOP (bubble)
        reg_write_out <= '0';
        mem_to_reg_out <= '0';
        mem_write_out <= '0';
        mem_read_out <= '0';
        branch_out <= '0';
        alu_op_out <= (others => '0');
        alu_src_out <= '0';
        reg_dst_out <= '0';
        pc_out <= (others => '0');
        read_data1_out <= (others => '0');
        read_data2_out <= (others => '0');
        imm_out <= (others => '0');
        rs_out <= (others => '0');
        rt_out <= (others => '0');
        rd_out <= (others => '0');
        opcode_out <= (others => '0');
        shamt_out <= (others => '0');

      elsif stall = '0' then
        -- normal update
        reg_write_out <= reg_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        mem_write_out <= mem_write_in;
        mem_read_out <= mem_read_in;
        branch_out <= branch_in;
        alu_op_out <= alu_op_in;
        alu_src_out <= alu_src_in;
        reg_dst_out <= reg_dst_in;
        pc_out <= pc_in;
        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        imm_out <= imm_in;
        rs_out <= rs_in;
        rt_out <= rt_in;
        rd_out <= rd_in;
        opcode_out <= opcode_in;
        shamt_out <= shamt_in;
      end if;

    end if;
  end process;
end architecture;


-- ============================================================================
-- EX/MEM Pipeline Register
-- ============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity EX_MEM_reg is
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    -- Control signals in
    reg_write_in   : in  std_logic;
    mem_to_reg_in  : in  std_logic;
    mem_write_in   : in  std_logic;
    mem_read_in    : in  std_logic;
    branch_in      : in  std_logic;
    -- Data in
    alu_result_in  : in  unsigned(15 downto 0);
    write_data_in  : in  unsigned(15 downto 0);
    write_reg_in   : in  unsigned(2 downto 0);
    zero_in        : in  std_logic;
    branch_addr_in : in  unsigned(15 downto 0);
    -- Control signals out
    reg_write_out  : out std_logic;
    mem_to_reg_out : out std_logic;
    mem_write_out  : out std_logic;
    mem_read_out   : out std_logic;
    branch_out     : out std_logic;
    -- Data out
    alu_result_out : out unsigned(15 downto 0);
    write_data_out : out unsigned(15 downto 0);
    write_reg_out  : out unsigned(2 downto 0);
    zero_out       : out std_logic;
    branch_addr_out: out unsigned(15 downto 0)
  );
end entity;

architecture rtl of EX_MEM_reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      reg_write_out <= '0';
      mem_to_reg_out <= '0';
      mem_write_out <= '0';
      mem_read_out <= '0';
      branch_out <= '0';
      alu_result_out <= (others => '0');
      write_data_out <= (others => '0');
      write_reg_out <= (others => '0');
      zero_out <= '0';
      branch_addr_out <= (others => '0');
    elsif rising_edge(clk) then
      reg_write_out <= reg_write_in;
      mem_to_reg_out <= mem_to_reg_in;
      mem_write_out <= mem_write_in;
      mem_read_out <= mem_read_in;
      branch_out <= branch_in;
      alu_result_out <= alu_result_in;
      write_data_out <= write_data_in;
      write_reg_out <= write_reg_in;
      zero_out <= zero_in;
      branch_addr_out <= branch_addr_in;
    end if;
  end process;
end architecture;

-- ============================================================================
-- MEM/WB Pipeline Register
-- ============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity MEM_WB_reg is
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    -- Control signals in
    reg_write_in   : in  std_logic;
    mem_to_reg_in  : in  std_logic;
    -- Data in
    mem_data_in    : in  unsigned(15 downto 0);
    alu_result_in  : in  unsigned(15 downto 0);
    write_reg_in   : in  unsigned(2 downto 0);
    -- Control signals out
    reg_write_out  : out std_logic;
    mem_to_reg_out : out std_logic;
    -- Data out
    mem_data_out   : out unsigned(15 downto 0);
    alu_result_out : out unsigned(15 downto 0);
    write_reg_out  : out unsigned(2 downto 0)
  );
end entity;

architecture rtl of MEM_WB_reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      reg_write_out <= '0';
      mem_to_reg_out <= '0';
      mem_data_out <= (others => '0');
      alu_result_out <= (others => '0');
      write_reg_out <= (others => '0');
    elsif rising_edge(clk) then
      reg_write_out <= reg_write_in;
      mem_to_reg_out <= mem_to_reg_in;
      mem_data_out <= mem_data_in;
      alu_result_out <= alu_result_in;
      write_reg_out <= write_reg_in;
    end if;
  end process;
end architecture;