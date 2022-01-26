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
    --address : in unsigned (ADDR_WIDTH-1 downto 0);
    estim_valid : out std_logic
  );
end top_level;

architecture top_level_arch of top_level is

  signal addr_mem, addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal data, datao_a, datai_b, y_s, p_y_s: std_logic_vector (DATA_WIDTH-1 downto 0);
  signal h_inf, h_sup : complex10;
  signal signo, en_prbs, valido_interpol : std_logic;
  signal interpol_ok : std_logic;

  component contador is
    generic( N : integer := 8 );
    port (
      rst    : in  std_logic;
      clk    : in  std_logic;
      ena    : in  std_logic;
      cuenta : out unsigned(N-1 downto 0));
  end component;

  component dpram is
    generic (
      DATA_WIDTH : integer := 8; -- Será puesta a 20 en nuestro top_level para facilitar la lectura de los datos
      ADDR_WIDTH : integer := 8);
    port (clk   : in  std_logic;
      addri_a : in  unsigned (ADDR_WIDTH-1 downto 0);
      datai_a : in  std_logic_vector (DATA_WIDTH-1 downto 0);
      we_a    : in  std_logic;
      datao_a : out std_logic_vector (DATA_WIDTH-1 downto 0);
      addri_b : in  unsigned (ADDR_WIDTH-1 downto 0);
      datai_b : in  std_logic_vector (DATA_WIDTH-1 downto 0);
      we_b    : in  std_logic;
      datao_b : out std_logic_vector (DATA_WIDTH-1 downto 0));
  end component;

  component FSM is
    generic (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 8  );
    port (
      rst    : in  std_logic;
      clk    : in  std_logic;
      addr_mem : out unsigned (ADDR_WIDTH-1 downto 0);
      data : in  std_logic_vector (DATA_WIDTH-1 downto 0);
      addr_cont : in unsigned (ADDR_WIDTH-1 downto 0);
      signo  : in std_logic;
      en_PRBS : out std_logic;
      inf : out complex10;
      sup : out complex10;
      start_stop : in std_logic;
      valido : out std_logic;
      interpol_ok : in std_logic );
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

  dpram_inst : dpram
    generic map(DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH)
    port map(clk => clk,
        addri_a => addr_cont, --address,
        datai_a => y_s,
        we_a    => y_valid,
        datao_a => datao_a,
        addri_b => addr_mem,
        datai_b => (OTHERS => '0'),
        we_b    => '0',
        datao_b => data);

  FSM_inst : FSM
    generic map(DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH)
    port map(rst => rst,
      clk  => clk,
      addr_mem => addr_mem,
      data => data,
      addr_cont => addr_cont,
      signo  => signo,
      en_PRBS => en_prbs,
      inf => h_inf,
      sup => h_sup,
      start_stop => y_valid,
      valido => valido_interpol,
      interpol_ok => interpol_ok);
  
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
        estim_valid => estim_valid,
        interpol_ok => interpol_ok);

  comb: process(y)
  begin
    p_y_s <= y;
  end process;

  sinc: process (rst, clk)
  begin
    if rising_edge(clk) then
      y_s <= y;
    end if;
  end process;

end top_level_arch;