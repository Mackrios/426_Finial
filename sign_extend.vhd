library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sign_extend is
  port(
    imm_in  : in  unsigned(5 downto 0);
    imm_out : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of sign_extend is
begin
  process(imm_in)
  begin
    if imm_in(5) = '1' then
      imm_out <= (15 downto 6 => '1') & imm_in;
    else
      imm_out <= (15 downto 6 => '0') & imm_in;
    end if;
  end process;
end architecture;
