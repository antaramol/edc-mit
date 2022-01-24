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

  TYPE STATE_TYPE IS (reposo, leer_primero, esperar_escritura, leer_ultimo, esperar_interpol);
  SIGNAL estado, p_estado : STATE_TYPE;
  SIGNAL direccion : unsigned(ADDR_WIDTH-1 downto 0);
  SIGNAL signo_s : signed(DATA_WIDTH/2-1 downto 0) := (OTHERS => '0');

begin
  
  comb: process (estado)
    variable h : complex10;
    begin
      en_PRBS <= '0';
      addr_mem <= to_unsigned(0,ADDR_WIDTH);
      h.re := signed(data(DATA_WIDTH-1 downto DATA_WIDTH/2));
      h.im := signed(data(DATA_WIDTH/2-1 downto 0));
     
      valido <= '0';

      CASE estado IS
        WHEN reposo =>
          --addr_mem <= to_unsigned(0,ADDR_WIDTH);
        
        WHEN leer_primero =>
          en_PRBS <= '1';
          if(signo = '1') then
            signo_s <= to_signed(-1,DATA_WIDTH/2);
          else
            signo_s <= to_signed(1, DATA_WIDTH/2);
          end if;

          --addr_mem <= to_unsigned(0,ADDR_WIDTH);
         
        WHEN esperar_escritura =>
          
          inf <= h;

        WHEN leer_ultimo =>
          en_PRBS <= '1';
          if(signo = '1') then
            signo_s <= to_signed(-1,DATA_WIDTH/2);
          else
            signo_s <= to_signed(1, DATA_WIDTH/2);
          end if;

          sup <= h;
          valido <= '1';

        WHEN esperar_interpol =>
          
         
          
          
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
        WHEN leer_primero =>
          estado <= esperar_escritura;

        WHEN esperar_escritura => 
          if (addr_cont = to_unsigned(1,ADDR_WIDTH)) then
            estado <= leer_ultimo;
          else
            estado <= esperar_escritura;
          end if;
        WHEN leer_ultimo => 
          estado <= esperar_interpol;
        WHEN esperar_interpol =>
          if(not start_stop) then
            estado <= reposo;
          elsif (not interpol_ok) then
            estado <=leer_primero; 
          else
            estado <= esperar_interpol;
          end if;
      
       END CASE;
    end if;
  end process;

end FSM_arch;

