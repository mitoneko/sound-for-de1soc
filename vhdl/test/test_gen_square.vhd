library IEEE;
use IEEE.std_logic_1164.all;

entity test_gen_square is
end test_gen_square;

architecture SIM of test_gen_square is
    component osc_square is
       port (
            clk:    in  std_logic;
            f:      in  std_logic_vector(15 downto 0);
            q:      out std_logic
        );
    end component;

    signal clk: std_logic := '0';
    signal f: std_logic_vector(15 downto 0) := b"0000_0001_1011_1000";
    signal q: std_logic;
begin

    U1: osc_square port map(clk, f, q);

    process begin
        wait for 5 ns;
        clk <= not clk;
    end process;
end SIM;
