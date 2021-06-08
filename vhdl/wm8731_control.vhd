library IEEE;
use IEEE.std_logic_1164.all;

entity wm8731_control is
    port (
            clk:        in      std_logic;
            rst:        in      std_logic;
            aud_sclk:   inout   std_logic;
            aud_sdat:   inout   std_logic;
            busy:       out     std_logic
         );
end wm8731_control;

architecture RTL of wm8731_control is
    component i2cmaster is
        port (  clk:    in  std_logic;
                rst:    in  std_logic;
                sclk:   inout   std_logic;
                sdat:   inout   std_logic;
                load:   in  std_logic;
                addr:   in  std_logic_vector(6 downto 0);
                data:   in  std_logic_vector(8 downto 0);
                busy:   out std_logic;
                err:    out std_logic;
                err_rst: in std_logic
                );
    end component;

    -- WM8731 Control
    type fms_wm8731_status_t is (idle, init1, init2, init3, init4, init5, init6, init7 );
    signal status_8731: fms_wm8731_status_t;
    type fms_i2c_status_t is (idle, wait_busy, end_seq, err_seq);
    signal status_i2c: fms_i2c_status_t;
    signal aud_load: std_logic;
    signal aud_addr: std_logic_vector(6 downto 0);
    signal aud_data: std_logic_vector(8 downto 0);
    signal aud_busy: std_logic;
    signal init_puls: std_logic;
    signal rst_reg: std_logic_vector(1 downto 0);
    signal w8731_init_seq: std_logic;
    signal i2c_err: std_logic;
    signal i2c_err_rst: std_logic;

begin
    -- WM8731 control
    i2c: i2cmaster port map(clk=>clk, rst=>rst, sclk=>aud_sclk, sdat=>aud_sdat, 
                            load=>aud_load, addr=>aud_addr, data=>aud_data, busy=>aud_busy, 
                            err=>i2c_err, err_rst=>i2c_err_rst);
    process (clk)
    begin
        if (clk'event and clk='1') then
            rst_reg <= rst_reg(0) & rst;
        end if;
    end process;
    init_puls <= '1' when rst_reg="10" else '0';

    process (clk)
    begin
        if (clk'event and clk='1') then
            if (rst = '1') then
                status_8731 <= idle;
            else
                case status_8731 is
                    when idle =>
                        if (init_puls = '1') then
                            status_8731 <= init1;
                        end if;
                    when init1 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0010";
                            aud_data <= b"01" & b"111_1110";  
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init2;
                        end if;
                    when init2 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0011";
                            aud_data <= b"01" & b"110_1111";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init3;
                        end if;
                    when init3 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0100";
                            aud_data <= b"0_0001_0010";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init4;
                        end if;
                    when init4 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0101";
                            aud_data <= b"0_0000_0000";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init5;
                        end if;
                    when init5 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0110";
                            aud_data <= b"0_0100_0111";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init6;
                        end if;
                    when init6 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_0111";
                            aud_data <= b"0_0100_0010";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= init7;
                        end if;
                    when init7 =>
                        if (status_i2c = idle) then
                            aud_addr <= b"000_1001";
                            aud_data <= b"0_0000_0001";
                        elsif (status_i2c = end_seq) then
                            status_8731 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process;
    with status_8731 select 
        w8731_init_seq <= '1' when init1 | init2 | init3 | init4 | init5 | init6 | init7,
                          '0' when others;
    aud_load <= '1' when w8731_init_seq='1' and (status_i2c=idle or status_i2c=err_seq) else '0';
    i2c_err_rst <= '1' when status_i2c=err_seq else '0';
    
    process (clk)
    begin
        if (clk'event and clk='1') then
            if (rst = '1') then
                status_i2c <= idle;
            else
                case status_i2c is
                    when idle =>
                        if (aud_load='1' and aud_busy='1') then
                            status_i2c <= wait_busy;
                        end if;
                    when wait_busy =>
                        if (aud_busy='0') then
                            status_i2c <= end_seq;
                        end if;
                    when end_seq =>
                        if (i2c_err = '1') then
                            status_i2c <= err_seq;
                        else
                            status_i2c <= idle;
                        end if;
                    when err_seq =>
                        if (aud_load='1' and aud_busy='1') then
                            status_i2c <= wait_busy;
                        end if;
                end case;
            end if;
        end if;
    end process;

    busy <= '0' when status_8731 = idle else '0';
end RTL;
