library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;


entity estimador is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
  port (
    rst    : in  std_logic;
    clk    : in  std_logic;
    y : in  std_logic_vector (DATA_WIDTH-1 downto 0);
    y_valid : in std_logic;
    estim_valid : out std_logic;
    estim : out complex10
  );
end estimador;

architecture estimador_arch of estimador is

  signal addr_mem, addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal data, datao_a, datai_b, y_s, p_y_s: std_logic_vector (DATA_WIDTH-1 downto 0);
  signal h_inf, h_sup : complex10;
  signal signo, en_prbs, valido_interpol : std_logic;
  signal interpol_ok, ultima_portadora, estim_valid_interpol : std_logic;

 
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

 

end estimador_arch;
