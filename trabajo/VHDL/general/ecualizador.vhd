library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;

entity ecualizador is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
  port (
    rst    : in  std_logic;
    clk    : in  std_logic;
    y : in  std_logic_vector (DATA_WIDTH-1 downto 0);
    y_valid : in std_logic;
    H_est : in complex10;
    H_valid : in std_logic;
    salida_valid : out std_logic;
    x_eq : out complex10
  );
end ecualizador;

architecture ecualizador_arch of ecualizador is

    type registro_type is array (12 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0); -- 12 posiciones
    signal reg, p_reg : registro_type  := (OTHERS => (others => '0'));

    signal a, b, c, d : signed(9 downto 0); -- A la salida del divisor
    signal divisor : signed(26 downto 0) := to_signed(1,27) ;
    signal dividendo_re, dividendo_im : signed(26 downto 0) := to_signed(0,27);

    signal x_aux_re, x_aux_im : signed(26 downto 0);
    


begin

    salida_valid <= H_valid; --Es un bloque combinacional, la conectamos directamente

    a <= H_est.re;
    b <= H_est.im;
    c <= signed(reg(0)(19 downto 10));
    d <= signed(reg(0)(9 downto 0));
    
    --Calculamos los dividendos y multiplicamos por 2^7 añadiendo 7 ceros a la derecha
    dividendo_re (26 downto 7) <= a*c + b*d;
    dividendo_im (26 downto 7) <= a*d - b*c;

    --Calculamos el divisor que es común
    divisor (19 downto 0) <= H_est.re*H_est.re + H_est.im*H_est.im; 

    
    
    comb: process (all)
    begin
      

      if (H_valid = '1') then

        if (divisor = 0) then 
          --A veces por la precisión algunos valores se hacen cero, hay que tratar estos extremos por separado
          
          if dividendo_im = to_signed(0,27) then 
            x_aux_im <= to_signed(0,27);
          elsif dividendo_im = to_signed(0,27) then 
            x_aux_im <= to_signed(-512,27);
          else
            x_aux_im <= to_signed(511,27);
          end if;

          if dividendo_re = to_signed(0,27) then 
            x_aux_re <= to_signed(0,27);
          elsif dividendo_im = to_signed(0,27) then 
            x_aux_re <= to_signed(-512,27);
          else
            x_aux_re <= to_signed(511,27);
          end if;
          
        else --Si tenemos una estimación válida y el divisor no es cero, hacemos la división
          x_aux_re <= dividendo_re / divisor;
          x_aux_im <= dividendo_im / divisor;
        end if;
        
      else
        x_aux_re <= to_signed(0,27);
        x_aux_im <= to_signed(0,27);
      end if;

    end process;

    --Asignamos los menos significativos, la división no va a salir un número mayor que 10 bits de precisión
    x_eq.re <= x_aux_re(9 downto 0);
    x_eq.im <= x_aux_im(9 downto 0);
    
    
    sinc: process (rst, clk)
    begin
      if rst = '1' then
        reg <= (OTHERS => (others => '0'));
      elsif rising_edge(clk) then
        reg(12) <= y;
        reg (11 downto 0) <= reg(12 downto 1);  
      end if;
    end process;


end;