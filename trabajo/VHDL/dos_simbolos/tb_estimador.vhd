library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity estimador_tb is
  generic (runner_cfg : string);
end;

architecture bench of estimador_tb is


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
  signal estim_valid : std_logic;
  signal estim : complex10;

  signal y_re_s, y_im_s : std_logic_vector(9 downto 0);
  signal address, p_address : unsigned (ADDR_WIDTH-1 downto 0) := to_unsigned(0,ADDR_WIDTH);


  signal running : boolean := true;
  signal fin : boolean := false;


begin

  estimador_inst : entity src_lib.estimador
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      rst => rst,
      clk => clk,
      y => y,
      y_valid => y_valid,
      estim_valid => estim_valid,
      estim => estim
    );

  main : process
    variable i : integer;

    variable portadora_re, portadora_im : integer_array_t;
    variable y_re, y_im : std_logic_vector(9 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        wait for 2 * clk_period;
        rst <= '1';
        wait for 3 * clk_period;
        rst <= '0';

        wait for 4 * clk_period;
        portadora_re := load_csv("Matlab/portadoras_re.csv",10);
        portadora_im := load_csv("Matlab/portadoras_im.csv",10);
        
        i := 0;
        y_valid <= '1';

        while i < length(portadora_re) loop --tienen la misma longitud
          y_re := std_logic_vector(to_signed(get(portadora_re,i),10));
          
          y_im := std_logic_vector(to_signed(get(portadora_im,i),10));
    
          y <= (DATA_WIDTH-1 downto DATA_WIDTH/2 => y_re,
                DATA_WIDTH/2-1 downto 0 => y_im);


          y_re_s <= y_re; -- Para verlo a la salida
          y_im_s <= y_im; 
          
          wait for clk_period;
          i := i+1;            
        end loop;

        y <= (OTHERS => '0');
        y_valid <= '0';

        wait for 100*clk_period;

      end if;
    end loop;
    
    running <= false;
    wait until fin = true;

    deallocate(portadora_re);
    deallocate(portadora_im);

    test_runner_cleanup(runner);

  end process main;

  printer: process
    -- Variable, internal to the process, where we will store the circuit
    -- outputs so they can be written to a .csv file
    -- The csv file can then be read from Matlab (using readmatrix() or
    -- csvread()) or octave (using csvread())
    variable outputs_re, outputs_im : integer_array_t;
    variable salida_int : integer := 0;

  begin
    -- new_1d is a function defined in the VUnit libraries (specifically,
    -- in integer_array_pkg) that initializes a 1-dimensional array.
    -- There are also new_2d and new_3d functions in that package.
    outputs_re := new_1d;
    outputs_im := new_1d;

    -- While the simulation is running, append output data to our output vector
    while (running) loop
      wait until rising_edge(clk);
      if(estim_valid)then
        
        salida_int := to_integer(estim.re);
        append(outputs_re, salida_int);

        salida_int := to_integer(estim.im);
        append(outputs_im, salida_int);
      end if;
    end loop;

    -- When no more clock cycles are expected, write the file and free the
    -- memory used for the output vector
    save_csv(outputs_re,"Matlab/estim_re.csv");
    save_csv(outputs_im,"Matlab/estim_im.csv");
    fin <= true;
    deallocate(outputs_re);
    deallocate(outputs_im);

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
