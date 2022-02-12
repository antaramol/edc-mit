library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity contador_tb is
  generic (runner_cfg : string);
end;

architecture bench of contador_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant N : integer := 8;

  -- Ports
  signal rst : std_logic := '0';
  signal clk : std_logic;
  signal ena : std_logic := '0';
  -- signal rst_control : std_logic := '0';
  signal cuenta : unsigned(N-1 downto 0);

begin

  contador_inst : entity src_lib.contador
    generic map (
      N => N
    )
    port map (
      rst => rst,
      clk => clk,
      ena => ena,
      cuenta => cuenta
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("cuenta_max") then
        wait for 4 * clk_period;
        rst <= '1';
	    wait for 4*clk_period;
	    rst <= '0';
	    wait for 10*clk_period;
	    ena <= '1';
	    wait for (2**N)*clk_period;

      elsif run("arranque_stop") then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        wait for 40 * clk_period;
        ena <= '0';
        wait for 10 * clk_period;

        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        wait for 40 * clk_period;
        ena <= '0';
        wait for 10 * clk_period;

        ena <= '1';
        wait for 40 * clk_period;
        ena <= '0';
        wait for 10 * clk_period;
        
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
