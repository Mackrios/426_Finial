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
end entity;

architecture rtl of register_file is
  type reg_array is array(0 to 7) of unsigned(15 downto 0);
  
signal Regs : reg_array := (
    0 => x"0000",  -- R0 = v0
    1 => x"1010",  -- R1 = v1   
    2 => x"000F",  -- R2 = v2
    3 => x"00F0",  -- R3 = v3
    4 => x"0000",  -- R4 = t0
    5 => x"0010",  -- R5 = a0
    6 => x"0005",  -- R6 = a1
    7 => x"0000"   -- R7 = temp / can use as zero
  );
begin
  process(clk, rst)
  begin
    if rst = '1' then
      Regs(0) <= x"0040";
      Regs(1) <= x"1010";
      Regs(2) <= x"000F";
      Regs(3) <= x"00F0";
      Regs(4) <= x"0000";
      Regs(5) <= x"0010";
      Regs(6) <= x"0005";
      Regs(7) <= x"0000";

    elsif rising_edge(clk) then
      if RegWr = '1' then
        Regs(to_integer(Rw)) <= busW;
      end if;
    end if;
  end process;
  
  busA <= Regs(to_integer(Ra));
  busB <= Regs(to_integer(Rb));
  
  reg0_out <= Regs(0);
  reg1_out <= Regs(1);
  reg2_out <= Regs(2);
  reg3_out <= Regs(3);
  reg4_out <= Regs(4);
  reg5_out <= Regs(5);
  reg6_out <= Regs(6);
  reg7_out <= Regs(7);
  
end architecture;