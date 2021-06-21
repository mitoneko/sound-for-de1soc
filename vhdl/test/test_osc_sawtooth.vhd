library IEEE;
use IEEE.std_logic_1164.all;

entity test_osc_sawtooth is
end test_osc_sawtooth;

architecture SIM of test_osc_sawtooth is
    component gen_clk_65536hz is
        port (  clk:    in  std_logic;
                q:      out std_logic
            );
    end component;
    
    component osc_sawtooth is
        port (  clk_s:  in  std_logic;
                f:      in std_logic_vector(15 downto 0);
                q:      out std_logic_vector(15 downto 0)
            );
    end component;

    signal clk: std_logic := '0';
    signal clk_s: std_logic;
    signal f: std_logic_vector(15 downto 0) := 16d"440";
    signal q: std_logic_vector(15 downto 0);

begin
    gen_clk: gen_clk_65536hz port map (clk, clk_s);
    osc: osc_sawtooth port map(clk_s, f, q);

    process begin
        clk <= not clk;
        wait for 5 ns;
    end process;
end SIM;
