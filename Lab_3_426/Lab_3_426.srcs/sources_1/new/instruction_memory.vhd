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
  
  -- ===========================================================
  -- CORRECTED PROGRAM MATCHING ASSEMBLY CODE
  -- ===========================================================
  -- Register assignment:
  -- r0 = v0    (0x0040)
  -- r1 = v1    (0x1010)
  -- r2 = v2    (0x000F)
  -- r3 = v3    (0x00F0)
  -- r4 = t0    (0x0000)
  -- r5 = a0    (0x0010) - pointer to data array
  -- r6 = a1    (0x0005) - loop counter
  -- r7 = temp  (0x0000)
  --
  -- Memory layout:
  -- mem[4] @ byte_addr 8  = 0x0100 (comparison constant)
  -- mem[5] @ byte_addr 10 = 0x00FF (ELSE store value)
  -- mem[6] @ byte_addr 12 = 0xFF00 (THEN store value)
  -- mem[8-25] = data array (accessed via a0 starting at 0x0010)
  --
  -- Instruction formats:
  -- R-Format: [Opcode 4][Rs 3][Rt 3][Rd 3][Func 3]
  -- I-Format: [Opcode 4][Rs 3][Rt 3][Immediate 6]
  -- J-Format: [Opcode 4][Address 12]
  --
  -- Opcodes:
  -- R-type: 0000, LW: 0001, SW: 0010, ADDI: 0011
  -- BGT: 0101, JUMP: 1000
  -- ===========================================================
  
  signal mem : mem_array := (
    -- ============================================================
    -- WHILE LOOP START (Address 0x00)
    -- ============================================================
    
    -- 0x00: addi $r6, $r6, -1  ($a1 = $a1 - 1, decrement counter)
    -- I-Format: [0011][110][110][111111]
    0  => x"36BF",
    
    -- 0x02: lw $r4, 0($r5)  ($t0 = Mem[$a0], load from data array)
    -- I-Format: [0001][101][100][000000]
    1  => x"1A80",
    
    -- 0x04: sub $r7, $r7, $r7  ($r7 = 0, create zero register)
    -- R-Format: [0000][111][111][111][001]
    -- Rs=$r7, Rt=$r7, Rd=$r7, Func=001 (SUB)
    2  => x"0FE1",
    
    -- 0x06: lw $r7, 8($r7)  (Load 0x0100 from mem[4])
    -- I-Format: [0001][111][111][001000]
    3  => x"1F88",
    
    -- 0x08: bgt $r4, $r7, +6  (if $t0 > 0x0100 goto THEN)
    -- I-Format: [0101][100][111][000110]
    -- Branch to address 0x16 (skip ELSE branch + jump)
    4  => x"5E66",
    
    -- ============================================================
    -- ELSE BRANCH (Address 0x0A)
    -- ============================================================
    
    -- 0x0A: sll $r2, $r2, 2  ($v2 = $v2 × 4, shift left by 2)
    -- R-Format: [0000][010][010][010][010]
    -- Rs=$r2, Rt=$r2 (unused), Rd=$r2, Func=010 (SLL)
    5  => x"0512",
    
    -- 0x0C: xor $r3, $r3, $r2  ($v3 = $v3 ? $v2)
    -- R-Format: [0000][011][010][011][111]
    -- Rs=$r3, Rt=$r2, Rd=$r3, Func=111 (XOR)
    6  => x"0727",
    
    -- 0x0E: lw $r7, 10($r7)  (Load 0x00FF from mem[5])
    -- I-Format: [0001][111][111][001010]
    -- Note: $r7 was zeroed, so base is 0, offset 10 accesses byte addr 10
    7  => x"1F8A",
    
    -- 0x10: sw $r7, 0($r5)  (Mem[$a0] = 0x00FF)
    -- I-Format: [0010][101][111][000000]
    8  => x"2BC0",
    
    -- 0x12: j 0x20  (Jump to ENDIF)
    -- J-Format: [1000][000000100000]
    -- Jump to byte address 0x20 (word index 16)
    9  => x"8020",
    
    -- ============================================================
    -- THEN BRANCH (Address 0x14)
    -- ============================================================
    
    -- 0x14: srl $r0, $r0, 3  ($v0 = $v0 ÷ 8, shift right by 3)
    -- R-Format: [0000][000][000][000][101]
    -- Rs=$r0, Rt=$r0, Rd=$r0, Func=101 (SRL) - using shamt encoding
    10 => x"0005",
    
    -- 0x16: or $r1, $r1, $r0  ($v1 = $v1 | $v0)
    -- R-Format: [0000][001][000][001][011]
    -- Rs=$r1, Rt=$r0, Rd=$r1, Func=011 (OR)
    11 => x"0883",
    
    -- 0x18: sub $r7, $r7, $r7  ($r7 = 0, re-zero for loading)
    -- R-Format: [0000][111][111][111][001]
    12 => x"0FE1",
    
    -- 0x1A: lw $r7, 12($r7)  (Load 0xFF00 from mem[6])
    -- I-Format: [0001][111][111][001100]
    13 => x"1F8C",
    
    -- 0x1C: sw $r7, 0($r5)  (Mem[$a0] = 0xFF00)
    -- I-Format: [0010][101][111][000000]
    14 => x"2BC0",
    
    -- 0x1E: j 0x20  (Jump to ENDIF - optional NOP)
    -- J-Format: [1000][000000100000]
    15 => x"8020",
    
    -- ============================================================
    -- ENDIF (Address 0x20)
    -- ============================================================
    
    -- 0x20: addi $r5, $r5, 2  ($a0 = $a0 + 2)
    -- I-Format: [0011][101][101][000010]
    16 => x"35A2",
    
    -- 0x22: sub $r7, $r7, $r7  ($r7 = 0, for comparison)
    -- R-Format: [0000][111][111][111][001]
    17 => x"0FE1",
    
    -- 0x24: bgt $r6, $r7, -18  (Loop back to WHILE if $a1 > 0)
    -- I-Format: [0101][110][111][OFFSET]
    -- From PC=0x26 back to 0x00: (0x00 - 0x26)/2 = -19 instructions
    -- -19 in 6-bit 2's complement: ~18 = 45, 45+1 = 46 = 101110
    -- Actually: -19 = 111101 in 6-bit two's complement
    -- Let's verify: 19 decimal = 010011 binary
    -- Invert: 101100, Add 1: 101101 (0x2D)
    18 => x"5EED",
    
    -- ============================================================
    -- RETURN / HALT (Address 0x26)
    -- ============================================================
    
    -- 0x26: j 0x26  (Infinite loop)
    -- J-Format: [1000][000000100110]
    19 => x"8026",
    
    others => (others => '0')
  );
  
begin
  -- Word addressing: PC increments by 2 (byte addresses)
  instruction <= mem(to_integer(address(7 downto 1)));
end architecture;