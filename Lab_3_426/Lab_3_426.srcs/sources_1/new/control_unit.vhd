
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_unit is
  port(
    opcode      : in  unsigned(3 downto 0);
    -- Control signals
    reg_dst     : out std_logic;              -- register dest select
    jump        : out std_logic;              -- jump cont
    branch      : out std_logic;              -- branch cont
    mem_read    : out std_logic;              -- memory rd ena
    mem_to_reg  : out std_logic;              
    ALU_OP      : out unsigned(1 downto 0);   -- op type
    mem_write   : out std_logic;              -- memory write enab
    alu_src     : out std_logic;              -- alu select
    reg_write   : out std_logic               -- register write enab
  );
end entity;

architecture rtl of control_unit is
begin
  process(opcode)
  begin
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
      -- R-type inst: add, sub, and, or, sll, srl, Ssra, xor
      -- Opcode 0000, 0001, 0010, 0011, 0100, 0101, 0110, 0111
      when "0000" | "0001" | "0010" | "0011" | 
           "0100" | "0101" | "0110" | "0111" =>
        reg_dst    <= '1';  
        ALU_OP     <= "10"; 
        reg_write  <= '1';  
        alu_src    <= '0';  
        
      when "1000" =>  --lw
        reg_dst    <= '0';  
        alu_src    <= '1';  
        mem_to_reg <= '1';  
        reg_write  <= '1';  
        mem_read   <= '1';  
        ALU_OP     <= "00"; 
        
      when "1001" =>  -- sw
        alu_src    <= '1';  
        mem_write  <= '1';  
        ALU_OP     <= "00"; 
        
      when "1010" =>  -- addi
        reg_dst    <= '0';  
        alu_src    <= '1';  
        reg_write  <= '1';  
        ALU_OP     <= "00"; 
        
      when "1011" =>  -- beq
        branch     <= '1';  
        alu_src    <= '1';  
        ALU_OP     <= "01";
        reg_write  <= '0';  
        
      when "1100" =>  -- bgt
        branch     <= '1';  
        alu_src    <= '1';  
        ALU_OP     <= "01"; 
        reg_write  <= '0';  
        
      when "1101" =>  -- bge
        branch     <= '1';  
        alu_src    <= '1';  
        ALU_OP     <= "01"; 
        reg_write  <= '0'; 
        
      when "1110" =>  -- b
        branch     <= '1';  
        alu_src    <= '1'; 
        ALU_OP     <= "01"; 
        reg_write  <= '0';  
        
      when "1111" =>  -- jump
        jump       <= '1';  
        ALU_OP     <= "11";
        reg_write  <= '0';  
        mem_write  <= '0';  
        
      when others =>
        null;
    end case;
  end process;
end architecture;