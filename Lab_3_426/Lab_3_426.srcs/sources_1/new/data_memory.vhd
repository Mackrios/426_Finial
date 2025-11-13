library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity data_memory is
  port(
    clk        : in  std_logic;
    address    : in  unsigned(15 downto 0);
    write_data : in  unsigned(15 downto 0);
    mem_write  : in  std_logic;
    mem_read   : in  std_logic;
    read_data  : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of data_memory is
  type mem_array is array(0 to 255) of unsigned(15 downto 0);
  
  -- Memory layout:
  -- mem[0-3]     = 0x0000 (unused)
  -- mem[4-6]     = Constants (0x0100, 0x00FF, 0xFF00)
  -- mem[7-15]    = 0x0000 (unused)
  -- mem[16-25]   = Results storage area (will be filled by program)
  -- mem[26-255]  = 0x0000 (unused)
  
  signal mem : mem_array := (
    -- Constants at addresses 4, 5, 6
    -- These are loaded by: lw $r6, 4($r0)  etc.
    4  => x"0100",  -- Comparison threshold (for BGT instruction)
    5  => x"00FF",  -- ELSE branch value (00FF for left shift + XOR)
    6  => x"FF00",  -- THEN branch value (FF00 for right shift + OR)
    
    -- Results storage area (word addresses 16-25)
    -- These will be written to by SW instructions
    -- Starting address R1 = 0x0020 (byte) ? word index 16
    16 => x"0000",  -- Reserved for program results
    17 => x"0000",
    18 => x"0000",
    19 => x"0000",
    20 => x"0000",
    21 => x"0000",
    22 => x"0000",
    23 => x"0000",
    24 => x"0000",
    25 => x"0000",
    
    others => (others => '0')
  );
  
begin
  -- Synchronous write
  process(clk)
  begin
    if rising_edge(clk) then
      if mem_write = '1' then
        mem(to_integer(address(7 downto 1))) <= write_data;
      end if;
    end if;
  end process;
  
  -- Asynchronous read
  read_data <= mem(to_integer(address(7 downto 1))) when mem_read = '1' 
               else (others => '0');
end architecture;