library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;


entity FSM is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
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
    valido : out std_logic;
    interpol_ok : in std_logic
  );
end FSM;

architecture FSM_arch of FSM is

  TYPE STATE_TYPE IS (reposo, primer_piloto, piloto_superior, activar_interpolador, esperar_interpolacion, habilitar_PRBS);
  SIGNAL estado, p_estado : STATE_TYPE;
  SIGNAL direccion : unsigned(ADDR_WIDTH-1 downto 0);

begin

  comb: process (estado, data, addr_cont, signo, interpol_ok)
  begin
    CASE estado IS
      WHEN reposo =>
        if (to_integer(addr_cont) = 11) then -- Cuando deja de ser cero
          p_estado <= primer_piloto;
        end if;
      WHEN primer_piloto =>
        inf.re <= data((DATA_WIDTH/2)-1 downto 0);
        inf.im <= data(DATA_WIDTH-1 downto DATA_WIDTH/2);
        p_estado <= piloto_superior;
      WHEN piloto_superior => 
        if ((direccion + 12) > addr_cont) then
          addr_mem <= direccion + 12;
          sup.re <= data((DATA_WIDTH/2)-1 downto 0);
          sup.im <= data(DATA_WIDTH-1 downto DATA_WIDTH/2);
          p_estado <= activar_interpolador;
        else
          p_estado <= piloto_superior;
        end if;
      WHEN activar_interpolador =>
        valido <= '1';
        p_estado <= esperar_interpolacion;
      WHEN esperar_interpolacion =>
        if (interpol_ok) then
            p_estado <= habilitar_PRBS;
        end if;
      WHEN habilitar_PRBS =>
        en_PRBS <= '1';
        inf <= sup;
        p_estado <= piloto_superior;
     END CASE;
    

  end process;
  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      estado <= reposo;
      addr_mem <= (OTHERS => '0');
      en_PRBS <= '0';
      inf <= (OTHERS => '0');
      sup <= (OTHERS => '0');
      valido <= '0';
    elsif rising_edge(clk) then
      estado <= p_estado;
      addr_mem <= direccion;
    end if;
  end process;

end FSM_arch;

