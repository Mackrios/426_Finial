library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_level_wrapper is
end entity;

architecture rtl of top_level_wrapper is
  -- Signals to drive the top-level
  signal clk_sig      : std_logic := '0';
  signal RegWr_sig    : std_logic := '0';
  signal Rd_sig, Rs_sig, Rt_sig : unsigned(4 downto 0) := (others => '0');
  signal ALUctr_sig   : unsigned(2 downto 0) := "000";
  signal Zero_sig, Overflow_sig, Carryout_sig : std_logic := '0';
  signal Result_sig   : unsigned(31 downto 0) := (others => '0');
begin

  -- Instantiate your top_level
  DUT: entity work.top_level(rtl)
    port map(
      clk       => clk_sig,
      RegWr     => RegWr_sig,
      Rd        => Rd_sig,
      Rs        => Rs_sig,
      Rt        => Rt_sig,
      ALUctr    => ALUctr_sig,
      Zero      => Zero_sig,
      Overflow  => Overflow_sig,
      Carryout  => Carryout_sig,
      Result    => Result_sig
    );

  -- Simple clock toggle
  clk_process : process
  begin
    while true loop
      clk_sig <= '0';
      wait for 20 ns;
      clk_sig <= '1';
      wait for 20 ns;
    end loop;
  end process;

  -- Tie inputs to constants for now
  RegWr_sig <= '0';         -- disable writes
  Rd_sig    <= "00010";     -- example
  Rs_sig    <= "00010";     -- R2
  Rt_sig    <= "00011";     -- R3
  ALUctr_sig <= "000";      -- ADD
end architecture;
