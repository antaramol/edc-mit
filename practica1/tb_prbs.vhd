library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_prbs is
end tb_prbs;

architecture tb_prbs_arch of tb_prbs is

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

  -- Control de la simulacion
  constant clk_period : time := 10 ns;
  signal endsim : boolean := false;

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

  -- Generación de reloj
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
    if endsim=true then
      wait;
    end if;
  end process;

  -- Proceso de estimulos
  stim_process : process
  begin
	  rst <= '1';
	  wait for 4*clk_period;
	  rst <= '0';
	  wait for 10*clk_period;
	  ena <= '1';
	  --wait for (2**N)*clk_period;
	  wait for 143*clk_period;
      ena <= '0';
	  wait for 10*clk_period;
	  endsim <= true;
	  wait;
  end process;

end tb_prbs_arch;
