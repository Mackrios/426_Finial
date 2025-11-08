library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity multp is
  port(
    A, B     : in  unsigned(31 downto 0);
    Result   : out unsigned(31 downto 0);
    Overflow : out std_logic
  );
end entity;

architecture rtl of multp is
begin
  process(A, B)
    variable product      : unsigned(63 downto 0);
    variable multiplicand  : unsigned(63 downto 0);
    variable multiplier    : unsigned(31 downto 0);
  begin
    product := (others => '0');
    multiplicand := resize(A, 64);
    multiplier := B;

    for i in 0 to 31 loop
      if multiplier(0) = '1' then
        product := product + multiplicand;
      end if;
      multiplicand := shift_left(multiplicand, 1);
      multiplier := shift_right(multiplier, 1);
    end loop;

    Result <= product(31 downto 0);
    if product(63 downto 32) /= 0 then
      Overflow <= '1';
    else
      Overflow <= '0';
    end if;
  end process;
end architecture;
