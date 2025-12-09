library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_program is
end entity;

architecture behavior of tb_program is
    
    constant CLK_PERIOD : time := 10 ns;
    constant MAX_LOOPS  : integer := 10;  

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';

    -- Outputs from CPU
    signal pc : unsigned(15 downto 0);
    signal r0,r1,r2,r3,r4,r5,r6,r7 : unsigned(15 downto 0);

    -- Debug signals
    signal dbg_if_id_instr      : unsigned(15 downto 0);
    signal dbg_id_ex_opcode     : unsigned(3 downto 0);
    signal dbg_ex_mem_alu_res   : unsigned(15 downto 0);
    signal dbg_mem_wb_write_reg : unsigned(2 downto 0);

    component pipelined_cpu is
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
            reg7   : out unsigned(15 downto 0);

            dbg_if_id_instr      : out unsigned(15 downto 0);
            dbg_id_ex_opcode     : out unsigned(3 downto 0);
            dbg_ex_mem_alu_res   : out unsigned(15 downto 0);
            dbg_mem_wb_write_reg : out unsigned(2 downto 0)
        );
    end component;

    procedure wait_cycles(n : integer) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

    function hex(u : unsigned) return string is
        variable s : string(1 to 4);
        variable t : unsigned(15 downto 0) := u;
        constant H : string := "0123456789ABCDEF";
    begin
        for i in 4 downto 1 loop
            s(i) := H(to_integer(t(3 downto 0))+1);
            t := shift_right(t,4);
        end loop;
        return s;
    end function;

   
    type mem_array is array(0 to 255) of unsigned(15 downto 0);


    procedure step_model(
        variable exp_r0 : inout unsigned(15 downto 0);
        variable exp_r1 : inout unsigned(15 downto 0);
        variable exp_r2 : inout unsigned(15 downto 0);
        variable exp_r3 : inout unsigned(15 downto 0);
        variable exp_r4 : inout unsigned(15 downto 0);
        variable exp_r5 : inout unsigned(15 downto 0);
        variable exp_r6 : inout unsigned(15 downto 0);
        variable exp_r7 : inout unsigned(15 downto 0);
        variable mem    : inout mem_array
    ) is
        variable idx : integer;
        variable t0  : unsigned(15 downto 0);
    begin
        -- while (a1 > 0) do ...
        if exp_r6 = x"0000" then
            return;
        end if;

        -- a1 = a1 - 1;
        exp_r6 := exp_r6 - 1;

        -- t0 = Mem[a0];
        idx := to_integer(exp_r5(7 downto 1));  -- same addressing as data_memory
        t0  := mem(idx);
        exp_r4 := t0;  -- t0 register

        -- if (t0 > 0100hex) then ...
        if t0 > x"0100" then
            -- v0 = v0 � 8;  (logical >> 3)
            exp_r0 := shift_right(exp_r0, 3);

            -- v1 = v1 | v0;
            exp_r1 := exp_r1 or exp_r0;

            -- Mem[a0] = FF00hex;
            mem(idx) := x"FF00";
        else
            -- v2 = v2 � 4;  (<< 2)
            exp_r2 := shift_left(exp_r2, 2);

            -- v3 = v3 ? v2;  (xor)
            exp_r3 := exp_r3 xor exp_r2;

            -- Mem[a0] = 00FFhex;
            mem(idx) := x"00FF";
        end if;

        -- a0 = a0 + 2;
        exp_r5 := exp_r5 + 2;
    end procedure;

begin

    ----------------------------------------------------------------------
    -- Clock
    ----------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
    end process;

    ----------------------------------------------------------------------
    -- DUT
    ----------------------------------------------------------------------
    DUT: pipelined_cpu
        port map(
            clk  => clk,
            rst  => rst,
            pc_out => pc,
            reg0 => r0,
            reg1 => r1,
            reg2 => r2,
            reg3 => r3,
            reg4 => r4,
            reg5 => r5,
            reg6 => r6,
            reg7 => r7,
            dbg_if_id_instr      => dbg_if_id_instr,
            dbg_id_ex_opcode     => dbg_id_ex_opcode,
            dbg_ex_mem_alu_res   => dbg_ex_mem_alu_res,
            dbg_mem_wb_write_reg => dbg_mem_wb_write_reg
        );

    ----------------------------------------------------------------------
    -- MAIN TEST
    ----------------------------------------------------------------------
    stim_proc : process
        -- expected registers
        variable exp_r0,exp_r1,exp_r2,exp_r3 : unsigned(15 downto 0);
        variable exp_r4,exp_r5,exp_r6,exp_r7 : unsigned(15 downto 0);
        -- golden memory
        variable exp_mem : mem_array;
        -- loop counter
        variable loop_count : integer := 0;
    begin
        -- Clear memory
        for i in 0 to 255 loop
            exp_mem(i) := (others => '0');
        end loop;

        -- Constants region
        exp_mem(4)  := x"0100";
        exp_mem(5)  := x"00FF";
        exp_mem(6)  := x"FF00";

        -- Pseudocode data at $a0 = 0x0010  -> mem(8..12)
        exp_mem(8)  := x"0101";  -- Mem[$a0]
        exp_mem(9)  := x"0110";  -- Mem[$a0+2]
        exp_mem(10) := x"0011";  -- Mem[$a0+4]
        exp_mem(11) := x"00F0";  -- Mem[$a0+6]
        exp_mem(12) := x"00FF";  -- Mem[$a0+8]

        -- r0=v0, r1=v1, r2=v2, r3=v3, r4=t0, r5=a0, r6=a1, r7=temp
        exp_r0 := x"0040";  -- v0
        exp_r1 := x"1010";  -- v1
        exp_r2 := x"000F";  -- v2
        exp_r3 := x"00F0";  -- v3
        exp_r4 := x"0000";  -- t0
        exp_r5 := x"0010";  -- a0
        exp_r6 := x"0005";  -- a1
        exp_r7 := x"0000";  -- temp

        rst <= '1';
        wait_cycles(5);
        rst <= '0';
        wait_cycles(5);

        report "================ INITIAL STATE (HW) ================" severity note;
        report "R0=" & hex(r0) & "  R1=" & hex(r1) &
               "  R2=" & hex(r2) & "  R3=" & hex(r3) severity note;
        report "R4=" & hex(r4) & "  R5=" & hex(r5) &
               "  R6=" & hex(r6) & "  R7=" & hex(r7) severity note;

        ------------------------------------------------------------------
        -- asserting if initial registers matches what is shown in the simulation
        ------------------------------------------------------------------
        assert r0 = exp_r0 report "Initial R0 mismatch. Exp=" &
              hex(exp_r0) & " got=" & hex(r0) severity error;
        assert r1 = exp_r1 report "Initial R1 mismatch. Exp=" &
              hex(exp_r1) & " got=" & hex(r1) severity error;
        assert r2 = exp_r2 report "Initial R2 mismatch. Exp=" &
              hex(exp_r2) & " got=" & hex(r2) severity error;
        assert r3 = exp_r3 report "Initial R3 mismatch. Exp=" &
              hex(exp_r3) & " got=" & hex(r3) severity error;
        assert r4 = exp_r4 report "Initial R4 mismatch. Exp=" &
              hex(exp_r4) & " got=" & hex(r4) severity error;
        assert r5 = exp_r5 report "Initial R5 mismatch. Exp=" &
              hex(exp_r5) & " got=" & hex(r5) severity error;
        assert r6 = exp_r6 report "Initial R6 mismatch. Exp=" &
              hex(exp_r6) & " got=" & hex(r6) severity error;
        assert r7 = exp_r7 report "Initial R7 mismatch. Exp=" &
              hex(exp_r7) & " got=" & hex(r7) severity error;

        ------------------------------------------------------------------
        -- Run loop according to the correct outputs
        ------------------------------------------------------------------
        while (exp_r6 /= x"0000") and (loop_count < MAX_LOOPS) loop

            loop_count := loop_count + 1;

            report "---------- GOLDEN LOOP " & integer'image(loop_count) &
                   " (a1=" & hex(exp_r6) & ") ----------" severity note;

            
            step_model(exp_r0, exp_r1, exp_r2, exp_r3,
                       exp_r4, exp_r5, exp_r6, exp_r7,
                       exp_mem);

            wait_cycles(200);

            -- Compare each register to expected; if any mismatch,
            -- assert incorrect output.
            assert r0 = exp_r0 report
                "Loop " & integer'image(loop_count) &
                ": R0 (v0) mismatch. Exp=" & hex(exp_r0) &
                " got=" & hex(r0) severity error;

            assert r1 = exp_r1 report
                "Loop " & integer'image(loop_count) &
                ": R1 (v1) mismatch. Exp=" & hex(exp_r1) &
                " got=" & hex(r1) severity error;

            assert r2 = exp_r2 report
                "Loop " & integer'image(loop_count) &
                ": R2 (v2) mismatch. Exp=" & hex(exp_r2) &
                " got=" & hex(r2) severity error;

            assert r3 = exp_r3 report
                "Loop " & integer'image(loop_count) &
                ": R3 (v3) mismatch. Exp=" & hex(exp_r3) &
                " got=" & hex(r3) severity error;

            assert r4 = exp_r4 report
                "Loop " & integer'image(loop_count) &
                ": R4 (t0) mismatch. Exp=" & hex(exp_r4) &
                " got=" & hex(r4) severity error;

            assert r5 = exp_r5 report
                "Loop " & integer'image(loop_count) &
                ": R5 (a0) mismatch. Exp=" & hex(exp_r5) &
                " got=" & hex(r5) severity error;

            assert r6 = exp_r6 report
                "Loop " & integer'image(loop_count) &
                ": R6 (a1) mismatch. Exp=" & hex(exp_r6) &
                " got=" & hex(r6) severity error;

            assert r7 = exp_r7 report
                "Loop " & integer'image(loop_count) &
                ": R7 (temp) mismatch. Exp=" & hex(exp_r7) &
                " got=" & hex(r7) severity error;

            report "HW after loop " & integer'image(loop_count) & ":" severity note;
            report "  R0=" & hex(r0) & "  R1=" & hex(r1) &
                   "  R2=" & hex(r2) & "  R3=" & hex(r3) severity note;
            report "  R4=" & hex(r4) & "  R5=" & hex(r5) &
                   "  R6=" & hex(r6) & "  R7=" & hex(r7) severity note;

        end loop;

        ------------------------------------------------------------------
        -- Final checks
        ------------------------------------------------------------------
        assert loop_count = 5 report
            "Expected 5 loop iterations; got " &
            integer'image(loop_count) severity error;

        assert r6 = x"0000" report
            "Final a1 (R6) is not zero; loop did not terminate correctly"
            severity error;

        -- exp final state: v0=0001, v1=1019, v2=03C0, v3=03FC,
        -- a0=001A, a1=0000, t0=00FF, temp=0000.
        assert r0 = x"0001" report
            "Final R0 mismatch vs known expected result (0001)" severity error;
        assert r1 = x"1019" report
            "Final R1 mismatch vs known expected result (1019)" severity error;
        assert r2 = x"03C0" report
            "Final R2 mismatch vs known expected result (03C0)" severity error;
        assert r3 = x"03FC" report
            "Final R3 mismatch vs known expected result (03FC)" severity error;
        assert r5 = x"001A" report
            "Final R5 (a0) mismatch vs known expected result (001A)" severity error;
        assert r6 = x"0000" report
            "Final R6 (a1) mismatch vs known expected result (0000)" severity error;

        wait;
    end process;

end architecture;
