library IEEE;
use IEEE.std_logic_1164.all;

entity gen_clk_65536hz is
    port (  clk:    in  std_logic;
            q:      out std_logic
        );
end gen_clk_65536hz;

architecture RTL of gen_clk_65536hz is
    constant period: integer := 1526;
    constant half_period: integer := period / 2;
    signal clk_cnt: integer range 0 to 65535;
begin
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (clk_cnt = period) then
                clk_cnt <= 0;
            else 
                clk_cnt <= clk_cnt + 1;
            end if;
            if (clk_cnt <= half_period) then
                q <= '0';
            else
                q <= '1';
            end if;
        end if;
    end process;
end RTL;
