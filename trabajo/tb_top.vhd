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
  signal rst : std_logic := '0';
  signal clk : std_logic;
  signal y : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal y_valid : std_logic := '0';
  signal estim : complex10;
  signal estim_valid : std_logic;
  signal y_re_s, y_im_s : std_logic_vector(31 downto 0);
 

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
    -- file input_file_re : text open read_mode is "../Matlab/portadoras_re.csv";
    -- file input_file_im : text open read_mode is "../Matlab/portadoras_im.csv";

    -- variable input_line_re, input_line_im : line;
    -- variable portadora_re, portadora_im : real;

    variable portadora_re, portadora_im : integer_array_t;
    variable y_re, y_im : std_logic_vector(31 downto 0);

  begin
    
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        wait for 10 * clk_period;
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        wait for 4 * clk_period;
        portadora_re := load_csv("../Matlab/portadoras_re.csv");
        portadora_im := load_csv("../Matlab/portadoras_im.csv");
        
        i := 0;
        while i < length(portadora_re) loop --tienen la misma longitud
          y_re := std_logic_vector(to_signed(get(portadora_re,i),32));
          
          y_im := std_logic_vector(to_signed(get(portadora_im,i),32));

          y <= (DATA_WIDTH-1 downto DATA_WIDTH/2 => y_re(31 downto 22), DATA_WIDTH/2-1 downto 0 => y_im(31 downto 22));--Cogemos los 10 primeros bits, a la salida habría que
          -- añadir ceros al final hasta completar los 32 bits del integer, y dividir por 10e8

          y_valid <= '1';
          
          y_re_s <= y_re; -- Para verlo a la salida
          y_im_s <= y_im; 
          
          wait for clk_period;
          -- wait for clk_period/2;
          -- y_valid <= '0';
          -- wait for clk_period/2;
          i := i+1;
        end loop;

        y <= (OTHERS => '0');
        y_valid <= '0';


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
