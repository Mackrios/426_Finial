library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_level is
  port(
    clk      : in  std_logic;
    RegWr    : in  std_logic;
    Rd, Rs, Rt: in  unsigned(4 downto 0);
    ALUctr   : in  unsigned(2 downto 0);
    Zero, Overflow, Carryout : out std_logic;
    Result   : out unsigned(31 downto 0)
  );
end entity;

architecture rtl of top_level is

  signal busA, busB, busW : unsigned(31 downto 0) := (others => '0');
  
  component register_file
    port(
      clk      : in  std_logic;
      RegWr    : in  std_logic;
      Rw, Ra, Rb: in  unsigned(4 downto 0);
      busW     : in  unsigned(31 downto 0);
      busA, busB: out unsigned(31 downto 0)
    );
  end component;
  
  component alu
    port(
      A, B       : in  unsigned(31 downto 0);
      ALUctr     : in  unsigned(2 downto 0);
      Result     : out unsigned(31 downto 0);
      Zero, Overflow, Carryout : out std_logic
    );
  end component;
  
begin
  RF: register_file
    port map(
      clk   => clk,
      RegWr => RegWr,
      Rw    => Rd,
      Ra    => Rs,
      Rb    => Rt,
      busW  => busW,
      busA  => busA,
      busB  => busB
    );
  
  ALU_Unit: alu
    port map(
      A       => busA,
      B       => busB,
      ALUctr  => ALUctr,
      Result  => busW,
      Zero    => Zero,
      Overflow=> Overflow,
      Carryout=> Carryout
    );


  Result <= busW;

end architecture;
