library IEEE;
use IEEE.std_logic_1164.all;

entity osc is
    port (  clk:    in  std_logic;
            clk_s:  in  std_logic;
            kind:   in  std_logic_vector(1 downto 0);
            noteno: in  std_logic_vector(6 downto 0);
            q:      out std_logic_vector(15 downto 0)
        );
end osc;

architecture RTL of osc is
    component osc_square is
       port (
            clk_s:    in  std_logic;
            f:      in  std_logic_vector(15 downto 0);
            q:      out std_logic_vector(15 downto 0)
        );
    end component;
    
    component osc_triangle is
        port (  clk_s:  in  std_logic;
                f:      in  std_logic_vector(15 downto 0);
                q:      out std_logic_vector(15 downto 0)
            );
    end component;

    component osc_sawtooth is
        port (  clk_s:  in  std_logic;
                f:      in  std_logic_vector(15 downto 0);
                q:      out std_logic_vector(15 downto 0)
            );
    end component;

    component osc_sin is
        port (   clk:       in  std_logic;
                 clk_s:     in  std_logic;
                 noteno:    in  std_logic_vector(6 downto 0);
                 q:         out std_logic_vector(15 downto 0)
             );
    end component;

    component noteno2freq IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            q		: OUT STD_LOGIC_VECTOR (13 DOWNTO 0)
        );
    END component;

    signal freq:    std_logic_vector(15 downto 0);
    signal q_square: std_logic_vector(15 downto 0);
    signal q_triangle: std_logic_vector(15 downto 0);
    signal q_sawtooth: std_logic_vector(15 downto 0);
    signal q_sin: std_logic_vector(15 downto 0);
begin
    -- noteno to frequency
    trance_freq: noteno2freq port map (address => noteno, clock=>clk, q=>freq(13 downto 0));
    freq(15 downto 14) <= "00";

    -- osc kari(440Hz)
    osc_s: osc_square port map(clk_s=>clk_s, f=>freq, q=>q_square);
    osc_t: osc_triangle port map(clk_s=>clk_s, f=>freq, q=>q_triangle);
    osc_sow: osc_sawtooth port map(clk_s=>clk_s, f=>freq, q=>q_sawtooth);
    osc_sin1: osc_sin port map(clk=>clk, clk_s=>clk_s, noteno=>noteno, q=>q_sin);
    with kind select
        q <=    q_sin       when "00",
                q_triangle  when "01",
                q_sawtooth  when "10",
                q_square    when "11",
                (others => 'X') when others;

end RTL;

            
