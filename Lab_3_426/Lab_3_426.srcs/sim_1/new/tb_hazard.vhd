library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_hazards is
end entity;

architecture behavior of tb_hazards is

    constant CLK_PERIOD : time := 10 ns;

    -- CPU signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';

    signal pc_out : unsigned(15 downto 0);
    signal r0,r1,r2,r3,r4,r5,r6,r7 : unsigned(15 downto 0);

    signal dbg_if_id_instr      : unsigned(15 downto 0);
    signal dbg_id_ex_opcode     : unsigned(3 downto 0);
    signal dbg_ex_mem_alu_res   : unsigned(15 downto 0);
    signal dbg_mem_wb_write_reg : unsigned(2 downto 0);

    -- Testbench instruction memory
    type mem_array is array(0 to 31) of unsigned(15 downto 0);
    signal IMEM : mem_array := (

      ------------------------------------------------------------------
      -- Test 1: EX/MEM Forwarding
      ------------------------------------------------------------------
      -- ADD r1 = r2 + r3
      -- R-format: opcode=0000, rs=010, rt=011, rd=001, func=000
      0 => x"0230",

      -- ADD r4 = r1 + r5  (needs EX/MEM forwarding)
      -- rs=001, rt=101, rd=100
      1 => x"0580",

      ------------------------------------------------------------------
      -- Test 2: MEM/WB Forwarding
      ------------------------------------------------------------------
      -- ADD r1 = r2 + r3
      2 => x"0230",

      -- NOP
      3 => x"0000",

      -- ADD r4 = r1 + r5 (needs MEM/WB forwarding)
      4 => x"0580",

      ------------------------------------------------------------------
      -- Test 3: LOAD-USE STALL
      ------------------------------------------------------------------
      -- LW r1, 0(r2)
      -- opcode=0001, rs=010, rt=001, imm=000000
      5 => x"1210",

      -- ADD r3 = r1 + r4  (must stall 1 cycle)
      -- rs=001, rt=100, rd=011
      6 => x"0340",

      others => x"0000"
    );

    --------------------------------------------------------------------
    -- Override CPU instruction fetch
    --------------------------------------------------------------------
    signal imem_instr : unsigned(15 downto 0);

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

begin

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Manual IMEM lookup (word addressing)
    --------------------------------------------------------------------
    imem_instr <= IMEM(to_integer(pc_out(7 downto 1)));

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    DUT: pipelined_cpu
      port map(
        clk => clk,
        rst => rst,
        pc_out => pc_out,

        reg0 => r0, reg1 => r1, reg2 => r2, reg3 => r3,
        reg4 => r4, reg5 => r5, reg6 => r6, reg7 => r7,

        dbg_if_id_instr      => dbg_if_id_instr,
        dbg_id_ex_opcode     => dbg_id_ex_opcode,
        dbg_ex_mem_alu_res   => dbg_ex_mem_alu_res,
        dbg_mem_wb_write_reg => dbg_mem_wb_write_reg
      );

    --------------------------------------------------------------------
    -- Testbench Stimulus
    --------------------------------------------------------------------
    stim : process
    begin
        -- Reset
        rst <= '1';
        wait for 50 ns;
        rst <= '0';

        ----------------------------------------------------------------
        -- Run long enough for all hazards to manifest
        ----------------------------------------------------------------
        wait for 800 ns;

        report "======== FINAL REGISTER STATE ========" severity note;
        report "r1=" & integer'image(to_integer(r1)) severity note;
        report "r4=" & integer'image(to_integer(r4)) severity note;
        report "r3=" & integer'image(to_integer(r3)) severity note;

        wait;
    end process;

end architecture;
