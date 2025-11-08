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
    -- Inputs from IF stage
    pc_in       : in  unsigned(15 downto 0);
    instr_in    : in  unsigned(15 downto 0);
    -- Outputs to ID stage
    pc_out      : out unsigned(15 downto 0);
    instr_out   : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of IF_ID_reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      pc_out <= (others => '0');
      instr_out <= (others => '0');
    elsif rising_edge(clk) then
      if flush = '1' then
        pc_out <= (others => '0');
        instr_out <= (others => '0');
      elsif stall = '0' then
        pc_out <= pc_in;
        instr_out <= instr_in;
      end if;
    end if;
  end process;
end architecture;