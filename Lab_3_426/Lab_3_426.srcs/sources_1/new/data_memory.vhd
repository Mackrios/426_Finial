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
    -- 0x0000 - 0x0006: unused / zero
    0  => x"0000",
    1  => x"0000",
    2  => x"0000",
    3  => x"0000",

    -- Constants used by the program (accessed via LW with byte offsets):
    -- byte offset 8  -> word index 4
    -- byte offset 10 -> word index 5
    -- byte offset 12 -> word index 6
    4  => x"0100",   -- comparison threshold
    5  => x"00FF",   -- "else" store value
    6  => x"FF00",   -- "then" store value

    -- 0x000E..0x001E etc. (everything else default to 0)
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