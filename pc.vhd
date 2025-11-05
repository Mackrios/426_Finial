library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc is
  port(
    clk, rst : in  std_logic;
    pc_in    : in  unsigned(15 downto 0);   -- external next PC (branch/jump)
    pc_src   : in  std_logic;               -- select signal (0: increment, 1: external)
    pc_out   : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of pc is
  signal reg_pc : unsigned(15 downto 0) := (others => '0');
  signal next_pc : unsigned(15 downto 0);
begin
  next_pc <= reg_pc + 2 when pc_src = '0' else pc_in;

  process(clk, rst)
  begin
    if rst = '1' then
      reg_pc <= (others => '0');
    elsif rising_edge(clk) then
      reg_pc <= next_pc;
    end if;
  end process;

  pc_out <= reg_pc;
end architecture;
