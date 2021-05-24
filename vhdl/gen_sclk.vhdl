-- generate i2c sclk for VM8731
library IEEE;
use IEEE.std_logic_1164.all;

entity gen_sclk is
   port (   clk:    in      std_logic;  -- master clock(100MHz)
            rst:    in      std_logic;  
            ena:    in      std_logic; 
            sclk:   inout   std_logic;
            sdat:   out     std_logic;  -- for start and stop condition
            can_data_change: out std_logic
        );
end gen_sclk;

architecture RTL of gen_sclk is
    type fms_status_t is (idle, start_cond1, start_cond2, run, end_cond);
    signal fms_status: fms_status_t;
    constant data_hold:  integer := 90;
    constant start_setup: integer := 60;
    constant sclk_half_period: integer := 500;
    signal sclk_cnt: integer range 0 to sclk_half_period * 2;
begin
    -- sclk counter
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (fms_status = idle) then
                sclk_cnt <= 0;
            elsif (sclk_cnt = sclk_half_period * 2 - 1) then
                sclk_cnt <= 0;
            elsif (not (sclk_cnt < sclk_half_period and To_X01(sclk) = '0')) then
                sclk_cnt <= sclk_cnt + 1;
            end if;
        end if;
    end process;

    -- FMS for control sclk and generate start and end condition
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (rst = '1') then
                fms_status <= idle;
            else
                case fms_status is
                    when idle =>
                        if (ena = '1') then 
                            fms_status <= start_cond1;
                        end if;
                    when start_cond1 =>
                        if (sclk_cnt = start_setup) then
                            fms_status <= start_cond2;
                        end if;
                    when start_cond2 =>
                        if (sclk_cnt = sclk_half_period + (data_hold / 2)) then
                            fms_status <= run;
                        end if;
                    when run =>
                        if (ena = '0') then
                            fms_status <= end_cond;
                        end if;
                    when end_cond =>
                        if (sclk_cnt = start_setup) then
                            fms_status <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    sclk <= '0' when sclk_cnt >= sclk_half_period else 'Z';
    sdat <= '0' when fms_status = start_cond2 else
            '0' when fms_status = end_cond else
            'Z';
    can_data_change <= '1' when fms_status = run and sclk_cnt = sclk_half_period+data_hold else '0';
end RTL;
