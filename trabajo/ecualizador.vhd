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
    signal divisor : signed(19 downto 0);
    signal dividendo_re, dividendo_im : signed(19 downto 0);

    signal x_aux_re, x_aux_im : signed(9 downto 0);
    


begin

    salida_valid <= H_valid;

    a <= H_est.re;
    b <= H_est.im;
    c <= signed(reg(0)(19 downto 10));
    d <= signed(reg(0)(9 downto 0));

    --dividendo_re <= a*c + b*d;
    --dividendo_im <= b*c - a*d;

    dividendo_re <= H_est.re * signed(reg(0)(19 downto 10)) + H_est.im * signed(reg(0)(9 downto 0));
    dividendo_im <= H_est.im * signed(reg(0)(19 downto 10)) - H_est.re * signed(reg(0)(9 downto 0));

    divisor <= to_signed(to_integer(H_est.re)**2 + to_integer(H_est.im)**2,20);
    
    comb: process (H_valid, H_est)
    begin
      if (H_valid = '1') then
      
        x_aux_re <= to_signed(to_integer(dividendo_re*(2**7)) / to_integer(divisor),10);
        x_aux_im <= to_signed(to_integer(dividendo_im*(2**7)) / to_integer(divisor),10);
        
      else
        x_aux_re <= to_signed(0,10);
        x_aux_im <= to_signed(0,10);
      end if;

    end process;

    x_eq.re <= x_aux_re;
    x_eq.im <= x_aux_im;
    
    
    sinc: process (rst, clk)
        variable i : unsigned(3 downto 0);
    begin
      if rst = '1' then
        i := to_unsigned(0,4);
        while (i < reg'length) loop
            reg(to_integer(i)) <= (others => '0');
            i := i+1;
        end loop;
      elsif rising_edge(clk) then
        reg(12) <= y;
        reg (11 downto 0) <= reg(12 downto 1);  
      end if;
    end process;


end;