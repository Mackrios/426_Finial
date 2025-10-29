library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
  port(
    A, B      : in  unsigned(15 downto 0);  
    ALUctr    : in  unsigned(3 downto 0);   
    shamt     : in  unsigned(2 downto 0);   
    Result    : out unsigned(15 downto 0);  
    Zero      : out std_logic;              
    Overflow  : out std_logic;              
    Carryout  : out std_logic               
  );
end entity;

architecture rtl of alu is
  signal adder_B     : unsigned(15 downto 0);
  signal adder_Cin   : std_logic;
  signal adder_Sum   : unsigned(15 downto 0);
  signal adder_Cout  : std_logic;
  
  component adder_16bit
    port(
      A, B : in  unsigned(15 downto 0);
      Cin  : in  std_logic;
      Sum  : out unsigned(15 downto 0);
      Cout : out std_logic
    );
  end component;

begin
  adder_B   <= not B when ALUctr = "0001" else B;
  adder_Cin <= '1'   when ALUctr = "0001" else '0';
  
  ADDER_INST: adder_16bit
    port map(
      A    => A,
      B    => adder_B,
      Cin  => adder_Cin,
      Sum  => adder_Sum,
      Cout => adder_Cout
    );

  -- Main ALU operations
  process(A, B, ALUctr, shamt, adder_Sum, adder_Cout)
    variable temp_result : unsigned(15 downto 0);
    variable shift_amount : integer;
  begin
    Overflow <= '0';
    Carryout <= '0';
    shift_amount := to_integer(shamt);
    
    case ALUctr is
      when "0000" =>  -- ADD
        temp_result := adder_Sum;
        Carryout    <= adder_Cout;
        if (A(15) = B(15)) and (adder_Sum(15) /= A(15)) then
          Overflow <= '1';
        end if;
        
      when "0001" =>  -- SUB
        temp_result := adder_Sum;
        Carryout    <= adder_Cout;
        if (A(15) /= B(15)) and (adder_Sum(15) /= A(15)) then
          Overflow <= '1';
        end if;
        
      when "0010" =>  -- AND
        temp_result := A and B;
        
      when "0011" =>  -- OR
        temp_result := A or B;
        
      when "0100" =>  -- XOR
        temp_result := A xor B;
        
      when "0101" =>  -- SLL (Shift Left Logical)
        temp_result := shift_left(A, shift_amount);
        
      when "0110" =>  -- SRL (Shift Right Logical)
        temp_result := shift_right(A, shift_amount);
        
      when "0111" =>  -- SRA (Shift Right Arithmetic)
        temp_result := unsigned(shift_right(signed(A), shift_amount));
        
      when "1000" =>  -- SLT (Set Less Than - signed)
        if signed(A) < signed(B) then
          temp_result := to_unsigned(1, 16);
        else
          temp_result := to_unsigned(0, 16);
        end if;
        
      when "1001" =>  -- SLTU (Set Less Than Unsigned)
        if A < B then
          temp_result := to_unsigned(1, 16);
        else
          temp_result := to_unsigned(0, 16);
        end if;
        
      when "1010" =>  -- NOR
        temp_result := A nor B;
        
      when others =>
        temp_result := (others => '0');
    end case;
    
    Result <= temp_result;
    
    -- Zero flag
    if temp_result = to_unsigned(0, 16) then
      Zero <= '1';
    else
      Zero <= '0';
    end if;
  end process;
end architecture;