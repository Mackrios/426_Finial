library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- CRITICAL FIX: Function field encoding must match instruction_memory.vhd
-- R-type instructions use 3-bit function field [2:0]:
--   SLL: 010 (2)
--   SRL: 101 (5) 
--   XOR: 111 (7)
--   OR:  011 (3)
--   AND: 010 (but different from SLL - needs checking)
-- The opcode input will be zero-extended function field for R-type

entity alu_control is
  port(
    opcode    : in  unsigned(3 downto 0);  -- Main opcode OR function field (for R-type)
    ALU_OP    : in  unsigned(1 downto 0);  -- from main control
    ALUctr    : out unsigned(3 downto 0)   -- To ALU
  );
end entity;

architecture rtl of alu_control is
begin
  process(opcode, ALU_OP)
  begin
    ALUctr <= "0000";  -- Default to ADD
    
    case ALU_OP is
      when "00" =>  -- LW/SW/ADDI - always ADD for address calculation
        ALUctr <= "0000";
        
      when "01" =>  -- Branch - SUB for comparison
        ALUctr <= "0001";
        
      when "10" =>  -- R-type - check function field
        -- For R-type, opcode input should contain the function field
        -- Function field is bits [2:0] of instruction
        case opcode is
          -- Match the actual function field encoding from instructions:
          when "0000" =>  -- ADD - func = 000
            ALUctr <= "0000";
          when "0001" =>  -- SUB - func = 001
            ALUctr <= "0001";
          when "0010" =>  -- SLL - func = 010
            ALUctr <= "0101";
          when "0011" =>  -- OR - func = 011
            ALUctr <= "0011";
          when "0100" =>  -- Unused
            ALUctr <= "0000";
          when "0101" =>  -- SRL - func = 101
            ALUctr <= "0110";
          when "0110" =>  -- SRA - func = 110
            ALUctr <= "0111";
          when "0111" =>  -- XOR - func = 111
            ALUctr <= "0100";
          when others =>
            ALUctr <= "0000";
        end case;
        
      when others =>
        ALUctr <= "0000";
    end case;
  end process;
end architecture;