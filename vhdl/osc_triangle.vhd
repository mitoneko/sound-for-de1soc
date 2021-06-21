library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity osc_triangle is
    port (  clk_s:  in  std_logic;
            f:      in  std_logic_vector(15 downto 0);
            q:      out std_logic_vector(15 downto 0)
        );
end osc_triangle;

architecture RTL of osc_triangle is
    signal delta_q: signed(15 downto 0);
    constant max_q: integer := 32767;
    constant min_q: integer := -32767;
    signal f_i: signed(15 downto 0) := (others => '0');
    signal q_i: signed(15 downto 0) := (others => '0');
    type updown_t is (up, down);
    signal updown : updown_t;
begin
    delta_q <= signed(f(14 downto 0) & '0');

    process(clk_s)
        variable neg_rest: signed(15 downto 0);
    begin
        if (clk_s'event and clk_s='1') then
            case updown is
                when up =>
                    if ((q_i(15) = '0') and (max_q - q_i < delta_q)) then
                        q_i <= max_q - (delta_q - (max_q - q_i)); 
                        updown <= down;
                    else
                        q_i <= q_i + delta_q;
                    end if;
                when down =>
                    neg_rest := (min_q - q_i);
                    neg_rest := (not neg_rest) + 1;
                    if (q_i(15) = '1') and (neg_rest < delta_q) then
                        q_i <= min_q + (delta_q - neg_rest);
                        updown <= up;
                    else 
                        q_i <= q_i - delta_q;
                    end if;
            end case;
        end if;
    end process;
    q <= std_logic_vector(q_i);
end RTL;
