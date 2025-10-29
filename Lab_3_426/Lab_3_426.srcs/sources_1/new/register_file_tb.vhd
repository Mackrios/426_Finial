library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity register_file_tb is
end entity;

architecture test of register_file_tb is
  component register_file
    port(
      clk       : in  std_logic;
      RegWr     : in  std_logic;
      Rw, Ra, Rb: in  unsigned(4 downto 0);
      busW      : in  unsigned(31 downto 0);
      busA, busB: out unsigned(31 downto 0)
    );
  end component;

  signal s_clk    : std_logic := '0';
  signal s_RegWr  : std_logic := '0';
  signal s_Rw, s_Ra, s_Rb: unsigned(4 downto 0):= (others => ('0'));
  signal s_busW, s_busA, s_busB: unsigned(31 downto 0):= (others => ('0'));

  constant clk_period : time := 10 ns;
begin
  UUT: register_file port map(clk => s_clk, RegWr => s_RegWr, Rw => s_Rw, Ra => s_Ra, Rb => s_Rb, busW => s_busW, busA => s_busA, busB => s_busB);

  s_clk <= not s_clk after clk_period/2;
  process
  begin
    -- 123 to R5
    s_RegWr <= '1';
    s_Rw <= to_unsigned(5, 5);
    s_busW <= to_unsigned(123, 32);
    wait for clk_period;
    
    -- 456 to R10
    s_Rw <= to_unsigned(10, 5);
    s_busW <= to_unsigned(456, 32);
    wait for clk_period;
    
    --stop write and read 
    s_RegWr <= '0';
    s_Ra <= to_unsigned(5, 5);
    s_Rb <= to_unsigned(10, 5);
    wait for clk_period;

    
    s_Ra <= to_unsigned(1, 5);
    s_Rb <= to_unsigned(2, 5);
    wait for clk_period;
    wait;
  end process;
end architecture;