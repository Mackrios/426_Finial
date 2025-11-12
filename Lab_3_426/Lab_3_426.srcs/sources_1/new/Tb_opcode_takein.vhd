-- MIPS Pipeline Testbench with Instruction State Machine
-- Tracks each instruction through all 5 pipeline stages (IF/ID/EX/MEM/WB)
-- Features: Descriptive signal names and proper instruction tracking
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
    constant OPCODE_FILE : string := "opcodes.txt";
    
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    
    -- CPU Output Signals (signals mapping to the content inside each register)
    signal Program_Counter_PC : unsigned(15 downto 0);
    signal Reg0_Contents, Reg1_Contents, Reg2_Contents, Reg3_Contents : unsigned(15 downto 0);
    signal Reg4_Contents, Reg5_Contents, Reg6_Contents, Reg7_Contents : unsigned(15 downto 0);
    
    -- Pipeline Stage Enumeration for state machine (Pipeline Stage)
    type pipeline_stage is (EMPTY, IF_STAGE, ID_STAGE, EX_STAGE, MEM_STAGE, WB_STAGE, COMPLETE);
    
    -- created pipeline component for the testbench
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
    
    -- Instruction Tracking Record (Each field clearly named)
    type instruction_tracking_record is record
        Instr_Number : integer;                    -- Which instruction (0, 1, 2, ...)
        Opcode_Bits : unsigned(3 downto 0);       -- Operation code (ADD, SUB, etc.)
        Dest_Register : integer;                   -- Rd - destination register
        Source1_Register : integer;                -- Rs - first source register (Data 1)
        Source2_Register : integer;                -- Rt - second source register (Data 2)
        Pipeline_Stage : pipeline_stage;           -- Current stage in pipeline
        Entry_Cycle : integer;                     -- Cycle when entered pipeline
        Cycles_In_Current_Stage : integer;         -- How long in current stage
    end record;
    
    -- Pipeline array: 5 stages (0=IF, 1=ID, 2=EX, 3=MEM, 4=WB)
    type pipeline_array is array (0 to 4) of instruction_tracking_record; 
    
    signal Pipeline_Tracker : pipeline_array;
    
    
    signal IF_Stage_Status : pipeline_stage;
    signal ID_Stage_Status : pipeline_stage;
    signal EX_Stage_Status : pipeline_stage;
    signal MEM_Stage_Status : pipeline_stage;
    signal WB_Stage_Status : pipeline_stage;
    
    -- more tracking signals for waveform clarity
    signal IF_Instr_Number : integer;
    signal ID_Instr_Number : integer;
    signal EX_Instr_Number : integer;
    signal MEM_Instr_Number : integer;
    signal WB_Instr_Number : integer;

    -- File reading function, reads in python file with MIPS instructions
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
    
    function get_opcode_name(opcode_bits : unsigned(3 downto 0)) return string is
    begin
        case opcode_bits is
            when "0000" => return "ADD"; when "0001" => return "SUB"; when "0010" => return "AND";
            when "0011" => return "OR "; when "0100" => return "SLL"; when "0101" => return "SRL";
            when "0110" => return "SRA"; when "0111" => return "XOR"; when "1000" => return "LW ";
            when "1001" => return "SW "; when "1010" => return "ADI"; when "1011" => return "BEQ";
            when "1100" => return "BGT"; when "1101" => return "BGE"; when "1110" => return "B  ";
            when "1111" => return "J  "; when others => return "???";
        end case;
    end function;
    
    function get_register_name(reg_num : integer) return string is
    begin
        case reg_num is
            when 0 => return "R0"; when 1 => return "R1"; when 2 => return "R2";
            when 3 => return "R3"; when 4 => return "R4"; when 5 => return "R5";
            when 6 => return "R6"; when 7 => return "R7"; when others => return "??";
        end case;
    end function;
    
    function get_operation_symbol(opcode_bits : unsigned(3 downto 0)) return string is
    begin
        case opcode_bits is
            when "0000" => return " + "; when "0001" => return " - "; when "0010" => return " AND ";
            when "0011" => return " OR "; when "0111" => return " XOR "; when "0100" => return " << ";
            when "0101" => return " >> "; when others => return " ? ";
        end case;
    end function;
    
    function stage_to_string(stage : pipeline_stage) return string is
    begin
        case stage is
            when EMPTY => return "EMPTY         ";
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
        
        -- Count total instructions
        for i in 0 to MAX_INSTRUCTIONS-1 loop
            if opcodes(i) /= x"0000" or i = 0 then
                total_instructions := i + 1;
            else
                exit;
            end if;
        end loop;

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
        
        -- Main simulation loop
        for i in 1 to 100 loop 
            cycle_count := i;
            
            -- STEP 1: Shift pipeline stages (from WB back to IF)
            -- Move WB -> complete (and clear it)
            if pipeline_state(4).Pipeline_Stage = WB_STAGE then
                pipeline_state(4).Pipeline_Stage := COMPLETE;
            end if;
            
            -- Shift stages: MEM->WB, EX->MEM, ID->EX, IF->ID
            for j in 4 downto 1 loop
                if pipeline_state(j-1).Instr_Number >= 0 then
                    pipeline_state(j) := pipeline_state(j-1);
                    
                    -- Update stage
                    case pipeline_state(j-1).Pipeline_Stage is
                        when IF_STAGE  => pipeline_state(j).Pipeline_Stage := ID_STAGE;
                        when ID_STAGE  => pipeline_state(j).Pipeline_Stage := EX_STAGE;
                        when EX_STAGE  => pipeline_state(j).Pipeline_Stage := MEM_STAGE;
                        when MEM_STAGE => pipeline_state(j).Pipeline_Stage := WB_STAGE;
                        when WB_STAGE  => pipeline_state(j).Pipeline_Stage := COMPLETE;
                        when others    => pipeline_state(j).Pipeline_Stage := EMPTY;
                    end case;
                    
                    -- Reset cycle counter for new stage
                    pipeline_state(j).Cycles_In_Current_Stage := 0;
                else
                    pipeline_state(j) := empty_record;
                end if;
            end loop;
            
            -- Clear completed instruction from WB stage
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

            -- STEP 3: Increment cycle counters for active instructions
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
            
            -- STEP 5: Print pipeline state
            report "";
            report "==== CYCLE " & integer'image(i) & " ====";
            report "PC: 0x" & to_hex_string(Program_Counter_PC) & 
                   " | R0=" & to_hex_string(Reg0_Contents) & 
                   " R1=" & to_hex_string(Reg1_Contents) & 
                   " R4=" & to_hex_string(Reg4_Contents) & 
                   " R5=" & to_hex_string(Reg5_Contents) & 
                   " R6=" & to_hex_string(Reg6_Contents) & 
                   " R7=" & to_hex_string(Reg7_Contents);
            report "";
            report "Pipeline Tracker - Instruction Flow:";
            report "Stage | Instr# | Stage           | Operation       | Cycles in Stage | Total Cycles";
            report "======================================================================================";
            
            for j in pipeline_state'range loop
                if pipeline_state(j).Instr_Number >= 0 then
                    opcode := pipeline_state(j).Opcode_Bits;
                    rd := pipeline_state(j).Dest_Register;
                    rs := pipeline_state(j).Source1_Register;
                    rt := pipeline_state(j).Source2_Register;
                    
                    report "  " & integer'image(j) & "   |   " &
                           integer'image(pipeline_state(j).Instr_Number) & "    | " &
                           stage_to_string(pipeline_state(j).Pipeline_Stage) & " | " &
                           get_opcode_name(opcode) & " " &
                           get_register_name(rd) & "," & 
                           get_register_name(rs) & "," &
                           get_register_name(rt) & "   | " &
                           integer'image(pipeline_state(j).Cycles_In_Current_Stage) & "               | " &
                           integer'image(i - pipeline_state(j).Entry_Cycle + 1);
                else
                    report "  " & integer'image(j) & "   |  --    | " &
                           stage_to_string(EMPTY) & " | --              | --              | --";
                end if;
            end loop;
            
            report "======================================================================================";
            
            -- Check for completion
            if instr_index >= total_instructions and 
               pipeline_state(0).Instr_Number < 0 and 
               pipeline_state(1).Instr_Number < 0 and
               pipeline_state(2).Instr_Number < 0 and 
               pipeline_state(3).Instr_Number < 0 and
               pipeline_state(4).Instr_Number < 0 then
                report "All instructions completed successfully!" severity note;
                exit;
            end if;
        end loop;
        
        sim_done <= true;
        report "Simulation ended." severity note;
        wait;
    end process;
    
    -- Timeout watchdog
    timeout_checker: process
    begin
        for i in 0 to 400 loop
            wait for CLK_PERIOD;
            if sim_done then
                exit;
            end if;
        end loop;
        if not sim_done then
            report "SIMULATION TIMEOUT - Check for pipeline stalls or infinite loops" severity failure;
        end if;
        wait;
    end process;
    
end architecture testbench;