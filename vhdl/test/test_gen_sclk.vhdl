library IEEE;
use IEEE.std_logic_1164.all;

entity test_gen_sclk is
end test_gen_sclk;

architecture RTL of test_gen_sclk is
    component gen_sclk is
       port (   clk:    in      std_logic;  -- master clock(100MHz)
                rst:    in      std_logic;  
                ena:    in      std_logic; 
                sclk:   inout   std_logic;
                sdat:   out     std_logic;  -- for start and stop condition
                can_data_change: out std_logic
            );
    end component;

    signal clk: std_logic :='0';
    signal rst: std_logic :='1';
    signal ena: std_logic :='0';
    signal sclk: std_logic :='Z';
    signal sdat: std_logic ;
    signal can_data_change: std_logic;
begin
    U1: gen_sclk port map(clk, rst, ena, sclk, sdat, can_data_change);

    process begin
        clk <= not clk;
        wait for 5 ns;
    end process;
    rst <= '0' after 100 ns;
    ena <= '1' after 1 us, '0' after 194 us;
    sclk <= '0' after 50 us, 'Z' after 80 us;

    process begin
        wait for 250 us;
        assert false report "end." severity FAILURE;
    end process;
end RTL;
