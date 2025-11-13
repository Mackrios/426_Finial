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
    -- CORRECTED FOR MEMORY STORAGE AT mem[16-25]
    -- R0 = base address for loading constants from mem[4-6]
    0 => x"0000",  -- R0 = 0x0000 (base for constant loads)
    
    -- R1 = base address for storing results to mem[16-25]
    -- Byte address 0x0020 maps to word index 16
    -- address(7 downto 1) extracts: 0x0020[7:1] = 16
    1 => x"0020",  -- R1 = 0x0020 (CRITICAL: points to mem[16])
    
    2 => x"000F",  -- R2 = 0x000F (loop counter, 15 iterations)
    3 => x"00F0",  -- R3 = 0x00F0 (V1 - will be modified)
    4 => x"0000",  -- R4 = 0x0000 (T0 - temp for loads)
    5 => x"0010",  -- R5 = 0x0010 (V2 - will be modified)
    6 => x"0005",  -- R6 = 0x0005 (V3 - comparison/temp)
    7 => x"0000"   -- R7 = 0x0000 (temp for stores)
  );
  
begin
  
  process(clk, rst)
  begin
    if rst = '1' then
      Regs(0) <= x"0000";
      Regs(1) <= x"0020";  -- KEY: Byte address for mem[16]
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