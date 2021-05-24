library IEEE;
use IEEE.std_logic_1164.all;

entity i2cmaster is
    port (  clk:    in  std_logic;
            rst:    in  std_logic;
            sclk:   inout   std_logic;
            sdat:   inout   std_logic;
            load:   in  std_logic;
            addr:   in  std_logic_vector(6 downto 0);
            data:   in  std_logic_vector(8 downto 0);
            busy:   out std_logic
            );
end i2cmaster;

architecture RTL of i2cmaster is
    component gen_sclk is
       port (   clk:    in      std_logic;  -- master clock(100MHz)
                rst:    in      std_logic;  
                ena:    in      std_logic; 
                sclk:   inout   std_logic;
                sdat:   out     std_logic;  -- for start and stop condition
                can_data_change: out std_logic
            );
    end component;

    signal can_data_change: std_logic;
    signal data_hi, data_lo : std_logic_vector(7 downto 0);
    signal sclk_ena: std_logic;
    constant i2c_address: std_logic_vector(6 downto 0) := "0011010";
    
    -- shift register
    type fms_shift_reg_status_t is (idle, reg_load, shift);
    signal fms_shift_reg_stat: fms_shift_reg_status_t;
    signal shift_enable: std_logic;
    signal shift_cnt: integer range 0 to 9;
    signal shift_reg: std_logic_vector(7 downto 0);
    signal shift_data: std_logic_vector(7 downto 0);
    signal send_bit: std_logic;

    -- detect sclk riseup
    signal sclk_rise: std_logic;
    signal sclk_reg: std_logic_vector(1 downto 0);

    -- i2c control
    type fms_i2c_master_status_t is 
        (idle, address_send1, address_send2, address_ack, data_hi_send1, data_hi_send2,
        data_hi_ack, data_lo_send1, data_lo_send2, data_lo_ack, end_seq);
    signal fms_i2c_master_status: fms_i2c_master_status_t;

begin
    U1: gen_sclk port map(clk=>clk, rst=>rst, ena=>sclk_ena , sclk=>sclk, sdat=>sdat, can_data_change=>can_data_change);
    data_hi <= addr & data(8);
    data_lo <= data(7 downto 0);

    -- shift register
    process(clk)
    begin
        if (clk'event and clk='1') then
            case fms_shift_reg_stat is
                when idle =>
                    shift_cnt <= 0;
                    if (shift_enable = '1') then
                        fms_shift_reg_stat <= reg_load;
                    end if;
                when reg_load =>
                    shift_reg <= shift_data;
                    fms_shift_reg_stat <= shift;
                when shift =>
                    if (shift_cnt = 9) then
                        fms_shift_reg_stat <= idle;
                    elsif (can_data_change = '1') then
                        send_bit <= shift_reg(7);
                        shift_reg <= shift_reg(6 downto 0) & "0";
                        shift_cnt <= shift_cnt + 1;
                    end if;
            end case;
        end if;
    end process;
    
    -- detect sclk riseup
    process(clk)
    begin
        if (clk'event and clk='1') then
            sclk_reg <= sclk_reg(0) & To_X01(sclk);
        end if;
    end process;
    sclk_rise <= '1' when sclk_reg="01" else '0';

    -- i2c control
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (rst = '1') then
                fms_i2c_master_status <= idle;
            else
                case fms_i2c_master_status is
                    when idle =>
                        if (load = '1') then
                            shift_data <= i2c_address & '0';
                            fms_i2c_master_status <= address_send1;
                        end if;
                    when address_send1 =>
                        fms_i2c_master_status <= address_send2;
                    when address_send2 =>
                        if (fms_shift_reg_stat = idle) then
                            fms_i2c_master_status <= address_ack;
                        end if;
                    when address_ack =>
                        if (sclk_rise = '1') then
                            if (To_X01(sdat) = '0') then
                                shift_data <= data_hi;
                                fms_i2c_master_status <= data_hi_send1;
                            else
                                fms_i2c_master_status <= idle;
                            end if;
                        end if;
                    when data_hi_send1 =>
                        fms_i2c_master_status <= data_hi_send2;
                    when data_hi_send2 =>
                        if (fms_shift_reg_stat = idle) then
                            fms_i2c_master_status <= data_hi_ack;
                        end if;
                    when data_hi_ack =>
                        if (sclk_rise = '1') then
                            if (To_X01(sdat) = '0') then
                                shift_data <= data_lo;
                                fms_i2c_master_status <= data_lo_send1;
                            else
                                fms_i2c_master_status <= idle;
                            end if;
                        end if;
                    when data_lo_send1 =>
                        fms_i2c_master_status <= data_lo_send2;
                    when data_lo_send2 =>
                        if (fms_shift_reg_stat = idle) then
                            fms_i2c_master_status <= data_lo_ack;
                        end if;
                    when data_lo_ack =>
                        if (sclk_rise = '1') then
                            if (To_X01(sdat) = '0') then
                                fms_i2c_master_status <= end_seq;
                            else
                                fms_i2c_master_status <= idle;
                            end if;
                        end if;
                    when end_seq =>
                        if (can_data_change = '1') then
                            fms_i2c_master_status <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process;
    shift_enable <= '1' when fms_i2c_master_status = address_send1 else
                    '1' when fms_i2c_master_status = data_hi_send1 else
                    '1' when fms_i2c_master_status = data_lo_send1 else
                    '0';
    sclk_ena <= '1' when fms_i2c_master_status /= idle else '0';
    busy <= '1' when fms_i2c_master_status /= idle else '0';
    sdat <= send_bit when fms_i2c_master_status = address_send2 else
            send_bit when fms_i2c_master_status = data_hi_send2 else
            send_bit when fms_i2c_master_status = data_lo_send2 else
            'Z';

end RTL;
