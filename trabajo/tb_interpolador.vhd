library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity interpolator_tb is
  generic (runner_cfg : string);
end;

architecture bench of interpolator_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports
  signal clk : std_logic;
  signal rst : std_logic := '0';
  signal inf : complex10;
  signal sup : complex10;
  signal valid : std_logic;
  signal estim : complex10;
  signal estim_valid : std_logic;

begin

  interpolator_inst : entity src_lib.interpolator
    port map (
      clk => clk,
      rst => rst,
      inf => inf,
      sup => sup,
      valid => valid,
      estim => estim,
      estim_valid => estim_valid
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("general") then

        wait for 10 * clk_period;
        rst <= '1';
        wait for 10 * clk_period;
        rst <= '0';

        wait for 10 * clk_period;
        valid <= '1';
        inf.re <= to_signed(4*100/3,10); -- Están multiplicados por 4/3 para simular el efecto de los pilotos,
        inf.im <= to_signed(4*100/3,10); -- ya que el bloque interpolador lo compensa.
        sup.re <= to_signed(4*300/3,10);
        sup.im <= to_signed(4*300/3,10);
        
        wait for clk_period;
        valid <= '0';
        
        wait for 100 * clk_period;
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
