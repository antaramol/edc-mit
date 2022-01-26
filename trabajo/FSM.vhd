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
    --addr_mem : out unsigned (ADDR_WIDTH-1 downto 0);
    data : in  std_logic_vector (DATA_WIDTH-1 downto 0);
    addr_cont : in unsigned (ADDR_WIDTH-1 downto 0);
    signo  : in std_logic;
    en_PRBS : out std_logic;
    inf : out complex10;
    sup : out complex10;
    start_stop : in std_logic;
    valido : out std_logic;
    interpol_ok : in std_logic;
    ultima_portadora : out std_logic
  );
end FSM;

architecture FSM_arch of FSM is

  TYPE STATE_TYPE IS (reposo, estado_espera,leer_primero, espera_escritura, actualizar_salidas, esperar_interpol, leer_ultimo_simbolo, espera_interpol_salir, ultima_port);
  SIGNAL estado, p_estado : STATE_TYPE;
  SIGNAL direccion : unsigned(ADDR_WIDTH-1 downto 0);
  SIGNAL signo_s : signed(DATA_WIDTH/2-1 downto 0) := (OTHERS => '0');

begin
  
  comb: process (estado)
    variable h, nuevo_inf : complex10;
    variable i : unsigned(4 downto 0) := to_unsigned(0,5);
    begin
      en_PRBS <= '0';
      
      -- addr_mem <= i;
      
     
      valido <= '0';

      ultima_portadora <= '0';
      

      CASE estado IS
        WHEN reposo =>
          inf.re <= to_signed(0,10);
          inf.im <= to_signed(0,10);
          sup.re <= to_signed(0,10);
          sup.im <= to_signed(0,10);

        WHEN estado_espera =>
        
        WHEN leer_primero =>
          en_PRBS <= '1';
          if(signo = '1') then
            sup.re <= -signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= -signed(data(DATA_WIDTH/2-1 downto 0));
          else
            sup.re <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= signed(data(DATA_WIDTH/2-1 downto 0));
          end if;

          i := to_unsigned(12,5);

        WHEN espera_escritura =>

        WHEN actualizar_salidas =>
          en_PRBS <= '1';

          inf <= sup;

          if(signo = '1') then
            sup.re <= -signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= -signed(data(DATA_WIDTH/2-1 downto 0));
          else
            sup.re <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= signed(data(DATA_WIDTH/2-1 downto 0));
          end if;

          --sup <= h;

          valido <= '1';

          if(i = 0) then
            i := to_unsigned(12,5);
           else
            i := to_unsigned(0,5);
           end if;   

        WHEN esperar_interpol =>
           
          
        WHEN leer_ultimo_simbolo =>
          en_PRBS <= '1';

          inf <= sup;

          if(signo = '1') then
            sup.re <= -signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= -signed(data(DATA_WIDTH/2-1 downto 0));
          else
            sup.re <= signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
            sup.im <= signed(data(DATA_WIDTH/2-1 downto 0));
          end if;

          --sup <= h;

          valido <= '1';

          if(i = 0) then
            i := to_unsigned(12,5);
          else
            i := to_unsigned(0,5);
          end if;   

        WHEN espera_interpol_salir =>

        WHEN ultima_port =>
          ultima_portadora <= '1';
          
          
          
      END CASE;
      
    end process;
  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      estado <= reposo;
    elsif rising_edge(clk) then
      CASE estado IS
        WHEN reposo =>
          if (start_stop) then
            estado <= leer_primero;
          end if;

        WHEN estado_espera =>
          estado <= leer_primero;

        WHEN leer_primero =>
          estado <= espera_escritura;

        WHEN espera_escritura => 
          if (addr_cont = to_unsigned(11,ADDR_WIDTH)) then
            estado <= actualizar_salidas;
          end if;

        WHEN actualizar_salidas => 
          estado <= esperar_interpol;
          
        WHEN esperar_interpol =>
          if(not start_stop) AND (interpol_ok) then
            estado <= leer_ultimo_simbolo;
          elsif (interpol_ok) then
            estado <=actualizar_salidas; 
          end if;
          
        WHEN leer_ultimo_simbolo =>
          estado <= espera_interpol_salir;

        WHEN espera_interpol_salir =>
          if (interpol_ok) then
            estado <= ultima_port;
          end if;

        WHEN ultima_port => 
          estado <= reposo;
          
       END CASE;
    end if;
  end process;

end FSM_arch;

