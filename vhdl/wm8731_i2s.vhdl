library IEEE;
use IEEE.std_logic_1164.all;

entity wm8731_i2s is
    port (
            clk:        in      std_logic;
            rst:        in      std_logic;
            aud_bclk:   in      std_logic;
            daclrck:    in      std_logic;
            dacdat:     out     std_logic;
            wave_dat:   in      std_logic_vector(15 downto 0)
         );
end wm8731_i2s;

architecture RTL of wm8731_i2s is
    signal sound_shift: std_logic_vector(16 downto 0);
    signal sound_shift_cnt: integer range 0 to 17;
    signal aud_lrc_shift: std_logic_vector(1 downto 0);
    signal aud_lrc_rise: std_logic;
    signal aud_lrc_fall: std_logic;
    signal aud_bclk_shift: std_logic_vector(1 downto 0);
    signal aud_bclk_fall: std_logic;
    type fms_aud_status_t is (left_load, left_shift, right_load, right_shift);
    signal status_aud: fms_aud_status_t;

begin
    -- WM8731 I2S out
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (rst = '1') then
                aud_lrc_shift <= "00";
                aud_bclk_shift <= "00";
            else
                aud_lrc_shift <= aud_lrc_shift(0) & daclrck;
                aud_bclk_shift <= aud_bclk_shift(0) & aud_bclk;
            end if;
        end if;
    end process;
    aud_lrc_rise <= '1' when aud_lrc_shift="01" else '0';
    aud_lrc_fall <= '1' when aud_lrc_shift="10" else '0';
    aud_bclk_fall <= '1' when aud_bclk_shift="10" else '0';

    process(clk)
    begin 
        if (clk'event and clk='1') then
            if (rst = '1') then
                sound_shift_cnt <= 0;
                status_aud <= left_load;
            else
                case status_aud is
                    when left_load =>
                        if (aud_lrc_fall = '1') then
                            sound_shift <= '0' & wave_dat;
                            status_aud <= left_shift;
                        end if;
                    when left_shift =>
                        if (aud_bclk_fall = '1') then
                            sound_shift <= sound_shift(15 downto 0) & '0';
                            sound_shift_cnt <= sound_shift_cnt + 1;
                        end if;
                        if (sound_shift_cnt = 17) then
                            sound_shift_cnt <= 0;
                            status_aud <= right_load;
                        end if;
                    when right_load =>
                        if (aud_lrc_rise = '1') then
                            sound_shift <= '0' & wave_dat;
                            status_aud <= right_shift;
                        end if;
                    when right_shift =>
                        if (aud_bclk_fall = '1') then
                            sound_shift <= sound_shift(15 downto 0) & '0';
                            sound_shift_cnt <= sound_shift_cnt + 1;
                        end if;
                        if (sound_shift_cnt = 17) then
                            sound_shift_cnt <= 0;
                            status_aud <= left_load;
                        end if;
                end case;
            end if;
        end if;
    end process;
    dacdat <= sound_shift(16);
end RTL;
