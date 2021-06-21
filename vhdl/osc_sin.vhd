library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity osc_sin is
    port (   clk:       in  std_logic;
             clk_s:     in  std_logic;
             toneno:    in  std_logic_vector(6 downto 0);
             q:         out std_logic_vector(15 downto 0)
         );
end osc_sin;

architecture RTL of osc_sin is
    component sin_arl IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            q		: OUT STD_LOGIC_VECTOR (17 DOWNTO 0)
        );
    END component;

    component siny1 IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
        );
    END component;
    
    signal arl: signed(18 downto 0);
    signal y1_i:  signed(18 downto 0);
    signal arl_tmp: std_logic_vector(17 downto 0);
    signal y1_tmp: std_logic_vector(15 downto 0);
    signal clk_s_rise:  std_logic;
    signal clk_s_r:     std_logic_vector(1 downto 0);
    type fms_t is (start, init0, init1, add0, add1, add2);
    signal fms: fms_t;
    signal y0, y1: signed(18 downto 0);
    signal q_i: signed(16 downto 0);
    signal first_term: signed(37 downto 0);
    constant min_y: signed(18 downto 0) := b"111_0000_0000_0000_0001";

begin
    mem_arl: sin_arl port map(address=>toneno, clock=>clk, q=>arl_tmp);
    mem_y1:  siny1  port map(address=>toneno, clock=>clk, q=>y1_tmp);
    arl <= signed('0' & arl_tmp);
    y1_i <= signed("000" & y1_tmp);

    process(clk)
    begin
        if (clk'event and clk='1') then
            clk_s_r <= clk_s_r(0) & clk_s;
        end if;
    end process;
    clk_s_rise <= '1' when clk_s_r = "01" else '0';

    process(clk)
        variable tmp: signed(21 downto 0);
    begin
        if (clk'event and clk='1') then
            case fms is
                when start => 
                    fms <= init0;
                when init0 =>
                    if (clk_s_rise = '1') then
                        y0 <= (others => '0');
                        q_i <= (others => '0');
                        fms <= init1;
                    end if;
                when init1 =>
                    if (clk_s_rise = '1') then
                        y1 <= y1_i;
                        q_i <= y1_i(16 downto 0);
                        fms <= add0;
                    end if;
                when add0 =>
                    if (clk_s_rise = '1') then
                       first_term <= arl * y1;
                       fms <= add1;
                    end if;
                when add1 =>
                    y0 <= y1;
                    tmp := signed(first_term(37 downto 16)) - signed(y0);    -- s + 21 bit
                    y1 <= tmp(18 downto 0);                                  -- s + 18 bit
                    fms <= add2;
                when add2 =>
                    if ((y0(18) = '1') and (y1(18) = '0')) then
                        fms <= init0;
                    else
                        if (y1 < min_y) then
                            y1 <= min_y;
                            q_i <= b"1_0000_0000_0000_0001";
                        else 
                            q_i <= y1(18) & y1(15 downto 0);
                            fms <= add0;
                        end if;
                    end if;
            end case;
        end if;
    end process;
    q <= std_logic_vector(q_i(16 downto 1));
end RTL;
