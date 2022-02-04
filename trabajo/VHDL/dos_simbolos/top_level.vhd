library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;


entity top_level is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
  port (
    rst    : in  std_logic;
    clk    : in  std_logic;
    y : in  std_logic_vector (DATA_WIDTH-1 downto 0);
    y_valid : in std_logic;
    valid_out : out std_logic;
    x_eq : out complex10
  );
end top_level;

architecture top_level_arch of top_level is

  signal addr_mem, addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal data, datao_a, datai_b, y_s, p_y_s: std_logic_vector (DATA_WIDTH-1 downto 0);
  signal h_inf, h_sup : complex10;
  signal signo, en_prbs, valido_interpol : std_logic;
  signal interpol_ok, ultima_portadora, estim_valid_interpol : std_logic;
  signal estim : complex10;
  signal estim_valid : std_logic;

 
begin
  
  contador_inst : entity src_lib.contador
    generic map(N => ADDR_WIDTH )
    port map(
        rst    => rst,
        clk    => clk,
        ena    => y_valid,
        cuenta => addr_cont);

  FSM_inst :  entity src_lib.FSM
    generic map(DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH)
    port map(rst => rst,
      clk  => clk,
      data => y,
      addr_cont => addr_cont,
      signo  => signo,
      en_PRBS => en_prbs,
      inf => h_inf,
      sup => h_sup,
      start_stop => y_valid,
      valido => valido_interpol,
      interpol_ok => interpol_ok,
      ultima_portadora => ultima_portadora);
  
  prbs_inst : entity src_lib.prbs
    port map(rst => rst,
        clk  => clk,
        ena  => en_prbs,
        signo => signo );


  interpolator_inst : entity src_lib.interpolator
    port map(clk => clk,
        rst => rst,
        inf => h_inf,
        sup => h_sup,
        valid => valido_interpol,
        estim => estim,
        estim_valid => estim_valid_interpol,
        interpol_ok => interpol_ok);

  estim_valid <= estim_valid_interpol OR ultima_portadora;

  ecualizador_inst :  entity src_lib.ecualizador
  generic map(
    DATA_WIDTH => DATA_WIDTH,
    ADDR_WIDTH => ADDR_WIDTH
  )
  port map(
    rst    => rst,
    clk    => clk,
    y => y,
    y_valid => y_valid,
    H_est => estim,
    H_valid => estim_valid,
    salida_valid => valid_out,
    x_eq => x_eq);



end top_level_arch;