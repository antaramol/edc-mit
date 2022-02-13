library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;


entity top_cont_mem is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
  port (
    rst    : in  std_logic;
    clk    : in  std_logic;
    y : out  std_logic_vector (DATA_WIDTH-1 downto 0);
    y_valid : in std_logic;
    --address : in unsigned (ADDR_WIDTH-1 downto 0);
    estim_valid : out std_logic
  );
end top_cont_mem;

architecture top_cont_mem_arch of top_cont_mem is

  signal addr_mem, addr_cont : unsigned (ADDR_WIDTH-1 downto 0);
  signal data, datao_a, datai_b : std_logic_vector (DATA_WIDTH-1 downto 0);
  signal h_inf, h_sup : complex10;
  signal signo, en_prbs, valido_interpol : std_logic;

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
        datai_a => y,
        we_a    => y_valid,
        datao_a => datao_a,
        addri_b => addr_mem,
        datai_b => (OTHERS => '0'),
        we_b    => '0',
        datao_b => data);
end;