library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity register_file is
  port(
    clk       : in  std_logic;
    rst       : in  std_logic;                 
    RegWr     : in  std_logic;                 
    Rw        : in  unsigned(2 downto 0);     
    Ra        : in  unsigned(2 downto 0);      
    Rb        : in  unsigned(2 downto 0);     
    busW      : in  unsigned(15 downto 0);     
    busA      : out unsigned(15 downto 0);     
    busB      : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of register_file is
  type reg_array is array(0 to 7) of unsigned(15 downto 0);
  
  signal Regs : reg_array := (
    0 => x"0040",  -- $r0 = $v0 = 0x0040 64 
    1 => x"1010",  -- $r1 = $v1 = 0x1010 4112
    2 => x"000F",  -- $r2 = $v2 = 0x000F 15
    3 => x"00F0",  -- $r3 = $v3 = 0x00F0 240 
    4 => x"0000",  -- $r4 = $t0 = 0x0000 temp register
    5 => x"0010",  -- $r5 = $a0 = 0x0010 memory pon at 16
    6 => x"0005",  -- $r6 = $a1 = 0x0005 loop counter 5 counts
    7 => x"0000"   -- $r7 = res
  );
  
begin
  
  process(clk, rst)
  begin
    if rst = '1' then
      Regs(0) <= x"0040";  -- $v0
      Regs(1) <= x"1010";  -- $v1
      Regs(2) <= x"000F";  -- $v2
      Regs(3) <= x"00F0";  -- $v3
      Regs(4) <= x"0000";  -- $t0
      Regs(5) <= x"0010";  -- $a0
      Regs(6) <= x"0005";  -- $a1
      Regs(7) <= x"0000";  -- res
    elsif rising_edge(clk) then
      if RegWr = '1' then
        Regs(to_integer(Rw)) <= busW;
      end if;
    end if;
  end process;
  
  busA <= Regs(to_integer(Ra));
  busB <= Regs(to_integer(Rb));
  
end architecture;