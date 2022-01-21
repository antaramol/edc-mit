library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity prbs_tb is
  generic (runner_cfg : string);
end;

architecture bench of prbs_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports
  signal rst : std_ulogic := '0';
  signal clk : std_ulogic;
  signal ena : std_ulogic := '0';
  signal signo : std_ulogic;

begin

  prbs_inst : entity src_lib.prbs
    port map (
      rst => rst,
      clk => clk,
      ena => ena,
      signo => signo
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("143_ciclos") then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        --wait for (2**N)*clk_period;
        wait for 143*clk_period;
        ena <= '0';
        wait for 10*clk_period;

      elsif run("arranque_stop")then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        wait for 50*clk_period;
        ena <= '0';
        
        wait for 10*clk_period;
        ena <= '1';
        wait for 50*clk_period;
        ena <= '0';
        wait for 10*clk_period;
      end if;
    end loop;

    test_runner_cleanup(runner);

  end process main;

  clk_process : process
  begin
  clk <= '1';
  wait for clk_period/2;
  clk <= '0';
  wait for clk_period/2;
  end process clk_process;

end;
