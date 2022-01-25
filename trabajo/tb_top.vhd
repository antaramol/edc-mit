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
  constant ADDR_WIDTH : integer := 5;

  -- Ports
  signal rst : std_logic := '0';
  signal clk : std_logic;
  signal y : std_logic_vector (DATA_WIDTH-1 downto 0) := (OTHERS => '0');
  signal y_valid : std_logic := '0';
  signal estim : complex10;
  signal estim_valid : std_logic;
  signal y_re_s, y_im_s : std_logic_vector(9 downto 0);
  signal address, p_address : unsigned (ADDR_WIDTH-1 downto 0) := to_unsigned(0,ADDR_WIDTH);

  signal salida_int : integer := 0;
  signal salida_std : std_logic_vector(31 downto 0);
  signal estim_std : std_logic_vector(9 downto 0);

  signal running : boolean := true;
  signal fin : boolean := false;
 

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
      --address => address,
      estim_valid => estim_valid
    );

  main : process

    variable i : integer;

    variable portadora_re, portadora_im : integer_array_t;
    variable y_re, y_im : std_logic_vector(9 downto 0);

  begin
    
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        --wait for 10 * clk_period;
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        wait for 4 * clk_period;
        portadora_re := load_csv("../Matlab/portadoras_re.csv",10);
        portadora_im := load_csv("../Matlab/portadoras_im.csv",10);
        
        i := 0;
        y_valid <= '1';

        while i < length(portadora_re) loop --tienen la misma longitud
          y_re := std_logic_vector(to_signed(get(portadora_re,i),10));
          
          y_im := std_logic_vector(to_signed(get(portadora_im,i),10));

          --y <= (DATA_WIDTH-1 downto DATA_WIDTH/2 => y_re(31 downto 22), DATA_WIDTH/2-1 downto 0 => y_im(31 downto 22));--Cogemos los 10 primeros bits, a la salida habría que
          -- añadir ceros al final hasta completar los 32 bits del integer, y dividir por 10e8
    
          y <= (DATA_WIDTH-1 downto DATA_WIDTH/2 => y_re,
                DATA_WIDTH/2-1 downto 0 => y_im);

          --y <= (OTHERS => '0');

          y_re_s <= y_re; -- Para verlo a la salida
          y_im_s <= y_im; 
          --address <= to_unsigned(i,ADDR_WIDTH);
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
    
    running <= false;
    wait until fin = true;

    test_runner_cleanup(runner);

  end process main;


  printer: process
    -- Variable, internal to the process, where we will store the circuit
    -- outputs so they can be written to a .csv file
    -- The csv file can then be read from Matlab (using readmatrix() or
    -- csvread()) or octave (using csvread())
    variable outputs : integer_array_t;

  begin
    -- new_1d is a function defined in the VUnit libraries (specifically,
    -- in integer_array_pkg) that initializes a 1-dimensional array.
    -- There are also new_2d and new_3d functions in that package.
    outputs := new_1d;

    -- While the simulation is running, append output data to our output vector
    while (running) loop
      wait until rising_edge(clk);
      if((rising_edge(estim_valid)) OR (estim_valid='1'))then
        estim_std <= std_logic_vector(estim.re);
        salida_std <= (31 downto 22 => estim_std, OTHERS => '0');
        salida_int <= to_integer(signed(salida_std));
        if(salida_int /= 0) then
          append(outputs, salida_int);
        end if;
      end if;
    end loop;

    -- When no more clock cycles are expected, write the file and free the
    -- memory used for the output vector
    save_csv(outputs,"../Matlab/salida_re.csv");
    fin <= true;
    deallocate(outputs);
    wait;
  end process;


  
  clk_process : process
  begin
  clk <= '1';
  wait for clk_period/2;
  clk <= '0';
  wait for clk_period/2;
  end process clk_process;

end;
