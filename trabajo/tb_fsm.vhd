library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity FSM_tb is
  generic (runner_cfg : string);
end;

architecture bench of FSM_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant DATA_WIDTH : integer := 20;
  constant ADDR_WIDTH : integer := 8;

  -- Ports
  signal rst : std_logic;
  signal clk : std_logic;
  signal addr_mem : unsigned (ADDR_WIDTH-1 downto 0);
  signal data : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal signo : std_logic;
  signal en_PRBS : std_logic;
  signal inf : complex10;
  signal sup : complex10;
  signal start_stop : std_logic;
  signal valido : std_logic;
  signal interpol_ok : std_logic;
  signal ultima_portadora : std_logic;

begin

  FSM_inst : entity src_lib.FSM
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      rst => rst,
      clk => clk,
      --addr_mem => addr_mem,
      data => data,
      addr_cont => addr_cont,
      signo => signo,
      en_PRBS => en_PRBS,
      inf => inf,
      sup => sup,
      start_stop => start_stop,
      valido => valido,
      interpol_ok => interpol_ok,
      ultima_portadora => ultima_portadora
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait for 100 * clk_period;
        test_runner_cleanup(runner);
        
      elsif run("test_0") then
        info("Hello world test_0");
        wait for 100 * clk_period;
        test_runner_cleanup(runner);
      end if;
    end loop;
  end process main;

  clk_process : process
  begin
  clk <= '1';
  wait for clk_period/2;
  clk <= '0';
  wait for clk_period/2;
  end process clk_process;

end;
