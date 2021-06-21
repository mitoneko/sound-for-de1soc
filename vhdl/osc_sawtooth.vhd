library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity osc_sawtooth is
    port (  clk_s:  in  std_logic;
            f:      in  std_logic_vector(15 downto 0);
            q:      out std_logic_vector(15 downto 0)
        );
end osc_sawtooth;

architecture RTL of osc_sawtooth is
    signal delta_q: signed(15 downto 0);
    constant max_q: integer := 32767;
    constant min_q: integer := -32767;
    signal f_i: signed(15 downto 0) := (others => '0');
    signal q_i: signed(15 downto 0) := (others => '0');
begin
    delta_q <= signed(f(15 downto 0));

    process(clk_s)
        variable neg_rest: signed(15 downto 0);
    begin
        if (clk_s'event and clk_s='1') then
            if ((q_i(15) = '0') and (max_q - q_i < delta_q)) then
                neg_rest := max_q - q_i;
                q_i <= min_q + (delta_q - neg_rest); 
            else
                q_i <= q_i + delta_q;
            end if;
        end if;
    end process;
    q <= std_logic_vector(q_i);
end RTL;
