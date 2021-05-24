library IEEE;
use IEEE.std_logic_1164.all;

entity test_i2c_master is
end test_i2c_master;

architecture SIM of test_i2c_master is
    component i2cmaster is
        port (  clk:    in  std_logic;
                rst:    in  std_logic;
                sclk:   inout   std_logic;
                sdat:    inout   std_logic;
                load:   in  std_logic;
                addr:   in  std_logic_vector(6 downto 0);
                data:   in  std_logic_vector(8 downto 0);
                busy:   out std_logic
                );
    end component;

    signal clk: std_logic := '0';
    signal rst: std_logic := '0';
    signal sclk: std_logic;
    signal sdat: std_logic;
    signal load: std_logic := '0';
    signal addr: std_logic_vector(6 downto 0);
    signal data: std_logic_vector(8 downto 0);
    signal busy: std_logic;

    signal sclk_cnt: integer range 0 to 8 := 0;
    signal sclk_shift: std_logic_vector(1 downto 0) := "11";
    signal recv_data: std_logic_vector(8 downto 0) := (others=>'0');
    signal sdat_i: std_logic := 'Z';
begin
    U1: i2cmaster port map (clk, rst, sclk, sdat, load, addr, data, busy);
    sclk <= 'H';
    sdat <= '0' when sdat_i='0' else 'H';
    
    process begin
        clk <= not clk;
        wait for 5 ns;
    end process;
    rst <= '1' after 10 ns, '0' after 100 ns;

    process(clk)
    begin
        if (clk'event and clk='1') then
            sclk_shift <= sclk_shift(0) & To_X01(sclk);
            if (sclk_shift = "01") then
                if (sclk_cnt = 8) then
                    sclk_cnt <= 0;
                else 
                    sclk_cnt <= sclk_cnt + 1;
                end if;
                recv_data <= recv_data(7 downto 0) & To_X01(sdat);
            end if;
        end if;
    end process;

    addr <= "1101010";
    data <= "011001101";

    process begin
        wait for 1 us;
        load <= '1'; wait for 10 ns;
        load <= '0';
        
        wait until sclk_shift="10" and sclk_cnt=8;
        sdat_i <= '0'; wait for 5 ns;
        wait until sclk_shift="10";
        sdat_i <= 'Z';

        wait until sclk_shift="10" and sclk_cnt=8;
        sdat_i <= '0'; wait for 5 ns;
        wait until sclk_shift="10";
        sdat_i <= 'Z';

        wait until sclk_shift="10" and sclk_cnt=8;
        sdat_i <= '0'; wait for 5 ns;
        wait until sclk_shift="10";
        sdat_i <= 'Z';

        wait for 100 us;

        assert false report "end." severity FAILURE;
    end process;
end SIM;
    
