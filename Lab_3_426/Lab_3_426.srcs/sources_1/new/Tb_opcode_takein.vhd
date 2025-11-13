--------------------------------------------------------------------------------
-- MIPS Pipeline Individual Instruction Testbench
-- Tests each instruction type individually to verify correctness
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_individual_instructions is
end entity;

architecture testbench of tb_individual_instructions is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    
    -- CPU Output Signals
    signal pc : unsigned(15 downto 0);
    signal reg0, reg1, reg2, reg3 : unsigned(15 downto 0);
    signal reg4, reg5, reg6, reg7 : unsigned(15 downto 0);
    
    component pipelined_cpu
        port( 
            clk    : in  std_logic;
            rst    : in  std_logic;
            pc_out : out unsigned(15 downto 0);
            reg0   : out unsigned(15 downto 0);
            reg1   : out unsigned(15 downto 0);
            reg2   : out unsigned(15 downto 0);
            reg3   : out unsigned(15 downto 0);
            reg4   : out unsigned(15 downto 0);
            reg5   : out unsigned(15 downto 0);
            reg6   : out unsigned(15 downto 0);
            reg7   : out unsigned(15 downto 0)
        );
    end component;
    
    signal sim_done : boolean := false;
    signal test_passed : integer := 0;
    signal test_failed : integer := 0;
    
    -- Utility functions
    function to_hex_string(value : unsigned) return string is
        variable hex_chars : string(1 to 16) := "0123456789ABCDEF";
        variable result : string(1 to 4);
        variable temp : unsigned(15 downto 0);
    begin
        temp := value;
        for i in 4 downto 1 loop
            result(i) := hex_chars(to_integer(temp(3 downto 0)) + 1);
            temp := shift_right(temp, 4);
        end loop;
        return result;
    end function;
    
    procedure wait_cycles(constant n : integer) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure;
    
    procedure check_register(
        constant reg_name : string;
        signal reg_value : unsigned(15 downto 0);
        constant expected : unsigned(15 downto 0);
        signal passed : inout integer;
        signal failed : inout integer
    ) is
    begin
        if reg_value = expected then
            report "  PASS: " & reg_name & " = 0x" & to_hex_string(reg_value) & " (expected 0x" & to_hex_string(expected) & ")" severity note;
            passed <= passed + 1;
        else
            report "  FAIL: " & reg_name & " = 0x" & to_hex_string(reg_value) & " (expected 0x" & to_hex_string(expected) & ")" severity error;
            failed <= failed + 1;
        end if;
    end procedure;
    
begin
    
    -- DUT Instantiation
    DUT: pipelined_cpu port map(
        clk    => clk,
        rst    => rst,
        pc_out => pc,
        reg0   => reg0,
        reg1   => reg1,
        reg2   => reg2,
        reg3   => reg3,
        reg4   => reg4,
        reg5   => reg5,
        reg6   => reg6,
        reg7   => reg7
    );
    
    -- Clock generation
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Main test process
    test_process: process
    begin
        report "========================================";
        report "INDIVIDUAL INSTRUCTION TEST SUITE";
        report "========================================";
        report "";
        
        -- Reset phase
        rst <= '1';
        wait_cycles(3);
        rst <= '0';
        wait_cycles(2);
        
        -- ====================================================================
        -- TEST 1: Check Initial Register Values
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 1: Initial Register Values";
        report "----------------------------------------";
        wait_cycles(1);
        
        report "Checking initial register state:";
        check_register("R0", reg0, x"0000", test_passed, test_failed);
        check_register("R1", reg1, x"0020", test_passed, test_failed);
        check_register("R2", reg2, x"000F", test_passed, test_failed);
        check_register("R3", reg3, x"00F0", test_passed, test_failed);
        check_register("R4", reg4, x"0000", test_passed, test_failed);
        check_register("R5", reg5, x"0010", test_passed, test_failed);
        check_register("R6", reg6, x"0005", test_passed, test_failed);
        check_register("R7", reg7, x"0000", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 2: ADDI Instruction
        -- Program: addi $r2, $r2, -1
        -- Opcode: 0011 010 010 111111 = 0x34BF
        -- Expected: R2 = 0x000F - 1 = 0x000E
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 2: ADDI Instruction";
        report "----------------------------------------";
        report "Instruction: addi $r2, $r2, -1 (0x34BF)";
        report "Initial R2: 0x" & to_hex_string(reg2);
        
        -- Wait for instruction to complete pipeline (5 stages + some buffer)
        wait_cycles(10);
        
        report "After execution:";
        report "  R2 = 0x" & to_hex_string(reg2);
        check_register("R2 after ADDI", reg2, x"000E", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 3: LW Instruction
        -- Program: lw $r4, 0($r1)
        -- Opcode: 0001 001 100 000000 = 0x1300
        -- R1 = 0x0020 (byte address) = word index 16
        -- Memory[16] should be loaded into R4
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 3: LW Instruction";
        report "----------------------------------------";
        report "Instruction: lw $r4, 0($r1) (0x1300)";
        report "R1 (base address): 0x" & to_hex_string(reg1);
        report "Initial R4: 0x" & to_hex_string(reg4);
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R4 = 0x" & to_hex_string(reg4);
        report "  Note: R4 should contain value from memory[word_index_16]";
        -- We expect 0x0000 since memory[16] is initialized to 0
        check_register("R4 after LW", reg4, x"0000", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 4: LW with offset
        -- Program: lw $r6, 4($r0)
        -- Opcode: 0001 000 110 000100 = 0x1184
        -- R0 = 0x0000, offset = 4 bytes = word index 2
        -- Memory[4] = 0x0100 (comparison threshold)
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 4: LW with Offset";
        report "----------------------------------------";
        report "Instruction: lw $r6, 4($r0) (0x1184)";
        report "R0 (base): 0x" & to_hex_string(reg0);
        report "Offset: 4 bytes (word index 4)";
        report "Initial R6: 0x" & to_hex_string(reg6);
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R6 = 0x" & to_hex_string(reg6);
        report "  Expected: 0x0100 (from memory[4])";
        check_register("R6 after LW", reg6, x"0100", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 5: R-Type - SLL (Shift Left Logical)
        -- Program: sll $r5, $r5, 2
        -- Opcode: 0000 101 000 101 010 = 0x0A2A
        -- R5 = 0x0010, shift left by 2 = 0x0040
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 5: SLL Instruction";
        report "----------------------------------------";
        report "Instruction: sll $r5, $r5, 2 (0x0A2A)";
        report "Initial R5: 0x" & to_hex_string(reg5);
        report "Expected: 0x0010 << 2 = 0x0040";
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R5 = 0x" & to_hex_string(reg5);
        check_register("R5 after SLL", reg5, x"0040", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 6: R-Type - XOR
        -- Program: xor $r3, $r3, $r5
        -- Opcode: 0000 011 101 011 111 = 0x075F
        -- R3 = 0x00F0, R5 = 0x0040
        -- Result: 0x00F0 XOR 0x0040 = 0x00B0
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 6: XOR Instruction";
        report "----------------------------------------";
        report "Instruction: xor $r3, $r3, $r5 (0x075F)";
        report "R3: 0x" & to_hex_string(reg3);
        report "R5: 0x" & to_hex_string(reg5);
        report "Expected: 0x00F0 XOR 0x0040 = 0x00B0";
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R3 = 0x" & to_hex_string(reg3);
        check_register("R3 after XOR", reg3, x"00B0", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 7: LW - Load constant for SW test
        -- Program: lw $r7, 5($r0)
        -- Opcode: 0001 000 111 000101 = 0x11C5
        -- Memory[5] = 0x00FF
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 7: LW - Load Constant";
        report "----------------------------------------";
        report "Instruction: lw $r7, 5($r0) (0x11C5)";
        report "Expected: Load 0x00FF from memory[5]";
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R7 = 0x" & to_hex_string(reg7);
        check_register("R7 after LW", reg7, x"00FF", test_passed, test_failed);
        report "";
        
        -- ====================================================================
        -- TEST 8: SW - Store Word
        -- Program: sw $r7, 0($r1)
        -- Opcode: 0010 001 111 000000 = 0x23C0
        -- Store R7 (0x00FF) to memory[R1] = memory[16]
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 8: SW Instruction";
        report "----------------------------------------";
        report "Instruction: sw $r7, 0($r1) (0x23C0)";
        report "R7 (data): 0x" & to_hex_string(reg7);
        report "R1 (address): 0x" & to_hex_string(reg1);
        report "Action: Store 0x00FF to memory[word_index_16]";
        
        wait_cycles(10);
        
        report "SW instruction completed.";
        report "  To verify: Check memory[16] in waveform should be 0x00FF";
        report "";
        
        -- ====================================================================
        -- TEST 9: R-Type - SRL (Shift Right Logical)
        -- Program: srl $r0, $r0, 3
        -- Opcode: 0000 000 000 000 011 = 0x0003
        -- Note: R0 might be read-only or have special behavior
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 9: SRL Instruction";
        report "----------------------------------------";
        report "Instruction: srl $r0, $r0, 3 (0x0003)";
        report "Initial R0: 0x" & to_hex_string(reg0);
        report "Note: R0 behavior depends on implementation";
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R0 = 0x" & to_hex_string(reg0);
        report "  (R0 may remain 0x0000 if it's hardwired to zero)";
        report "";
        
        -- ====================================================================
        -- TEST 10: R-Type - OR
        -- Program: or $r3, $r3, $r0
        -- Opcode: 0000 011 000 011 011 = 0x061B
        -- R3 OR R0
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 10: OR Instruction";
        report "----------------------------------------";
        report "Instruction: or $r3, $r3, $r0 (0x061B)";
        report "R3: 0x" & to_hex_string(reg3);
        report "R0: 0x" & to_hex_string(reg0);
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R3 = 0x" & to_hex_string(reg3);
        report "";
        
        -- ====================================================================
        -- TEST 11: ADDI - Increment pointer
        -- Program: addi $r1, $r1, 4
        -- Opcode: 0011 001 001 000100 = 0x3244
        -- R1 = R1 + 4
        -- ====================================================================
        report "----------------------------------------";
        report "TEST 11: ADDI - Pointer Increment";
        report "----------------------------------------";
        report "Instruction: addi $r1, $r1, 4 (0x3244)";
        report "Initial R1: 0x" & to_hex_string(reg1);
        
        wait_cycles(10);
        
        report "After execution:";
        report "  R1 = 0x" & to_hex_string(reg1);
        report "  Expected: R1 increased by 4";
        report "";
        
        -- ====================================================================
        -- FINAL SUMMARY
        -- ====================================================================
        wait_cycles(5);
        
        report "";
        report "========================================";
        report "TEST SUMMARY";
        report "========================================";
        report "Tests Passed: " & integer'image(test_passed);
        report "Tests Failed: " & integer'image(test_failed);
        report "";
        
        if test_failed = 0 then
            report "ALL TESTS PASSED!" severity note;
        else
            report "SOME TESTS FAILED - Review errors above" severity warning;
        end if;
        
        report "";
        report "========================================";
        report "FINAL REGISTER STATE";
        report "========================================";
        report "R0: 0x" & to_hex_string(reg0);
        report "R1: 0x" & to_hex_string(reg1);
        report "R2: 0x" & to_hex_string(reg2);
        report "R3: 0x" & to_hex_string(reg3);
        report "R4: 0x" & to_hex_string(reg4);
        report "R5: 0x" & to_hex_string(reg5);
        report "R6: 0x" & to_hex_string(reg6);
        report "R7: 0x" & to_hex_string(reg7);
        report "PC: 0x" & to_hex_string(pc);
        report "";
        
        sim_done <= true;
        wait;
    end process;
    
end architecture testbench;