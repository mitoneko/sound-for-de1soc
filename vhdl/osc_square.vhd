library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity osc_square is
   port (
        clk:    in  std_logic;
        f:      in  std_logic_vector(15 downto 0);
        q:      out std_logic_vector(15 downto 0)
    );
end osc_square;

architecture RTL of osc_square is
    signal clk_cnt: integer range 0 to 65535;
    signal clk_65535hz: std_logic;
    signal f_cnt:   std_logic_vector(15 downto 0) := b"0000_0000_0000_0000";
begin
    process(clk)
    begin
        if (clk'event and clk='1') then
            if (clk_cnt = 1526) then
                clk_cnt <= 0;
            else 
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;
    clk_65535hz <= '1' when clk_cnt = 0 else '0';

    process(clk)
    begin
        if (clk'event and clk='1') then
            if (clk_65535hz = '1') then
                f_cnt <= std_logic_vector(signed(f_cnt) + signed(f));
            end if;
        end if;
    end process;
    q <= b"1000_0000_0000_0000" when f_cnt(15) = '0' else b"0111_1111_1111_1111";
end RTL;



            

