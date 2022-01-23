library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

library src_lib;
use src_lib.edc_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;



entity top_level_tb is
  generic (runner_cfg : string);
end;

architecture bench of top_level_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant DATA_WIDTH : integer := 20;
  constant ADDR_WIDTH : integer := 8;

  -- Ports
  signal rst : std_logic;
  signal clk : std_logic;
  signal y : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal y_valid : std_logic;
  signal estim : complex10;
  signal estim_valid : std_logic;
  signal portadora_s : real;
  signal y_re, y_im :signed (DATA_WIDTH/2-1 downto 0);
 

begin

  top_level_inst : entity src_lib.top_level
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      rst => rst,
      clk => clk,
      y => y,
      y_valid => y_valid,
      estim => estim,
      estim_valid => estim_valid
    );

  main : process
    -- variable portadoras_re, portadoras_im : integer_array_t;
       
    variable i : integer;
    file input_file : text open read_mode is "../Matlab/portadoras_im.csv";
    variable input_line : line;
    variable portadora : real;

  begin
    
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        wait for 10 * clk_period;
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        readline(input_file, input_line);
        read(input_line, portadora);
        portadora_s <= portadora;

        wait for 10 * clk_period;
        readline(input_file, input_line);
        read(input_line, portadora);
        portadora_s <= portadora;
        wait for 100*clk_period;

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
