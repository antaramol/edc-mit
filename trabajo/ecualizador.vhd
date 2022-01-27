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
    x_eq : out complex10
  );
end ecualizador;

architecture ecualizador_arch of ecualizador is

    type registro_type is array (12 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0); -- 12 posiciones
    signal reg, p_reg : registro_type  := (OTHERS => (others => '0'));

    signal real_s, imag_s : signed(9 downto 0) := to_signed(0,10); -- A la salida del divisor
    signal divisor, p_divisor : signed(19 downto 0) := to_signed(1,20);

    signal x_eq_re, x_eq_im : signed(19 downto 0) := to_signed(0,20);



begin

    real_s <= signed(y(DATA_WIDTH-1 downto DATA_WIDTH/2))/divisor;
    imag_s <= -signed(y(DATA_WIDTH/2-1 downto 0))/divisor;

    x_eq_re <= real_s * signed(reg(0)(19 downto 10));
    x_eq_im <= imag_s * signed(reg(0)(9 downto 0));

    x_eq.re <= x_eq_re(19 downto 10);
    x_eq.im <= x_eq_im(19 downto 10);

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

        if (H_valid = '1') then
            divisor <= to_signed(to_integer(H_est.re)**2 + to_integer(H_est.im)**2,20);
            real_s <= signed(y(DATA_WIDTH-1 downto DATA_WIDTH/2))/divisor;
            imag_s <= -signed(y(DATA_WIDTH/2-1 downto 0))/divisor;

            x_eq_re <= real_s * signed(reg(0)(19 downto 10));
            x_eq_im <= imag_s * signed(reg(0)(9 downto 0));

            x_eq.re <= x_eq_re(19 downto 10);
            x_eq.im <= x_eq_im(19 downto 10);
        else
            divisor <= to_signed(1,20);
            real_s <= to_signed(0,10);
            imag_s <= to_signed(0,10);

            x_eq_re <= to_signed(0,20);
            x_eq_im <= to_signed(0,20);

            x_eq.re <= to_signed(0,10);
            x_eq.im <= to_signed(0,10);
        end if;
       
      end if;
    end process;


end;