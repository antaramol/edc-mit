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
    start_stop : in std_logic;
    valido : out std_logic;
    interpol_ok : in std_logic
  );
end FSM;

architecture FSM_arch of FSM is

  -- TYPE STATE_TYPE IS (reposo, primer_piloto, piloto_superior, activar_interpolador, esperar_interpolacion, habilitar_PRBS);
  -- TYPE STATE_TYPE IS (reposo, leer_primero, esperar_escritura, leer_ultimo, esperar_interpol);
  TYPE STATE_TYPE IS (reposo, leer_primero, esperar_escritura, leer_ultimo, esperar_interpol);
  SIGNAL estado, p_estado : STATE_TYPE;
  SIGNAL direccion : unsigned(ADDR_WIDTH-1 downto 0);
  SIGNAL piloto : signed(9 downto 0) := to_signed(4/3,10);

begin

  -- comb: process (estado, data, addr_cont, signo, interpol_ok)
  -- begin
  --   CASE estado IS
  --     WHEN reposo =>
  --       if (to_integer(addr_cont) = 11) then -- Cuando deja de ser cero
  --         p_estado <= primer_piloto;
  --       end if;
  --     WHEN primer_piloto =>
  --       en_PRBS <= '1';
  --       piloto(9) <= signo;
  --       inf.re <= signed(data((DATA_WIDTH/2)-1 downto 0))/piloto;
  --       inf.im <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2))/piloto;
  --       p_estado <= piloto_superior;
  --     WHEN piloto_superior => 
  --       if ((direccion + 12) > addr_cont) then
  --         en_PRBS <= '1';
  --         piloto(9) <= signo;
  --         addr_mem <= direccion + 12;
  --         sup.re <= signed(data((DATA_WIDTH/2)-1 downto 0))/piloto;
  --         sup.im <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2))/piloto;
  --         p_estado <= activar_interpolador;
  --       else
  --         p_estado <= piloto_superior;
  --       end if;
  --     WHEN activar_interpolador =>
  --       valido <= '1';
  --       p_estado <= esperar_interpolacion;
  --     WHEN esperar_interpolacion =>
  --       if (interpol_ok) then
  --           p_estado <= piloto_superior;
  --       end if;
  --     WHEN habilitar_PRBS =>
  --       en_PRBS <= '1';
  --       inf <= sup;
  --       p_estado <= piloto_superior;
  --    END CASE;
    
  -- end process;

  comb: process (estado,start_stop, addr_cont)
    begin
      CASE estado IS
        WHEN reposo =>
          addr_mem <= to_unsigned(0,ADDR_WIDTH);
          if (start_stop) then -- Cuando deja de ser cero
            p_estado <= leer_primero;
          end if;
        WHEN leer_primero =>
          en_PRBS <= '1';
          piloto(9) <= signo;
          addr_mem <= to_unsigned(0,ADDR_WIDTH);
          inf.re <= signed(data((DATA_WIDTH/2)-1 downto 0))/piloto;
          inf.im <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2))/piloto;
          p_estado <= esperar_escritura;
        WHEN esperar_escritura => 
          if (addr_cont = to_unsigned(10,ADDR_WIDTH)) then
            p_estado <= leer_ultimo;
          else
            p_estado <= esperar_escritura;
          end if;
        WHEN leer_ultimo => 
          en_PRBS <= '1';
          piloto(9) <= signo;
          addr_mem <= direccion + to_unsigned(12,ADDR_WIDTH);
          sup.re <= signed(data((DATA_WIDTH/2)-1 downto 0))/piloto;
          sup.im <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2))/piloto;
          p_estado <= esperar_interpol;
          valido <= '1';
        WHEN esperar_interpol =>
          p_estado <= esperar_interpol;
          if (not start_stop) then
            p_estado <= reposo;
          elsif (not interpol_ok) then
            p_estado <= leer_primero;
          end if;
       END CASE;
      
    end process;
  

  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      estado <= reposo;
      addr_mem <= to_unsigned(0,ADDR_WIDTH);
      en_PRBS <= '0';
      inf.re <= to_signed(0,10);
      inf.im <= to_signed(0,10);
      sup.re <= to_signed(0,10);
      sup.im <= to_signed(0,10);
      valido <= '0';
    elsif rising_edge(clk) then
      estado <= p_estado;
      --addr_mem <= direccion;
    end if;
  end process;

end FSM_arch;

