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
    y : out  std_logic_vector (DATA_WIDTH-1 downto 0);
    y_valid : in std_logic;
    estim : out complex10;
    estim_valid : out std_logic
  );
end top_level;

architecture top_level_arch of top_level is

  signal addr_mem, addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal data, datao_a, datai_b, y_s, p_y_s: std_logic_vector (DATA_WIDTH-1 downto 0);
  signal h_inf, h_sup : complex10;
  signal signo, en_prbs, valido_interpol : std_logic;
  signal interpol_ok, ultima_portadora, estim_valid_interpol : std_logic;

  component contador is
    generic( N : integer := 8 );
    port (
      rst    : in  std_logic;
      clk    : in  std_logic;
      ena    : in  std_logic;
      cuenta : out unsigned(N-1 downto 0));
  end component;

  component FSM is
    generic (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 8  );
    port (
      rst    : in  std_logic;
      clk    : in  std_logic;
      data : in  std_logic_vector (DATA_WIDTH-1 downto 0);
      addr_cont : in unsigned (ADDR_WIDTH-1 downto 0);
      signo  : in std_logic;
      en_PRBS : out std_logic;
      inf : out complex10;
      sup : out complex10;
      start_stop : in std_logic;
      valido : out std_logic;
      interpol_ok : in std_logic;
      ultima_portadora : out std_logic );
  end component;

  component prbs is
    port (
      rst    : in  std_ulogic;
      clk    : in  std_ulogic;
      ena    : in  std_ulogic;
      signo  : out std_ulogic );
  end component;

  component interpolator is
    port (
      clk : in std_logic;
      rst : in std_logic;
      inf : in complex10;
      sup : in complex10;
      valid : in std_logic;
      estim : out complex10;
      estim_valid : out std_logic;
      interpol_ok : out std_logic);
  end component;

begin
  
  contador_inst : contador
    generic map(N => ADDR_WIDTH )
    port map(
        rst    => rst,
        clk    => clk,
        ena    => y_valid,
        cuenta => addr_cont);

  FSM_inst : FSM
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
  
  prbs_inst : prbs
    port map(rst => rst,
        clk  => clk,
        ena  => en_prbs,
        signo => signo );


  interpolator_inst : interpolator
    port map(clk => clk,
        rst => rst,
        inf => h_inf,
        sup => h_sup,
        valid => valido_interpol,
        estim => estim,
        estim_valid => estim_valid_interpol,
        interpol_ok => interpol_ok);

  estim_valid <= estim_valid_interpol OR ultima_portadora;


end top_level_arch;