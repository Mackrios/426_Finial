library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_unit is
  port(
    opcode      : in  unsigned(3 downto 0);
    reg_dst     : out std_logic;
    jump        : out std_logic;
    branch      : out std_logic;
    mem_read    : out std_logic;
    mem_to_reg  : out std_logic;
    ALU_OP      : out unsigned(1 downto 0);
    mem_write   : out std_logic;
    alu_src     : out std_logic;
    reg_write   : out std_logic
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
      when "0000" =>  -- R-type
        reg_dst    <= '1';
        ALU_OP     <= "10";
        reg_write  <= '1';
        alu_src    <= '0';
        
      when "0001" =>  -- LW
        reg_dst    <= '0';
        alu_src    <= '1';
        mem_to_reg <= '1';
        reg_write  <= '1';
        mem_read   <= '1';
        ALU_OP     <= "00";
        
      when "0010" =>  -- SW
        alu_src    <= '1';
        mem_write  <= '1';
        ALU_OP     <= "00";
        
      when "0011" =>  -- ADDI
        reg_dst    <= '0';
        alu_src    <= '1';
        reg_write  <= '1';
        ALU_OP     <= "00";
        
      when "0100" =>  -- BRANCH
        branch     <= '1';
        alu_src    <= '0';
        ALU_OP     <= "01";
        
      when "0101" =>  -- BGT
        branch     <= '1';
        alu_src    <= '0';
        ALU_OP     <= "01";
        
      when "0110" =>  -- BGE
        branch     <= '1';
        alu_src    <= '0';
        ALU_OP     <= "01";
        
      when "0111" =>  -- BEQ
        branch     <= '1';
        alu_src    <= '0';
        ALU_OP     <= "01";
        
      when "1000" =>  -- JUMP 
        jump       <= '1';
        ALU_OP     <= "11";
        
      when others =>
        null;
    end case;
  end process;
end architecture;