library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity prbs is
  port (
    rst    : in  std_ulogic;
    clk    : in  std_ulogic;
    ena    : in  std_ulogic;
    signo  : out std_ulogic
  );
end prbs;

architecture prbs_arch of prbs is

  signal reg, p_reg : std_ulogic_vector(11 downto 1);

begin

  signo <= reg(1);

  comb: process (ena)
  begin
    if ena='1' then
      p_reg(11) <= reg(1) XOR reg(3); 
      p_reg(10 downto 1) <= reg(11 downto 2);
    else
      p_reg <= reg;  
    end if;  

  end process;
  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      reg <= (others => '1');
    elsif rising_edge(clk) then
      reg <= p_reg;
    end if;
  end process;

end prbs_arch;

