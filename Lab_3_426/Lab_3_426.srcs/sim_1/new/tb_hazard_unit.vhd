library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_hazard_unit is
end entity;

architecture behavior of tb_hazard_unit is

    -- Inputs to hazard_unit
    signal rs_id         : unsigned(2 downto 0) := (others => '0');
    signal rt_id         : unsigned(2 downto 0) := (others => '0');
    signal rs_ex         : unsigned(2 downto 0) := (others => '0');
    signal rt_ex         : unsigned(2 downto 0) := (others => '0');
    signal write_reg_ex  : unsigned(2 downto 0) := (others => '0');
    signal mem_read_ex   : std_logic := '0';
    signal reg_write_ex  : std_logic := '0';
    signal write_reg_mem : unsigned(2 downto 0) := (others => '0');
    signal reg_write_mem : std_logic := '0';
    signal write_reg_wb  : unsigned(2 downto 0) := (others => '0');
    signal reg_write_wb  : std_logic := '0';
    signal branch_taken  : std_logic := '0';
    signal jump_taken    : std_logic := '0';

    -- Outputs from hazard_unit
    signal stall         : std_logic;
    signal flush_if_id   : std_logic;
    signal flush_id_ex   : std_logic;
    signal forward_a     : unsigned(1 downto 0);
    signal forward_b     : unsigned(1 downto 0);

    component hazard_unit
      port(
        rs_id          : in  unsigned(2 downto 0);
        rt_id          : in  unsigned(2 downto 0);
        rs_ex          : in  unsigned(2 downto 0);
        rt_ex          : in  unsigned(2 downto 0);
        write_reg_ex   : in  unsigned(2 downto 0);
        mem_read_ex    : in  std_logic;
        reg_write_ex   : in  std_logic;
        write_reg_mem  : in  unsigned(2 downto 0);
        reg_write_mem  : in  std_logic;
        write_reg_wb   : in  unsigned(2 downto 0);
        reg_write_wb   : in  std_logic;
        branch_taken   : in  std_logic;
        jump_taken     : in  std_logic;
        stall          : out std_logic;
        flush_if_id    : out std_logic;
        flush_id_ex    : out std_logic;
        forward_a      : out unsigned(1 downto 0);
        forward_b      : out unsigned(1 downto 0)
      );
    end component;

begin

    DUT: hazard_unit
      port map(
        rs_id          => rs_id,
        rt_id          => rt_id,
        rs_ex          => rs_ex,
        rt_ex          => rt_ex,
        write_reg_ex   => write_reg_ex,
        mem_read_ex    => mem_read_ex,
        reg_write_ex   => reg_write_ex,
        write_reg_mem  => write_reg_mem,
        reg_write_mem  => reg_write_mem,
        write_reg_wb   => write_reg_wb,
        reg_write_wb   => reg_write_wb,
        branch_taken   => branch_taken,
        jump_taken     => jump_taken,
        stall          => stall,
        flush_if_id    => flush_if_id,
        flush_id_ex    => flush_id_ex,
        forward_a      => forward_a,
        forward_b      => forward_b
      );

    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- TEST 1: No hazard (everything zero) ? no stall, no forwarding
        ----------------------------------------------------------------
        rs_id         <= "000";
        rt_id         <= "000";
        rs_ex         <= "000";
        rt_ex         <= "000";
        write_reg_ex  <= "000";
        mem_read_ex   <= '0';
        reg_write_ex  <= '0';
        write_reg_mem <= "000";
        reg_write_mem <= '0';
        write_reg_wb  <= "000";
        reg_write_wb  <= '0';
        branch_taken  <= '0';
        jump_taken    <= '0';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- TEST 2: LOAD-USE hazard
        -- EX stage: load writing r1 (write_reg_ex="001", mem_read_ex='1')
        -- ID stage: instruction uses r1 as rs_id ("001")
        -- Expect: stall = '1', flush_id_ex = '1'
        ----------------------------------------------------------------
        rs_id         <= "001";   -- uses r1 in ID
        rt_id         <= "010";
        write_reg_ex  <= "001";   -- load writes r1
        mem_read_ex   <= '1';     -- this is a load
        reg_write_ex  <= '1';
        write_reg_mem <= "000";
        reg_write_mem <= '0';
        write_reg_wb  <= "000";
        reg_write_wb  <= '0';
        branch_taken  <= '0';
        jump_taken    <= '0';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- TEST 3: EX/MEM ? EX forwarding on A input
        -- MEM stage: reg_write_mem='1', write_reg_mem="011"
        -- EX stage: rs_ex = "011" ? expect forward_a = "10"
        ----------------------------------------------------------------
        mem_read_ex   <= '0';
        write_reg_ex  <= "000";
        reg_write_ex  <= '0';
        rs_id         <= "000";
        rt_id         <= "000";

        rs_ex         <= "011";   -- needs r3
        rt_ex         <= "000";
        write_reg_mem <= "011";   -- r3 written in MEM
        reg_write_mem <= '1';
        write_reg_wb  <= "000";
        reg_write_wb  <= '0';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- TEST 4: MEM/WB ? EX forwarding on B input
        -- WB stage: reg_write_wb='1', write_reg_wb="100"
        -- EX stage: rt_ex = "100" ? expect forward_b = "01"
        ----------------------------------------------------------------
        rs_ex         <= "000";
        rt_ex         <= "100";   -- needs r4 in EX
        write_reg_mem <= "000";
        reg_write_mem <= '0';
        write_reg_wb  <= "100";   -- r4 written in WB
        reg_write_wb  <= '1';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- TEST 5: Branch/JUMP flush
        -- Expect flush_if_id = '1', flush_id_ex = '1'
        ----------------------------------------------------------------
        branch_taken  <= '1';
        jump_taken    <= '0';
        wait for 20 ns;

        branch_taken  <= '0';
        jump_taken    <= '1';
        wait for 20 ns;

        wait;
    end process;

end architecture;
