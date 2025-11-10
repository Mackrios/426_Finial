library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_level_tb is
end entity;

architecture test of top_level_tb is
  component top_level
    port(
      clk         : in  std_logic;
      RegWr       : in  std_logic;
      Rd, Rs, Rt: in  unsigned(4 downto 0);
      ALUctr    : in  unsigned(2 downto 0);
      Zero, Overflow, Carryout : out std_logic;
      Result    : out unsigned(31 downto 0)
    );
  end component;

  signal clk         : std_logic := '0';
  signal RegWr       : std_logic;
  signal Rd, Rs, Rt: unsigned(4 downto 0);
  signal ALUctr    : unsigned(2 downto 0);
  signal Zero, Overflow, Carryout : std_logic;
  signal Result    : unsigned(31 downto 0);

  constant clk_period : time := 10 ns;

begin
  UUT: top_level
    port map (
      clk => clk, RegWr => RegWr, Rd => Rd, Rs => Rs, Rt => Rt,
      ALUctr => ALUctr, Zero => Zero, Overflow => Overflow,
      Carryout => Carryout, Result => Result
    );

  clk_process: process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;

  stimulus: process
  begin
    RegWr <= '0';
    Rd <= (others => '0');
    Rs <= (others => '0');
    Rt <= (others => '0');
    ALUctr <= (others => '0');
    wait for 20 ns;

        report "Test 1: ADD R1 + R2 -> R3 (10 + 3 = 13)";
    Rs <= to_unsigned(1, 5);
    Rt <= to_unsigned(2, 5);
    Rd <= to_unsigned(3, 5);
    ALUctr <= "000";
    RegWr <= '1';
    wait for clk_period;
    RegWr <= '0';
    wait for 10 ns;

    report "Test 2: SUB R1 - R2 -> R4 (10 - 3 = 7)";
    Rs <= to_unsigned(1, 5);
    Rt <= to_unsigned(2, 5);
    Rd <= to_unsigned(4, 5);
    ALUctr <= "001";
    RegWr <= '1';
    wait for clk_period;
    RegWr <= '0';
    wait for 10 ns;

    report "Test 3: SLL R1 << 1 -> R5 (10 << 1 = 20)";
    Rs <= to_unsigned(1, 5);
    Rt <= (others => '0');
    Rd <= to_unsigned(5, 5);
    ALUctr <= "100";
    RegWr <= '1';
    wait for clk_period;
    RegWr <= '0';
    wait for 10 ns;
    
    -- MULT
    report "Test 4: MULT R1 * R2 -> R5 (10 * 3 = 30)";
    Rs <= to_unsigned(1, 5);
    Rt <= to_unsigned(2, 5);
    Rd <= to_unsigned(5, 5);
    ALUctr <= "110";
    RegWr <= '1';
    wait for clk_period;
    RegWr <= '0';
    wait for 10 ns;
    wait;
  end process;

end architecture;