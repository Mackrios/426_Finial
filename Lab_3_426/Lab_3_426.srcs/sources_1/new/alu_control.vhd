library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu_control is
  port(
    opcode    : in  unsigned(3 downto 0);   -- Instruction opcode
    ALU_OP    : in  unsigned(1 downto 0);   -- From main control unit
    ALUctr    : out unsigned(3 downto 0)    -- To ALU
  );
end entity;

architecture rtl of alu_control is
begin
  process(opcode, ALU_OP)
  begin
    -- Default
    ALUctr <= "0000";
    
    case ALU_OP is
      when "00" =>  -- Memory operations (LW/SW/ADDI) - always ADD
        ALUctr <= "0000";
        
      when "01" =>  -- Branch operations - always SUB for comparison
        ALUctr <= "0001";
        
      when "10" =>  -- R-type - use opcode to find op
        case opcode is
          when "0000" =>  -- ADD
            ALUctr <= "0000";
          when "0001" =>  -- SUB  
            ALUctr <= "0001";
          when "0010" =>  -- AND
            ALUctr <= "0010";
          when "0011" =>  -- OR
            ALUctr <= "0011";
          when "0100" =>  -- SLL
            ALUctr <= "0101";
          when "0101" =>  -- SRL
            ALUctr <= "0110";
          when "0110" =>  -- SRA
            ALUctr <= "0111";
          when "0111" =>  -- XOR
            ALUctr <= "0100";
          when others =>
            ALUctr <= "0000";
        end case;
        
      when others =>
        ALUctr <= "0000";
    end case;
  end process;
end architecture;
