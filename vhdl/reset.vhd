library IEEE;
use IEEE.std_logic_1164.all;

entity reset is
    port (  pll_lock:   in  std_logic;
            clk:        in  std_logic;
            reset:      out std_logic );
end reset;

architecture RTL of reset is
    constant CNT_MAX : integer  := 99;
    signal rst_cnt: integer range 0 to CNT_MAX+1;
begin
    process(clk, pll_lock)
    begin
        if (pll_lock = '0') then
            rst_cnt <= 0;
        elsif (clk'event and clk='1') then
            if (rst_cnt < CNT_MAX) then
                rst_cnt <= rst_cnt + 1;
            end if;
        end if;
    end process;
    reset <= '1' when rst_cnt < CNT_MAX else '0';
end RTL;
