library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity prbs_tb is
  generic (runner_cfg : string);
end;

architecture bench of prbs_tb is


  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports
  signal rst : std_ulogic := '0';
  signal clk : std_ulogic;
  signal ena : std_ulogic := '0';
  signal signo : std_ulogic;

  signal running : boolean := true;
  signal fin : boolean := false;

begin

  prbs_inst : entity src_lib.prbs
    port map (
      rst => rst,
      clk => clk,
      ena => ena,
      signo => signo
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("1705_ciclos") then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        --wait for (2**N)*clk_period;
        wait for 1705*clk_period;
        ena <= '0';
        wait for 10*clk_period;

      elsif run("arranque_stop")then
        wait for 4 * clk_period;
        rst <= '1';
        wait for 4*clk_period;
        rst <= '0';
        wait for 10*clk_period;
        ena <= '1';
        wait for 50*clk_period;
        ena <= '0';
        
        wait for 10*clk_period;
        ena <= '1';
        wait for 50*clk_period;
        ena <= '0';
        wait for 10*clk_period;
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
    variable output_signo : integer_array_t;
    variable salida_int : integer := 0;

  begin
    -- new_1d is a function defined in the VUnit libraries (specifically,
    -- in integer_array_pkg) that initializes a 1-dimensional array.
    -- There are also new_2d and new_3d functions in that package.
    output_signo := new_1d;

    -- While the simulation is running, append output data to our output vector
    while (running) loop
      wait until rising_edge(clk);
      if(ena)then
        
        if signo then
          salida_int := to_integer(to_unsigned(1,32));
        else 
          salida_int := to_integer(to_unsigned(0,32));
        end if;
        append(output_signo, salida_int);

      end if;
    end loop;

    -- When no more clock cycles are expected, write the file and free the
    -- memory used for the output vector
    save_csv(output_signo,"../Matlab/signo.csv");
    fin <= true;
    deallocate(output_signo);

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
