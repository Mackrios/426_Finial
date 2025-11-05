library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dmem is
  port(
    clk       : in  std_logic;
    addr      : in  unsigned(15 downto 0);
    writeData : in  unsigned(15 downto 0);
    memRead   : in  std_logic;
    memWrite  : in  std_logic;
    readData  : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of dmem is
  type ram_array is array (0 to 255) of unsigned(15 downto 0);
  signal RAM : ram_array := (others => (others => '0'));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if memWrite = '1' then
        RAM(to_integer(addr(15 downto 1))) <= writeData;
      end if;
    end if;
  end process;

  readData <= RAM(to_integer(addr(15 downto 1))) when memRead = '1' else (others => '0');
end architecture;

