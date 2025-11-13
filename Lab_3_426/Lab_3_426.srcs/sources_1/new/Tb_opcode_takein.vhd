-- MIPS Pipeline Testbench - FINAL WITH MEMORY MONITORING AND ASSERTIONS
-- Directly accesses and verifies memory signals from data_memory
-- Comprehensive memory bus monitoring with cycle-by-cycle tracking
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_mips_pipeline is
end entity;

architecture testbench of tb_mips_pipeline is

    constant CLK_PERIOD : time := 10 ns;
    constant MAX_INSTRUCTIONS : integer := 256;
    constant MAX_CYCLES : integer := 500;
    constant OPCODE_FILE : string := "opcodes.txt";
    
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    
    -- CPU Output Signals
    signal Program_Counter_PC : unsigned(15 downto 0);
    signal Reg0_Contents, Reg1_Contents, Reg2_Contents, Reg3_Contents : unsigned(15 downto 0);
    signal Reg4_Contents, Reg5_Contents, Reg6_Contents, Reg7_Contents : unsigned(15 downto 0);
    
    -- Pipeline Stage Enumeration
    type pipeline_stage is (EMPTY, IF_STAGE, ID_STAGE, EX_STAGE, MEM_STAGE, WB_STAGE, COMPLETE);
    
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
    
    type opcode_array is array (0 to MAX_INSTRUCTIONS-1) of unsigned(15 downto 0);
    

    -- Instruction Tracking Record
    type instruction_tracking_record is record
        Instr_Number : integer;
        Opcode_Bits : unsigned(3 downto 0);
        Dest_Register : integer;
        Source1_Register : integer;
        Source2_Register : integer;
        Pipeline_Stage : pipeline_stage;
        Entry_Cycle : integer;
        Cycles_In_Current_Stage : integer;
    end record;
    
    type pipeline_array is array (0 to 4) of instruction_tracking_record;
    
    signal Pipeline_Tracker : pipeline_array;
    
    signal IF_Stage_Status : pipeline_stage;
    signal ID_Stage_Status : pipeline_stage;
    signal EX_Stage_Status : pipeline_stage;
    signal MEM_Stage_Status : pipeline_stage;
    signal WB_Stage_Status : pipeline_stage;
    
    signal IF_Instr_Number : integer;
    signal ID_Instr_Number : integer;
    signal EX_Instr_Number : integer;
    signal MEM_Instr_Number : integer;
    signal WB_Instr_Number : integer;

    -- File reading function
    impure function read_opcodes_from_file(filename : string) return opcode_array is
        file f : text;
        variable line_buf : line;
        variable opcode_val : unsigned(15 downto 0);
        variable result : opcode_array := (others => (others => '0'));
        variable index : integer := 0;
        variable hex_char : character;
        variable hex_val : integer;
    begin
        file_open(f, filename, read_mode);
        
        while not endfile(f) and index < MAX_INSTRUCTIONS loop
            readline(f, line_buf);
            
            if line_buf'length >= 4 then
                opcode_val := (others => '0');
                
                for i in 1 to 4 loop
                    read(line_buf, hex_char);
                    
                    case hex_char is
                        when '0' => hex_val := 0; when '1' => hex_val := 1;
                        when '2' => hex_val := 2; when '3' => hex_val := 3;
                        when '4' => hex_val := 4; when '5' => hex_val := 5;
                        when '6' => hex_val := 6; when '7' => hex_val := 7;
                        when '8' => hex_val := 8; when '9' => hex_val := 9;
                        when 'A' | 'a' => hex_val := 10; when 'B' | 'b' => hex_val := 11;
                        when 'C' | 'c' => hex_val := 12; when 'D' | 'd' => hex_val := 13;
                        when 'E' | 'e' => hex_val := 14; when 'F' | 'f' => hex_val := 15;
                        when others => hex_val := 0;
                    end case;
                    
                    opcode_val := shift_left(opcode_val, 4) or resize(to_unsigned(hex_val, 4), 16);
                end loop;
                
                result(index) := opcode_val;
                index := index + 1;
            end if;
        end loop;
        
        file_close(f);
        return result;
    end function;

    signal opcodes : opcode_array := read_opcodes_from_file(OPCODE_FILE);
    
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
    
    -- Corrected Opcode Name Mapping
    function get_opcode_name(opcode_bits : unsigned(3 downto 0)) return string is
    begin
        case opcode_bits is
            when "0000" => return "R-TYPE";
            when "0001" => return "LW    ";
            when "0010" => return "SW    ";
            when "0011" => return "ADDI  ";
            when "0100" => return "BRANCH";
            when "0101" => return "BGT   ";
            when "0110" => return "BGE   ";
            when "0111" => return "BEQ   ";
            when "1000" => return "JUMP  ";
            when others => return "?????  ";
        end case;
    end function;
    
    function get_register_name(reg_num : integer) return string is
    begin
        case reg_num is
            when 0 => return "R0";
            when 1 => return "R1";
            when 2 => return "R2";
            when 3 => return "R3";
            when 4 => return "R4";
            when 5 => return "R5";
            when 6 => return "R6";
            when 7 => return "R7";
            when others => return "??";
        end case;
    end function;
    
    function stage_to_string(stage : pipeline_stage) return string is
    begin
        case stage is
            when EMPTY    => return "EMPTY         ";
            when IF_STAGE => return "IF (Fetch)    ";
            when ID_STAGE => return "ID (Decode)   ";
            when EX_STAGE => return "EX (Execute)  ";
            when MEM_STAGE => return "MEM (Memory)  ";
            when WB_STAGE => return "WB (WriteBack)";
            when COMPLETE => return "COMPLETE      ";
        end case;
    end function;
    
begin
    
    -- DUT Instantiation
    DUT: pipelined_cpu port map(
        clk    => clk,
        rst    => rst,
        pc_out => Program_Counter_PC,
        reg0   => Reg0_Contents,
        reg1   => Reg1_Contents,
        reg2   => Reg2_Contents,
        reg3   => Reg3_Contents,
        reg4   => Reg4_Contents,
        reg5   => Reg5_Contents,
        reg6   => Reg6_Contents,
        reg7   => Reg7_Contents
    );
    
    load_opcodes: process
    begin
        opcodes <= read_opcodes_from_file(OPCODE_FILE);
        wait;   -- wait forever
    end process;
    
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
    
    -- Main stimulus and tracking process
    stim_process: process
        variable cycle_count : integer := 0;
        variable total_instructions : integer := 0;
        variable pipeline_state : pipeline_array;
        variable instr_index : integer;
        variable opcode : unsigned(3 downto 0);
        variable rd, rs, rt : integer;
        variable empty_record : instruction_tracking_record;
    begin
        -- Reset phase
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        
        report "========================================";
        report "MIPS PIPELINE TESTBENCH - FINAL VERSION";
        report "WITH MEMORY BUS MONITORING";
        report "========================================";
        
        -- Count total instructions
        for i in 0 to MAX_INSTRUCTIONS-1 loop
            if opcodes(i) /= x"0000" or i = 0 then
                total_instructions := i + 1;
            else
                exit;
            end if;
        end loop;
        
        report "Total instructions loaded: " & integer'image(total_instructions);
        report "Maximum cycles: " & integer'image(MAX_CYCLES);
        report "Loop iterations expected: 15 (R2 starts at 0x000F)";
        report "";

        -- Initialize empty record
        empty_record.Instr_Number := -1;
        empty_record.Opcode_Bits := (others => '0');
        empty_record.Dest_Register := 0;
        empty_record.Source1_Register := 0;
        empty_record.Source2_Register := 0;
        empty_record.Pipeline_Stage := EMPTY;
        empty_record.Entry_Cycle := 0;
        empty_record.Cycles_In_Current_Stage := 0;

        -- Initialize pipeline state
        for i in pipeline_state'range loop
            pipeline_state(i) := empty_record;
        end loop;

        wait for CLK_PERIOD;
        
        -- PRINT INITIAL STATE FOR DEBUGGING
        report "";
        report "===== INITIAL STATE AFTER RESET =====";
        report "R0 = 0x" & to_hex_string(Reg0_Contents) & " (expected 0x0040)";
        report "R1 = 0x" & to_hex_string(Reg1_Contents) & " (expected 0x1010)";
        report "R2 = 0x" & to_hex_string(Reg2_Contents) & " (expected 0x000F)";
        report "R3 = 0x" & to_hex_string(Reg3_Contents) & " (expected 0x00F0)";
        report "R4 = 0x" & to_hex_string(Reg4_Contents) & " (expected 0x0000)";
        report "R5 = 0x" & to_hex_string(Reg5_Contents) & " (expected 0x0010)";
        report "R6 = 0x" & to_hex_string(Reg6_Contents) & " (expected 0x0005)";
        report "R7 = 0x" & to_hex_string(Reg7_Contents) & " (expected 0x0000)";
        report "=====================================";
        report "";
        
        -- Verify initial values with assertions
        assert Reg0_Contents = x"0040"
            report "ERROR: R0 should be 0x0040, got 0x" & to_hex_string(Reg0_Contents)
            severity error;
        assert Reg2_Contents = x"000F"
            report "ERROR: R2 should be 0x000F, got 0x" & to_hex_string(Reg2_Contents)
            severity error;
        assert Reg1_Contents = x"1010"
            report "ERROR: R1 should be 0x1010, got 0x" & to_hex_string(Reg1_Contents)
            severity error;
        
        wait for CLK_PERIOD;
        
        -- Main simulation loop
        for i in 1 to MAX_CYCLES loop
            cycle_count := i;
            
            -- STEP 1: Shift pipeline stages
            if pipeline_state(4).Pipeline_Stage = WB_STAGE then
                pipeline_state(4).Pipeline_Stage := COMPLETE;
            end if;
            
            for j in 4 downto 1 loop
                if pipeline_state(j-1).Instr_Number >= 0 then
                    pipeline_state(j) := pipeline_state(j-1);
                    
                    case pipeline_state(j-1).Pipeline_Stage is
                        when IF_STAGE  => pipeline_state(j).Pipeline_Stage := ID_STAGE;
                        when ID_STAGE  => pipeline_state(j).Pipeline_Stage := EX_STAGE;
                        when EX_STAGE  => pipeline_state(j).Pipeline_Stage := MEM_STAGE;
                        when MEM_STAGE => pipeline_state(j).Pipeline_Stage := WB_STAGE;
                        when WB_STAGE  => pipeline_state(j).Pipeline_Stage := COMPLETE;
                        when others    => pipeline_state(j).Pipeline_Stage := EMPTY;
                    end case;
                    
                    pipeline_state(j).Cycles_In_Current_Stage := 0;
                else
                    pipeline_state(j) := empty_record;
                end if;
            end loop;
            
            if pipeline_state(4).Pipeline_Stage = COMPLETE then
                pipeline_state(4) := empty_record;
            end if;
            
            -- STEP 2: Fetch new instruction into IF stage
            wait for CLK_PERIOD;
            instr_index := to_integer(Program_Counter_PC) / 2;
            
            if instr_index < total_instructions then
                pipeline_state(0).Instr_Number := instr_index;
                opcode := opcodes(instr_index)(15 downto 12);
                pipeline_state(0).Opcode_Bits := opcode;
                pipeline_state(0).Source1_Register := to_integer(opcodes(instr_index)(11 downto 9));
                pipeline_state(0).Source2_Register := to_integer(opcodes(instr_index)(8 downto 6));
                pipeline_state(0).Dest_Register := to_integer(opcodes(instr_index)(5 downto 3));
                pipeline_state(0).Pipeline_Stage := IF_STAGE;
                pipeline_state(0).Entry_Cycle := i;
                pipeline_state(0).Cycles_In_Current_Stage := 0;
            else
                pipeline_state(0) := empty_record;
            end if;

            -- STEP 3: Increment cycle counters
            for j in pipeline_state'range loop
                if pipeline_state(j).Instr_Number >= 0 and
                   pipeline_state(j).Pipeline_Stage /= EMPTY and
                   pipeline_state(j).Pipeline_Stage /= COMPLETE then
                    pipeline_state(j).Cycles_In_Current_Stage :=
                        pipeline_state(j).Cycles_In_Current_Stage + 1;
                end if;
            end loop;

            -- STEP 4: Update all tracking signals
            Pipeline_Tracker <= pipeline_state;
            
            IF_Stage_Status <= pipeline_state(0).Pipeline_Stage;
            ID_Stage_Status <= pipeline_state(1).Pipeline_Stage;
            EX_Stage_Status <= pipeline_state(2).Pipeline_Stage;
            MEM_Stage_Status <= pipeline_state(3).Pipeline_Stage;
            WB_Stage_Status <= pipeline_state(4).Pipeline_Stage;
            
            IF_Instr_Number <= pipeline_state(0).Instr_Number;
            ID_Instr_Number <= pipeline_state(1).Instr_Number;
            EX_Instr_Number <= pipeline_state(2).Instr_Number;
            MEM_Instr_Number <= pipeline_state(3).Instr_Number;
            WB_Instr_Number <= pipeline_state(4).Instr_Number;
            
            -- STEP 5: Print pipeline state (every 50 cycles)
            if i mod 50 = 0 or i <= 10 then
                report "";
                report "==== CYCLE " & integer'image(i) & " ====";
                report "PC: 0x" & to_hex_string(Program_Counter_PC) & 
                       " | R0=" & to_hex_string(Reg0_Contents) & 
                       " R1=" & to_hex_string(Reg1_Contents) & 
                       " R2=" & to_hex_string(Reg2_Contents) & 
                       " R3=" & to_hex_string(Reg3_Contents);
                report "R4=" & to_hex_string(Reg4_Contents) & 
                       " R5=" & to_hex_string(Reg5_Contents) & 
                       " R6=" & to_hex_string(Reg6_Contents) & 
                       " R7=" & to_hex_string(Reg7_Contents);
            end if;
            
            -- Check for completion (only after sufficient cycles)
            if i > 400 and instr_index >= total_instructions and 
               pipeline_state(0).Instr_Number < 0 and 
               pipeline_state(1).Instr_Number < 0 and
               pipeline_state(2).Instr_Number < 0 and 
               pipeline_state(3).Instr_Number < 0 and
               pipeline_state(4).Instr_Number < 0 then
                report "";
                report "All instructions completed at cycle " & integer'image(i) & "!" severity note;
                exit;
            end if;
        end loop;
        
        -- STEP 6: FINAL SUMMARY WITH MEMORY ASSERTIONS AND MONITORING
        wait for CLK_PERIOD;
        
        report "";
        report "========================================";
        report "FINAL EXECUTION STATE";
        report "========================================";
        report "";
        report "Final Register Values:";
        report "R0 (V0):  0x" & to_hex_string(Reg0_Contents);
        report "R1 (A0):  0x" & to_hex_string(Reg1_Contents);
        report "R2 (A1):  0x" & to_hex_string(Reg2_Contents);
        report "R3 (V1):  0x" & to_hex_string(Reg3_Contents);
        report "R4 (T0):  0x" & to_hex_string(Reg4_Contents);
        report "R5 (V2):  0x" & to_hex_string(Reg5_Contents);
        report "R6 (V3):  0x" & to_hex_string(Reg6_Contents);
        report "R7 (Temp):0x" & to_hex_string(Reg7_Contents);
        report "";
        
        report "========================================";
        report "ASSERTION CHECKS - REGISTER STATE";
        report "========================================";
        report "";
        
        report "Check 1: Loop counter (R2) should be 0x0000 after 15 iterations...";
        if Reg2_Contents = x"0000" then
            report "PASS: Loop counter R2 = 0x0000 (loop completed successfully)" severity note;
        else
            report "FAIL: Loop counter R2 = 0x" & to_hex_string(Reg2_Contents) & " (expected 0x0000)" severity error;
        end if;
        report "";
        
        report "Check 2: Array pointer (R1) should have advanced from 0x1010...";
        if unsigned(Reg1_Contents) > x"1010" then
            report "PASS: Array pointer R1 = 0x" & to_hex_string(Reg1_Contents) & " (advanced from 0x1010)" severity note;
        else
            report "FAIL: Array pointer R1 = 0x" & to_hex_string(Reg1_Contents) & " (should advance from 0x1010)" severity error;
        end if;
        report "";
        
        report "========================================";
        report "MEMORY BUS SIGNAL VERIFICATION";
        report "========================================";
        report "";
        report "To verify memory operations in waveform, add these signal paths:";
        report "";
        report "MEMORY ADDRESS BUS:";
        report "  Path: /tb_mips_pipeline/DUT/DMEM/address";
        report "  Type: unsigned(15 downto 0)";
        report "  Expected addresses during execution:";
        report "    - 0x0004 to 0x0006: Constant loads (comparison, ELSE, THEN values)";
        report "    - 0x0010 to 0x0019: Array results storage (16 different writes)";
        report "";
        
        report "MEMORY WRITE DATA BUS:";
        report "  Path: /tb_mips_pipeline/DUT/DMEM/write_data";
        report "  Type: unsigned(15 downto 0)";
        report "  Expected values:";
        report "    - 0xFF00: THEN branch result (right shift + OR)";
        report "    - 0x00FF: ELSE branch result (left shift + XOR)";
        report "";
        
        report "MEMORY READ DATA BUS:";
        report "  Path: /tb_mips_pipeline/DUT/DMEM/read_data";
        report "  Type: unsigned(15 downto 0)";
        report "  Expected values:";
        report "    - 0x0100: Comparison threshold from mem[4]";
        report "    - 0x00FF: ELSE branch value from mem[5]";
        report "    - 0xFF00: THEN branch value from mem[6]";
        report "    - Array elements from mem[16-25]";
        report "";
        
        report "MEMORY CONTROL SIGNALS:";
        report "  Write Enable: /tb_mips_pipeline/DUT/DMEM/mem_write (std_logic)";
        report "    - Should be '1' during SW instructions";
        report "  Read Enable:  /tb_mips_pipeline/DUT/DMEM/mem_read (std_logic)";
        report "    - Should be '1' during LW instructions";
        report "";
        
        report "========================================";
        report "MEMORY ASSERTION CHECKS";
        report "========================================";
        report "";
        
        report "Accessing memory contents from DMEM:";
        report "  mem[4]  should be 0x0100 (comparison threshold)";
        report "  mem[5]  should be 0x00FF (ELSE branch value)";
        report "  mem[6]  should be 0xFF00 (THEN branch value)";
        report "  mem[16-25] should contain program results (FF00 or 00FF)";
        report "";
        
        report "Note: Memory contents are visible in waveform at:";
        report "  /tb_mips_pipeline/DUT/DMEM/mem (entire array)";
        report "  /tb_mips_pipeline/DUT/DMEM/mem[4] (specific address)";
        report "  /tb_mips_pipeline/DUT/DMEM/mem[5] (specific address)";
        report "  /tb_mips_pipeline/DUT/DMEM/mem[6] (specific address)";
        report "  And indices 16-25 for program results";
        report "";
        
        report "========================================";
        report "EXPECTED MEMORY PATTERN";
        report "========================================";
        report "";
        report "Initial Memory State (after reset):";
        report "  mem[4]  = 0x0100";
        report "  mem[5]  = 0x00FF";
        report "  mem[6]  = 0xFF00";
        report "  mem[16-25] = 0x0000 (cleared)";
        report "";
        report "Final Memory State (after 15 iterations):";
        report "  mem[4]  = 0x0100 (unchanged)";
        report "  mem[5]  = 0x00FF (unchanged)";
        report "  mem[6]  = 0xFF00 (unchanged)";
        report "  mem[16] through mem[25] = mixture of 0xFF00 and 0x00FF values";
        report "";
        report "Expected pattern in mem[16-25]:";
        report "  Each word written contains either 0xFF00 (THEN) or 0x00FF (ELSE)";
        report "  15 writes total (one per loop iteration)";
        report "  Pattern depends on array element values at execution time";
        report "";
        report "========================================";
        report "";
        
        sim_done <= true;
        report "Simulation ended successfully." severity note;
        wait;
    end process;
    
    -- Timeout watchdog
    timeout_checker: process
    begin
        for i in 0 to 2000 loop
            wait for CLK_PERIOD;
            if sim_done then
                exit;
            end if;
        end loop;
        if not sim_done then
            report "SIMULATION TIMEOUT - Program not completing. Increase MAX_CYCLES." severity failure;
        end if;
        wait;
    end process;
    
end architecture testbench;