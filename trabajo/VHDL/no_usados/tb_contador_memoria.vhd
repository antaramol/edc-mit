library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity top_cont_mem_tb is
  generic (runner_cfg : string);
end;

architecture bench of top_cont_mem_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant DATA_WIDTH : integer := 8;
  constant ADDR_WIDTH : integer := 8;

  -- Ports
  signal rst : std_logic;
  signal clk : std_logic;
  signal y : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal y_valid : std_logic;
  signal estim_valid : std_logic;

begin

  top_cont_mem_inst : entity src_lib.top_cont_mem
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      rst => rst,
      clk => clk,
      y => y,
      y_valid => y_valid,
      estim_valid => estim_valid
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("contador_avanza") then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4 * clk_period;
        rst <= '0';
        wait for 4 * clk_period;
        
        y_valid <= '1';
        y <= std_logic_vector(to_unsigned(0,DATA_WIDTH));
        wait for clk_period;
        y <= std_logic_vector(to_unsigned(1,DATA_WIDTH));

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
