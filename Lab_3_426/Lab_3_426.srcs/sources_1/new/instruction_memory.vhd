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
  
  -- ================================================================
  -- PSEUDOCODE PROGRAM - CORRECTLY ENCODED
  -- ================================================================
  -- Register mapping:
  -- $r0 = $v0 (0x0040), $r1 = $a0 (0x1010), $r2 = $a1 (0x000F)
  -- $r3 = $v1 (0x00F0), $r4 = $t0 (0x0000), $r5 = $v2 (0x0010)
  -- $r6 = $v3 (0x0005), $r7 = temp
  --
  -- Instruction Formats:
  -- R-Format: [Opcode 4][Rs 3][Rt 3][Rd 3][Func 3]
  -- I-Format: [Opcode 4][Rs 3][Rt 3][Immediate 6]
  -- J-Format: [Opcode 4][Address 12]
  --
  -- From Control Table:
  -- R-type: 0000, LW: 0001, SW: 0010, ADDI: 0011
  -- Branch: 0100, BGT: 0101, BGE: 0110, BEQ: 0111, Jump: 1000
  -- ================================================================
  
  
  signal mem : mem_array := (
  0  => x"34BF", -- addi $r2, $r2, -1
  1  => x"1300", -- lw $r4, 0($r1)
  2  => x"1188", -- lw $r6, 8($r0)   -- FIXED
  3  => x"5985", -- bgt $r4, $r6, +5
  4  => x"0A2A", -- sll $r5, $r5, 2
  5  => x"075F", -- xor $r3, $r3, $r5
  6  => x"11CA", -- lw $r7, 10($r0)  -- FIXED
  7  => x"23C0", -- sw $r7, 0($r1)
  8  => x"801A", -- j 0x001A
  9  => x"0003", -- srl $r0, $r0, 3
  10 => x"061B", -- or $r3, $r3, $r0
  11 => x"11CC", -- lw $r7, 12($r0)  -- FIXED
  12 => x"23C0", -- sw $r7, 0($r1)
  13 => x"3244", -- addi $r1, $r1, 4
  14 => x"5431", -- bgt $r2, $r0, -15
  others => (others => '0')
);


  
  
--  signal mem : mem_array := (
--    -- ============================================================
--    -- WHILE LOOP START (Address 0x0000)
--    -- ============================================================
    
--    -- 0x0000: addi $r2, $r2, -1  ($a1 = $a1 - 1, decrement counter)
--    -- I-Format: [0011][010][010][111111] = 0011 010 010 111111
--    -- Opcode=0011 (ADDI), Rs=$r2, Rt=$r2, Imm=-1 (111111 in 6-bit 2's complement)
--    0  => x"34BF",  -- 0011 0100 1011 1111
    
--    -- 0x0002: lw $r4, 0($r1)  ($t0 = Mem[$a0])
--    -- I-Format: [0001][001][100][000000] = 0001 001 100 000000
--    -- Opcode=0001 (LW), Rs=$r1 (base), Rt=$r4 (dest), Offset=0
--    1  => x"1900",  -- 0001 1001 0000 0000
    
--    -- 0x0004: lw $r6, 4($r0)  (Load comparison value 0x0100)
--    -- Note: Memory address 8 means offset 4 (byte address / 2 = word offset)
--    -- I-Format: [0001][000][110][000100] = 0001 000 110 000100
--    -- Opcode=0001 (LW), Rs=$r0 (base), Rt=$r6 (dest), Offset=4
--    2  => x"10C4",  -- 0001 0000 1100 0100
    
--    -- 0x0006: bgt $r4, $r6, +5  (if $t0 > 0x0100 goto THEN)
--    -- I-Format: [0101][100][110][000101] = 0101 100 110 000101
--    -- Opcode=0101 (BGT), Rs=$r4, Rt=$r6, Offset=+5 (to address 0x0012)
--    3  => x"5CC5",  -- 0101 1100 1100 0101
    
--    -- ============================================================
--    -- ELSE BRANCH (Address 0x0008)
--    -- ============================================================
    
--    -- 0x0008: sll $r5, $r5, 2  ($v2 = $v2 × 4, shift left by 2)
--    -- R-Format: [0000][101][000][101][010] = 0000 101 000 101 010
--    -- Opcode=0000 (R-type), Rs=$r5, Rt=$r0 (unused), Rd=$r5, Func=010 (shamt)
--    -- Note: shamt field stores shift amount
--    4  => x"0A0A",  -- 0000 1010 0000 1010 (sll $r5, $r5, 2)
    
--    -- 0x000A: xor $r3, $r3, $r5  ($v3 = $v3 ? $v2)
--    -- R-Format: [0000][011][101][011][111] = 0000 011 101 011 111
--    -- Opcode=0000 (R-type), Rs=$r3, Rt=$r5, Rd=$r3, Func=111 (XOR)
--    5  => x"0757",  -- 0000 0111 0101 0111
    
--    -- 0x000C: lw $r7, 5($r0)  (Load 0x00FF from memory address 10)
--    -- I-Format: [0001][000][111][000101] = 0001 000 111 000101
--    -- Opcode=0001 (LW), Rs=$r0, Rt=$r7, Offset=5
--    6  => x"11C5",  -- 0001 0001 1100 0101
    
--    -- 0x000E: sw $r7, 0($r1)  (Mem[$a0] = 0x00FF)
--    -- I-Format: [0010][001][111][000000] = 0010 001 111 000000
--    -- Opcode=0010 (SW), Rs=$r1 (base), Rt=$r7 (data), Offset=0
--    7  => x"27C0",  -- 0010 0111 1100 0000
    
--    -- 0x0010: j 0x001A  (jump to ENDIF)
--    -- J-Format: [1000][000000011010] = 1000 0000 0001 1010
--    -- Opcode=1000 (JUMP), Address=0x001A (in bytes: 26, word addr: 13)
--    8  => x"801A",  -- 1000 0000 0001 1010
    
--    -- ============================================================
--    -- THEN BRANCH (Address 0x0012)
--    -- ============================================================
    
--    -- 0x0012: srl $r0, $r0, 3  ($v0 = $v0 ÷ 8, shift right by 3)
--    -- R-Format: [0000][000][000][000][011] = 0000 000 000 000 011
--    -- Opcode=0000 (R-type), Rs=$r0, Rt=$r0, Rd=$r0, Func=011 (shamt)
--    9  => x"0003",  -- 0000 0000 0000 0011 (srl $r0, $r0, 3)
    
--    -- 0x0014: or $r3, $r3, $r0  ($v1 = $v1 | $v0)
--    -- R-Format: [0000][011][000][011][011] = 0000 011 000 011 011
--    -- Opcode=0000 (R-type), Rs=$r3, Rt=$r0, Rd=$r3, Func=011 (OR)
--    10 => x"061B",  -- 0000 0110 0001 1011
    
--    -- 0x0016: lw $r7, 6($r0)  (Load 0xFF00 from memory address 12)
--    -- I-Format: [0001][000][111][000110] = 0001 000 111 000110
--    -- Opcode=0001 (LW), Rs=$r0, Rt=$r7, Offset=6
--    11 => x"11C6",  -- 0001 0001 1100 0110
    
--    -- 0x0018: sw $r7, 0($r1)  (Mem[$a0] = 0xFF00)
--    -- I-Format: [0010][001][111][000000] = 0010 001 111 000000
--    -- Opcode=0010 (SW), Rs=$r1, Rt=$r7, Offset=0
--    12 => x"27C0",  -- 0010 0111 1100 0000
    
--    -- ============================================================
--    -- ENDIF (Address 0x001A)
--    -- ============================================================
    
--    -- 0x001A: addi $r1, $r1, 2  ($a0 = $a0 + 2, increment pointer)
--    -- I-Format: [0011][001][001][000010] = 0011 001 001 000010
--    -- Opcode=0011 (ADDI), Rs=$r1, Rt=$r1, Imm=+2
--    13 => x"3242",  -- 0011 0010 0100 0010
    
--    -- 0x001C: bgt $r2, $r0, -14  (if $a1 > 0 goto WHILE)
--    -- Branch back to address 0x0000, offset = -14 (0x0000 - 0x001C = -28 bytes / 2 = -14 words)
--    -- I-Format: [0101][010][000][111110] = 0101 010 000 111110 (sign bit = 1)
--    -- Actually: PC-relative, from 0x001E to 0x0000 = -15 instructions
--    -- Offset in 6-bit 2's complement: -15 = 110001 (inverted 001110 + 1 = 110001)
--    14 => x"5431",  -- 0101 0100 0011 0001 (bgt $r2, $r0, -15)
    
--    others => (others => '0')
--  );
  
begin
  -- Read instruction (combinational, word addressed: PC steps by 2 bytes)
  instruction <= mem(to_integer(address(7 downto 1)));
end architecture;
