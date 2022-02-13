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

    salida_valid <= H_valid;

    a <= H_est.re;
    b <= H_est.im;
    c <= signed(reg(0)(19 downto 10));
    d <= signed(reg(0)(9 downto 0));
    
    dividendo_re (26 downto 7) <= a*c + b*d;
    dividendo_im (26 downto 7) <= a*d - b*c;

    divisor (19 downto 0) <= H_est.re*H_est.re + H_est.im*H_est.im;

    
    
    comb: process (all)
    begin
      

      if (H_valid = '1') then
      
      
        -- a <= H_est.re;
        -- b <= H_est.im;
        -- c <= signed(reg(0)(19 downto 10));
        -- d <= signed(reg(0)(9 downto 0));

        -- dividendo_re (26 downto 7) <= a*c + b*d;
        -- dividendo_im (26 downto 7) <= b*c - a*d;

        -- divisor (19 downto 0) <= H_est.re*H_est.re + H_est.im*H_est.im;
        --divisor (26 downto 20) <= (OTHERS => '0');

        if (divisor = 0) then 
          
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
          
        else
          x_aux_re <= dividendo_re / divisor;
          x_aux_im <= dividendo_im / divisor;
        end if;
        
      else
        -- a <= to_signed(0,10);
        -- b <= to_signed(0,10);
        -- c <= to_signed(0,10);
        -- d <= to_signed(0,10);
        -- dividendo_re <= to_signed(0,27);
        -- dividendo_im <= to_signed(0,27);
        --divisor <= to_signed(1,27);
        x_aux_re <= to_signed(0,27);
        x_aux_im <= to_signed(0,27);
      end if;

    end process;

    x_eq.re <= x_aux_re(9 downto 0);
    x_eq.im <= x_aux_im(9 downto 0);
    
    
    sinc: process (rst, clk)
        --variable i : unsigned(3 downto 0);
    begin
      if rst = '1' then
        -- i := to_unsigned(0,4);
        -- while (i < reg'length) loop
        --     reg(i) <= (others => '0');
        --     i := i+1;
        -- end loop;
        reg <= (OTHERS => (others => '0'));
      elsif rising_edge(clk) then
        reg(12) <= y;
        reg (11 downto 0) <= reg(12 downto 1);  
      end if;
    end process;


end;