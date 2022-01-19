library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_prbs is
  generic (runner_cfg : string);
end;

architecture bench of tb_prbs is

  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports

  -- Declaramos el registro como component
  component prbs is
    port (
        rst    : in  std_ulogic;
        clk    : in  std_ulogic;
        ena    : in  std_ulogic;
        signo  : out std_ulogic;
        secuencia_salida : out std_ulogic;
        valido : out std_ulogic
     );
  end component;

  -- Declaramos los signals que necesitamos para conectar
  -- la instancia del prbs
  signal rst : std_ulogic := '0';
  signal clk : std_ulogic := '0';
  signal ena : std_ulogic := '0';
  signal signo : std_ulogic := '0';
  signal secuencia_salida : std_ulogic := '0';
  signal valido : std_ulogic := '1';

begin

  -- Instanciamos el registro
  prbs_inst : prbs
  port map (
    rst => rst,
    clk => clk,
    ena => ena,
    signo => signo,
    secuencia_salida => secuencia_salida,
    valido => valido
  );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("registro") then
        info("Prueba de generación del registro");
        wait for 2*clk_period;
        rst <= '1';
	      wait for 4*clk_period;
	      rst <= '0';
	      wait for 10*clk_period;
	      ena <= '1';
	      --wait for (2**N)*clk_period;
	      wait for 143*clk_period;
        ena <= '0';
	      wait for 10*clk_period;
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


