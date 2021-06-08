library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clk_division is
    port (  ratio:  in  std_logic_vector(7 downto 0);
            clk_m:  in  std_logic;
            clk_d:  out std_logic
        );
end clk_division;

architecture RTL of clk_division is
    signal clk_cnt: integer range 0 to 256;
    signal ratio_i: integer range 0 to 255;
begin
    ratio_i <= to_integer(unsigned(ratio));
    process(clk_m)
    begin
        if (clk_m'event and clk_m='1') then
            if (ratio_i /= 0) then
                if (clk_cnt = ratio_i - 1) then
                    clk_cnt <= 0;
                else 
                    clk_cnt <= clk_cnt + 1;
                end if;
            else
                clk_cnt <= 0;
            end if;
        end if;
    end process;
    clk_d <= clk_m when (ratio_i<=1) else
             '1' when (ratio_i>1) and clk_cnt > to_integer(unsigned(ratio(7 downto 1))) else
             '0';
end RTL;
