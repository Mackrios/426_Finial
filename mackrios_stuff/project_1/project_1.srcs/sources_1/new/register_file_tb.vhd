library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity register_file_tb is
end entity;

architecture test of register_file_tb is

  component register_file
    port(
      clk       : in  std_logic;
      rst       : in  std_logic;
      RegWr     : in  std_logic;
      Rw, Ra, Rb: in  unsigned(2 downto 0);
      busW      : in  unsigned(15 downto 0);
      busA, busB: out unsigned(15 downto 0)
    );
  end component;
  
  signal clk : std_logic := '0';
  signal rst, RegWr : std_logic := '0';
  signal Rw, Ra, Rb : unsigned(2 downto 0) := (others => '0');
  signal busW, busA, busB : unsigned(15 downto 0) := (others => '0');
  
  constant CLK_PERIOD : time := 10 ns;
  
begin
  UUT: register_file
    port map(
      clk    => clk,
      rst    => rst,
      RegWr  => RegWr,
      Rw     => Rw,
      Ra     => Ra,
      Rb     => Rb,
      busW   => busW,
      busA   => busA,
      busB   => busB
    );
  
  clk_process: process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;
  
  test_process: process
  begin
    report "Starting Register File Testbench...";

    -- Test 1
    report "Test 1: Reset and Initial Values";
    rst <= '1'; wait for CLK_PERIOD;
    rst <= '0'; wait for CLK_PERIOD;

    -- Test 2
    report "Test 2: Verify Initial Register Values";
    Ra <= "000"; Rb <= "001"; wait for 5 ns;
    assert busA = to_unsigned(16#0040#, 16) report "$r0 init failed!" severity error;
    assert busB = to_unsigned(16#1010#, 16) report "$r1 init failed!" severity error;
    report "$r0 = 0x" & integer'image(to_integer(busA)) &
           ", $r1 = 0x" & integer'image(to_integer(busB));

    Ra <= "010"; Rb <= "011"; wait for 5 ns;
    assert busA = to_unsigned(16#000F#, 16) report "$r2 init failed!" severity error;
    assert busB = to_unsigned(16#00F0#, 16) report "$r3 init failed!" severity error;
    report "$r2 = 0x" & integer'image(to_integer(busA)) &
           ", $r3 = 0x" & integer'image(to_integer(busB));

    Ra <= "100"; Rb <= "101"; wait for 5 ns;
    assert busA = to_unsigned(16#0000#, 16) report "$r4 init failed!" severity error;
    assert busB = to_unsigned(16#0010#, 16) report "$r5 init failed!" severity error;
    report "$r4 = 0x" & integer'image(to_integer(busA)) &
           ", $r5 = 0x" & integer'image(to_integer(busB));

    Ra <= "110"; Rb <= "111"; wait for 5 ns;
    assert busA = to_unsigned(16#0005#, 16) report "$r6 init failed!" severity error;
    assert busB = to_unsigned(16#0000#, 16) report "$r7 init failed!" severity error;
    report "$r6 = 0x" & integer'image(to_integer(busA)) &
           ", $r7 = 0x" & integer'image(to_integer(busB));

    -- Test 3
    report "Test 3: Write to Register $r3";
    Rw <= "011";
    busW <= to_unsigned(16#1234#, 16);
    RegWr <= '1'; wait for CLK_PERIOD;
    RegWr <= '0';

    Ra <= "011"; wait for 5 ns;
    assert busA = to_unsigned(16#1234#, 16) report "Write to $r3 failed!" severity error;
    report "$r3 written: 0x" & integer'image(to_integer(busA));

    -- Test 4
    report "Test 4: Simultaneous Read";
    Ra <= "000"; Rb <= "001"; wait for 5 ns;
    assert busA = to_unsigned(16#0040#, 16) and busB = to_unsigned(16#1010#, 16)
      report "Simultaneous read failed!" severity error;
    report "Read $r0 and $r1: 0x" &
           integer'image(to_integer(busA)) & ", 0x" &
           integer'image(to_integer(busB));

    -- Test 5
    report "Test 5: Write Multiple Registers";
    RegWr <= '1';
    for i in 0 to 7 loop
      Rw <= to_unsigned(i, 3);
      busW <= to_unsigned(i * 16#100#, 16);
      wait for CLK_PERIOD;
    end loop;
    RegWr <= '0';

    for i in 0 to 7 loop
      Ra <= to_unsigned(i, 3); wait for 5 ns;
      assert busA = to_unsigned(i * 16#100#, 16)
        report "Multi-write verification failed!" severity error;
      report "$r" & integer'image(i) &
             " = 0x" & integer'image(to_integer(busA));
    end loop;

    -- Test 6
    report "Test 6: Write Without Enable";
    Ra <= "010"; wait for 5 ns;
    busW <= to_unsigned(16#9999#, 16);
    Rw <= "010";
    RegWr <= '0';
    wait for CLK_PERIOD;

    Ra <= "010"; wait for 5 ns;
    assert busA /= to_unsigned(16#9999#, 16) report "Write occurred without enable!" severity error;
    report "Write correctly blocked when RegWr=0";

    -- Test 7
    report "Test 7: Phase 1 Test Program Operations";
    rst <= '1'; wait for CLK_PERIOD;
    rst <= '0'; wait for CLK_PERIOD;

    Ra <= "110"; wait for 5 ns;
    report "$a1 initial = " & integer'image(to_integer(busA));

    Rw <= "110";
    busW <= busA - 1;
    RegWr <= '1'; wait for CLK_PERIOD;
    RegWr <= '0';

    Ra <= "110"; wait for 5 ns;
    assert busA = to_unsigned(4, 16) report "$a1 decrement failed!" severity error;
    report "$a1 after decrement = " & integer'image(to_integer(busA));

    report "Register File Testbench Complete!";
    wait;
  end process;

end architecture;
