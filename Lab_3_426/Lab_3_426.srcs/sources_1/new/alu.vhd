library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
  port(
    A, B      : in  unsigned(31 downto 0);
    ALUctr    : in  unsigned(2 downto 0);
    Result    : out unsigned(31 downto 0);
    Zero, Overflow, Carryout : out std_logic
  );
end entity;

architecture rtl of alu is

  signal adder_B     : unsigned(31 downto 0);
  signal adder_Cin   : std_logic;
  signal adder_Sum   : unsigned(31 downto 0);
  signal adder_Cout  : std_logic;
  signal mult_Result : unsigned(31 downto 0);
  signal mult_Overflow : std_logic;

  component adder_32bit
    port(
      A, B : in  unsigned(31 downto 0);
      Cin  : in  std_logic;
      Sum  : out unsigned(31 downto 0);
      Cout : out std_logic
    );
  end component;

  component multp
    port(
      A, B     : in  unsigned(31 downto 0);
      Result   : out unsigned(31 downto 0);
      Overflow : out std_logic
    );
  end component;

begin

  adder_B   <= not B when ALUctr = "001" else B;
  adder_Cin <= '1'   when ALUctr = "001" else '0';

  ADDER_INST: adder_32bit
    port map(
      A    => A,
      B    => adder_B,
      Cin  => adder_Cin,
      Sum  => adder_Sum,
      Cout => adder_Cout
    );

  MULT_INST: multp
    port map(
      A        => A,
      B        => B,
      Result   => mult_Result,
      Overflow => mult_Overflow
    );

  process(A, B, ALUctr, adder_Sum, adder_Cout, mult_Result, mult_Overflow)
    variable temp_result : unsigned(31 downto 0);
  begin
    Overflow <= '0';
    Carryout <= '0';

    case ALUctr is
      when "000" =>  -- ADD
        temp_result := adder_Sum;
        Carryout    <= adder_Cout;
        if (A(31) = B(31)) and (adder_Sum(31) /= A(31)) then
          Overflow <= '1';
        end if;

      when "001" =>  -- SUB
        temp_result := adder_Sum;
        Carryout    <= adder_Cout;
        if (A(31) /= B(31)) and (adder_Sum(31) /= A(31)) then
          Overflow <= '1';
        end if;

      when "010" =>  -- AND
        temp_result := A and B;

      when "011" =>  -- OR
        temp_result := A or B;

      when "100" =>  -- logical left shift
        temp_result := shift_left(A, 1);

      when "101" =>  -- logical right shift
        temp_result := shift_right(A, 1);

      when "110" =>  -- MULTIPLY (from multp)
        temp_result := mult_Result;
        Overflow <= mult_Overflow;

      when "111" =>  -- arithmetic right shift
        temp_result := unsigned(shift_right(signed(A), 1));

      when others =>
        temp_result := (others => '0');
    end case;

    Result <= temp_result;

    if temp_result = to_unsigned(0, temp_result'length) then
      Zero <= '1';
    else
      Zero <= '0';
    end if;
  end process;

end architecture;
