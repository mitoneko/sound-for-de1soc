library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity osc_square is
   port (
        clk_s:  in  std_logic; -- clock for sampling(2^16hz)
        f:      in  std_logic_vector(15 downto 0);
        q:      out std_logic_vector(15 downto 0)
    );
end osc_square;

architecture RTL of osc_square is
    signal f_cnt:   std_logic_vector(15 downto 0) := b"0000_0000_0000_0000";
begin
    process(clk_s)
    begin
        if (clk_s'event and clk_s='1') then
            f_cnt <= std_logic_vector(signed(f_cnt) + signed(f));
        end if;
    end process;
    q <= b"1000_0000_0000_0000" when f_cnt(15) = '0' else b"0111_1111_1111_1111";
end RTL;



            

