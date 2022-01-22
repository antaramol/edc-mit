library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_dpram is
  generic (runner_cfg : string;
    DATA_WIDTH : integer := 20; -- Será puesta a 20 en nuestro top_level para facilitar la lectura de los datos
    ADDR_WIDTH : integer := 8
  );
end;

architecture tb_dpram_arch of tb_dpram is


  -- Clock period
  constant clk_period : time := 5 ns;

  
  -- Ports
  signal clk : std_logic := '0';
  signal addri_a : unsigned (ADDR_WIDTH-1 downto 0) := (OTHERS => '0');
  signal datai_a : std_logic_vector (DATA_WIDTH-1 downto 0) := (OTHERS => '0');
  signal we_a : std_logic := '0';
  signal datao_a : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal addri_b : unsigned (ADDR_WIDTH-1 downto 0) := (OTHERS => '0');
  signal datai_b : std_logic_vector (DATA_WIDTH-1 downto 0) := (OTHERS => '0');
  signal we_b : std_logic := '0';
  signal datao_b : std_logic_vector (DATA_WIDTH-1 downto 0);

begin

  dpram_inst : entity src_lib.dpram
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      clk_a => clk,
      clk_b => clk,
      addri_a => addri_a,
      datai_a => datai_a,
      we_a => we_a,
      datao_a => datao_a,
      addri_b => addri_b,
      datai_b => datai_b,
      we_b => we_b,
      datao_b => datao_b
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("lectura_escritura") then

        wait for 15 * clk_period;
        we_a <= '1';
        addri_a <= to_unsigned(8, ADDR_WIDTH);
        datai_a <= std_logic_vector(to_unsigned(5,DATA_WIDTH));
        wait for clk_period;
        we_a <= '0';
        wait for 10 * clk_period;
        addri_b <= to_unsigned(8, ADDR_WIDTH);
        wait for 50 * clk_period;

      elsif run("leer_escribir_simul") then

        wait for 15 * clk_period;
        addri_a <= to_unsigned(8, ADDR_WIDTH);
        datai_a <= std_logic_vector(to_unsigned(10,DATA_WIDTH));
        addri_b <= to_unsigned(8, ADDR_WIDTH);
        wait for clk_period;
        we_a <= '1';
        wait for clk_period;
        we_a <= '0';
        wait for 10 * clk_period;
        addri_b <= to_unsigned(8, ADDR_WIDTH);

        wait for 50 * clk_period;

        addri_a <= to_unsigned(8, ADDR_WIDTH);
        datai_a <= std_logic_vector(to_unsigned(5,DATA_WIDTH));
        --wait for clk_period;
        we_a <= '1';
        wait for clk_period;
        we_a <= '0';
        wait for 50 * clk_period;

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

end tb_dpram_arch; 
