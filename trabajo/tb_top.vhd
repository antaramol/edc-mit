library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

-- library osvvm;
-- use osvvm.RandomPkg.RandomPType;

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
  
  --type integer_array_t is array (1704 downto 0) of integer;
  --signal portadoras_vect : integer_array_vec_t;
  --signal portadora : integer_array_t;

  signal start, data_check_done, stimuli_done : boolean := false;

  shared variable portadoras : integer_array_t;
  
  
  
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

    procedure run_test is
    begin
      wait until rising_edge(clk);
      start <= true;
      wait until rising_edge(clk);
      start <= false;

      wait until (
        stimuli_done and
        data_check_done and
        rising_edge(clk)
      );
    end procedure;
    
  begin
    portadoras := new_1d;
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        wait for 10 * clk_period;
        rst <= '1';
        -- impure function load_csv
        --  file_name : string;
        --  bit_width : natural := 32;
        --  is_signed : boolean := true
        -- ) return integer_array_t;
        portadoras := load_csv("portadoras_re.csv");
        
        wait for 100 * clk_period;
      end if;
    end loop;

    test_runner_cleanup(runner);

  end process main;

--   cargar : process (rst)
--   begin

--   end process;

stimuli_process : process
begin
  wait until start and rising_edge(clk);
  stimuli_done <= false;

--   report (
--     "Sending image of size " &
--     to_string(width(image)) & "x" &
--     to_string(height(image))
--   );

  for i in 0 to height(portadoras)-1 loop
    
      wait until rising_edge(clk);
      y_valid <= '1';
      
      y <= (get(portadoras, i,1), 10);
    
  end loop;

  wait until rising_edge(clk);

  stimuli_done <= true;
end process;
  
  clk_process : process
  begin
  clk <= '1';
  wait for clk_period/2;
  clk <= '0';
  wait for clk_period/2;
  end process clk_process;

end;
