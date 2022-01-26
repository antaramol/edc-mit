library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
use src_lib.edc_common.all;

entity interpolator is
        port (
            clk : in std_logic;
            rst : in std_logic;
            inf : in complex10;
            sup : in complex10;
            valid : in std_logic;
            estim : out complex10;
            estim_valid : out std_logic;
            interpol_ok : out std_logic
        );
    end interpolator;

architecture two_processes of interpolator is

    signal i, p_i    : signed (4 downto 0);
    signal estim_aux, s_aux : complex15;

    -- Two signals needed for the firewall assertions
    signal firewall_inf, firewall_sup : complex10;

begin
    
    -- i controls the interpolation:
    -- when i = 12 we are idle
    -- if we receive a valid input, we go to i = 0
    -- when i is between 0 and 11, interpolate
    -- afterwards go again to i = 12
    comb: process(inf, sup, valid, i)
    begin
        if (i < 0) or (i > 11) then  -- Anything that is not between 0 and 11: idle
            estim_valid <= '0';
            if valid = '1' then
                p_i <= to_signed(1, p_i'length);
            else
                p_i <= to_signed(12,p_i'length);
            end if;
        else                         -- Between 0 and 11: interpolate
            p_i <= i + 1;
            estim_valid <= '1';
        end if;

        if p_i = 11 then
            interpol_ok <= '1';
        else
            interpol_ok <= '0';
        end if;

        if valid = '1' then
            estim.re <= inf.re/4 + inf.re/4 + inf.re/4;
            estim.im <= inf.im/4 + inf.im/4 + inf.im/4;
        else
            estim.re <= estim_aux.re(13 downto 4);
            estim.im <= estim_aux.im(13 downto 4);
        end if;

    end process;


    estim_aux.re <= inf.re*(12-i) + sup.re*i;
    estim_aux.im <= inf.im*(12-i) + sup.im*i;

    -- Discard the least significant bit since it doesn't contain any
    -- information (it is redundant with bit 13), and keep the 10 most
    -- significant of the rest
    --estim.re <= estim_aux.re(13 downto 4);
    --estim.im <= estim_aux.im(13 downto 4);

    sinc: process(rst, clk)
    begin
        if rst = '1' then
            i <= to_signed(12,i'length);  -- set i to 12
        elsif rising_edge(clk) then
            i <= p_i;
        end if;
    end process;

    -- Firewall assertions: assure that our module is being used correctly
    -- What can go wrong?
    -- 1.- Valid cannot be asserted while the interpolator is busy
    -- 2.- Input data cannot change while the interpolator is busy
    -- (the interpolator is busy if 0 <= i <= 11)
    --
    -- An interesting idea here would be to define a procedure in
    -- edc_common/edc_common called "fail_in_N_cycles", which would
    -- wait N clock cycles before stopping the simulation
    firewall_assertions: process (clk)
    begin
        if falling_edge(clk) then
            firewall_sup <= sup;
            firewall_inf <= inf;
            if (i >= 0) and (i <= 11) then
                if valid = '1' then
                    report "valid asserted while interpolator busy, data will be lost"
                    severity failure;
                end if;
                if (inf /= firewall_inf) or (sup /= firewall_sup) then
                    report "data changed while interpolator busy, interpolation will be wrong"
                    severity failure;
                end if;
            end if;
        end if;
    end process;

end two_processes;
