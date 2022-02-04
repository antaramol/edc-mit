library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity contador is
  generic( N : integer := 8 ); -- Nº bits del contador
  port (
    rst    : in  std_logic;
    clk    : in  std_logic;
    ena    : in  std_logic;
    --rst_control : out std_logic;
    cuenta : out unsigned(N-1 downto 0)
  );
end contador;

architecture contador_arch of contador is

  -- TYPE STATE_TYPE IS (reposo, contar);
  -- SIGNAL estado, p_estado : STATE_TYPE;

  signal cont, p_cont : unsigned(N-1 downto 0);

begin
  
  comb: process (cont, ena)
  begin
    if (ena = '1') then
      if (cont = to_unsigned(11,N)) then
        p_cont <= (others => '0');
        --rst_control <= '1';
      else
        p_cont <= cont + 1;
        --rst_control <= '0';
      end if;
    else
      p_cont <= cont;    
    end if;  
  end process;
  
  sinc: process (rst, clk)
  begin
    if rst = '1' then
      cont <= (others => '0');
      --estado <= reposo;
    elsif rising_edge(clk) then
      cont <= p_cont;
      --cont <= (0 => '1', others => '0');
      --estado <= p_estado;
    end if;
  end process;

  cuenta <= cont;
end contador_arch;

