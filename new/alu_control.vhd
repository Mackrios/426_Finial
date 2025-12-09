library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- ALU_OP encoding:
--   "00"ADD (lw, sw, addi)
--   "01" SUB (branch compares)
--   "10" R-type (use funct)

-- Function field (funct) encoding (from instruction[2:0]):
--   ADD = 000
--   SUB = 001
--   SLL = 010
--   OR  = 011
--   SRL = 101
--   SRA = 110
--   XOR = 111

-- ALUctr output encoding (must match alu.vhd):
--   0000 = ADD
--   0001 = SUB
--   0011 = OR
--   0100 = XOR
--   0101 = SLL
--   0110 = SRL
--   0111 = SRA

entity alu_control is
  port(
    opcode    : in  unsigned(3 downto 0);  -- Contains funct field for R-type
    ALU_OP    : in  unsigned(1 downto 0);  -- From main control
    ALUctr    : out unsigned(3 downto 0)
  );
end entity;

architecture rtl of alu_control is
begin
  process(opcode, ALU_OP)
  begin
    case ALU_OP is

      ------------------------------------------------------------------
      -- 00 = ADD (lw, sw, addi)
      ------------------------------------------------------------------
      when "00" =>
        ALUctr <= "0000";

      ------------------------------------------------------------------
      -- 01 = SUB (branches)
      ------------------------------------------------------------------
      when "01" =>
        ALUctr <= "0001";

      ------------------------------------------------------------------
      -- 10 = R-TYPE (decode funct field)
      ------------------------------------------------------------------
      when "10" =>
        case opcode(2 downto 0) is      -- funct field
          when "000" =>  -- ADD
            ALUctr <= "0000";

          when "001" =>  -- SUB
            ALUctr <= "0001";

          when "010" =>  -- SLL
            ALUctr <= "0101";

          when "011" =>  -- OR
            ALUctr <= "0011";

          when "101" =>  -- SRL
            ALUctr <= "0110";

          when "110" =>  -- SRA
            ALUctr <= "0111";

          when "111" =>  -- XOR
            ALUctr <= "0100";

          when others =>
            ALUctr <= "0000";  -- default ADD
        end case;

      ------------------------------------------------------------------
      -- default
      ------------------------------------------------------------------
      when others =>
        ALUctr <= "0000";
    end case;
  end process;
end architecture;
