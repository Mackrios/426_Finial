library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory is
  port(
    address     : in  unsigned(15 downto 0);
    instruction : out unsigned(15 downto 0)
  );
end entity;

architecture rtl of instruction_memory is
  type mem_array is array(0 to 255) of unsigned(15 downto 0);
  
  -- Your test program from the lab document
  signal mem : mem_array := (
    -- Address 0x0000
    0  => x"34BF",  -- addi $r2, $r2, -1
    1  => x"10C0",  -- lw $r3, 0($r1)
    2  => x"118C",  -- lw $r6, 48($r0)
    3  => x"58A5",  -- bgt $r3, $r6, +5
    4  => x"0D90",  -- sll $r6, $r6, 2
    5  => x"0FEF",  -- xor $r7, $r7, $r6
    6  => x"11D0",  -- lw $r3, 52($r0)
    7  => x"20C0",  -- sw $r3, 0($r1)
    8  => x"801E",  -- j ENDIF
    9  => x"0D85",  -- srl $r4, $r4, 1
    10 => x"0D85",  -- srl $r4, $r4, 1
    11 => x"0D85",  -- srl $r4, $r4, 1
    12 => x"0B6B",  -- or $r5, $r5, $r4
    13 => x"11B8",  -- lw $r3, 50($r0)
    14 => x"20C0",  -- sw $r3, 0($r1)
    15 => x"3902",  -- addi $r1, $r1, 2
    16 => x"541F",  -- bgt $r2, $r0, -17
    others => (others => '0')
  );
  
begin
  -- Read instruction (combinational)
  instruction <= mem(to_integer(address(7 downto 0))) 
                 when to_integer(address) < 256 
                 else (others => '0');
end architecture;