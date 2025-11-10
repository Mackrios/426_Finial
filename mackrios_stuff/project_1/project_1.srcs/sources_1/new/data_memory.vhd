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
  
  signal mem : mem_array := (
    -- Memory starting at address 0x0010 ($a0 initial value)
    8  => x"0101",  -- $a0 (0x0010 / 2 = index 8)
    9  => x"0110",  -- $a0 + 2
    10 => x"0011",  -- $a0 + 4
    11 => x"00F0",  -- $a0 + 6
    12 => x"00FF",  -- $a0 + 8
    -- Constants at addresses 48, 50, 52
    24 => x"0100",  -- address 48 (0x0030)
    25 => x"00FF",  -- address 50 (0x0032)
    26 => x"FF00",  -- address 52 (0x0034)
    others => (others => '0')
  );
  
begin
  -- Write process (synchronous)
  process(clk)
  begin
    if rising_edge(clk) then
      if mem_write = '1' then
        mem(to_integer(address(7 downto 1))) <= write_data;
      end if;
    end if;
  end process;
  
  -- Read process (combinational)
  read_data <= mem(to_integer(address(7 downto 1))) when mem_read = '1' 
               else (others => '0');
end architecture;