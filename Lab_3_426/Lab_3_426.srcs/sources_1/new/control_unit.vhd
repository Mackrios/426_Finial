
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_unit is
  port(
    opcode      : in  unsigned(3 downto 0);   -- Instruction opcode [15:12]
    -- Control signals
    reg_dst     : out std_logic;              -- Register destination select
    jump        : out std_logic;              -- Jump control
    branch      : out std_logic;              -- Branch control
    mem_read    : out std_logic;              -- Memory read enable
    mem_to_reg  : out std_logic;              -- Memory to register
    ALU_OP      : out unsigned(1 downto 0);   -- ALU operation type
    mem_write   : out std_logic;              -- Memory write enable
    alu_src     : out std_logic;              -- ALU source select
    reg_write   : out std_logic               -- Register write enable
  );
end entity;

architecture rtl of control_unit is
begin
  process(opcode)
  begin
    -- Default values
    reg_dst    <= '0';
    jump       <= '0';
    branch     <= '0';
    mem_read   <= '0';
    mem_to_reg <= '0';
    ALU_OP     <= "00";
    mem_write  <= '0';
    alu_src    <= '0';
    reg_write  <= '0';
    
    case opcode is
      -- R-type instructions: ADD, SUB, AND, OR, SLL, SRL, SRA, XOR
      -- Opcodes: 0000, 0001, 0010, 0011, 0100, 0101, 0110, 0111
      when "0000" | "0001" | "0010" | "0011" | 
           "0100" | "0101" | "0110" | "0111" =>
        reg_dst    <= '1';  -- Write to Rd
        ALU_OP     <= "10"; -- R-type ALU operation
        reg_write  <= '1';  -- Write result to register
        alu_src    <= '0';  -- Use register for ALU source
        
      when "1000" =>  -- LW (Load Word) - Opcode 1000
        reg_dst    <= '0';  -- Write to Rt
        alu_src    <= '1';  -- Use immediate
        mem_to_reg <= '1';  -- Write memory data to register
        reg_write  <= '1';  -- Enable register write
        mem_read   <= '1';  -- Enable memory read
        ALU_OP     <= "00"; -- ADD for address calculation
        
      when "1001" =>  -- SW (Store Word) - Opcode 1001
        alu_src    <= '1';  -- Use immediate
        mem_write  <= '1';  -- Enable memory write
        ALU_OP     <= "00"; -- ADD for address calculation
        
      when "1010" =>  -- ADDI (Add Immediate) - Opcode 1010
        reg_dst    <= '0';  -- Write to Rt
        alu_src    <= '1';  -- Use immediate
        reg_write  <= '1';  -- Enable register write
        ALU_OP     <= "00"; -- ADD operation
        
      when "1011" =>  -- BEQ (Branch Equal) - Opcode 1011
        branch     <= '1';  -- Enable branch
        alu_src    <= '1';  -- Use immediate for comparison
        ALU_OP     <= "01"; -- SUB for comparison
        reg_write  <= '0';  -- No register write
        
      when "1100" =>  -- BGT (Branch Greater Than) - Opcode 1100
        branch     <= '1';  -- Enable branch
        alu_src    <= '1';  -- Use immediate
        ALU_OP     <= "01"; -- SUB for comparison
        reg_write  <= '0';  -- No register write
        
      when "1101" =>  -- BGE (Branch Greater or Equal) - Opcode 1101
        branch     <= '1';  -- Enable branch
        alu_src    <= '1';  -- Use immediate
        ALU_OP     <= "01"; -- SUB for comparison
        reg_write  <= '0';  -- No register write
        
      when "1110" =>  -- Branch - Opcode 1110
        branch     <= '1';  -- Enable branch
        alu_src    <= '1';  -- Use immediate
        ALU_OP     <= "01"; -- SUB for comparison
        reg_write  <= '0';  -- No register write
        
      when "1111" =>  -- Jump - Opcode 1111
        jump       <= '1';  -- Enable jump
        ALU_OP     <= "11"; -- Don't care
        reg_write  <= '0';  -- No register write
        mem_write  <= '0';  -- No memory write
        
      when others =>
        null;
    end case;
  end process;
end architecture;