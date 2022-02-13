library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity prbs is
  port (
    rst    : in  std_ulogic;
    clk    : in  std_ulogic;
    ena    : in  std_ulogic;
    signo  : out std_ulogic;
    secuencia_salida : out std_ulogic;
    valido : out std_ulogic
  );
end prbs;

architecture prbs_arch of prbs is

  signal reg, p_reg : std_ulogic_vector(11 downto 1);
  signal signo_interno, p_signo_interno, p_valido : std_ulogic; 

begin

  valido <= p_valido;
  secuencia_salida <= reg(1);
  signo <= signo_interno;

  comb: process (reg, p_valido)
  begin
    if p_valido='1' then
      p_reg(11) <= reg(1) XOR reg(3); 
      p_reg(10 downto 1) <= reg(11 downto 2);
      p_signo_interno <= NOT signo_interno; 
    else
      p_reg <= reg;   
      p_signo_interno <= signo_interno;
    end if;  

  end process;
  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      reg <= (others => '1');
      signo_interno <= '0';
      p_valido <= '0';
    elsif rising_edge(clk) then
      reg <= p_reg;
      signo_interno <= p_signo_interno;
      if(ena = '1')then
        p_valido <= '1';
      else
          p_valido <= '0';
      end if;
    end if;
  end process;

end prbs_arch;

