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
  -- 0..3 unused
  16  => x"0000",
  17  => x"0100",
  18  => x"00FF",
  19  => x"FF00",

  -- constants region (if you still want 0x0100, 0x00FF, 0xFF00 here)
  20  => x"0101",  -- threshold
  21  => x"0110",  -- else store value
  22  => x"0011",  -- then store value

  -- test data starting at $a0 = 0x0010
  23  => x"00F0",  -- Mem[$a0]
  24  => x"00FF",  -- Mem[$a0+2]
  --10 => x"0011",  -- Mem[$a0+4]
  --11 => x"00F0",  -- Mem[$a0+6]
  --12 => x"00FF",  -- Mem[$a0+8]

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