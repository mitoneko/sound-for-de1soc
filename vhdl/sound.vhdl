library IEEE;
use IEEE.std_logic_1164.all;

entity sound is
    port (  
            -- clock
            clk50:      in      std_logic;
            -- WM8731 audio codec
            daclrck:    in      std_logic;
            dacdat:     out     std_logic;
            aud_xck:    out     std_logic; -- 12.288MHz
            aud_bclk:   in      std_logic;
            aud_sclk:   inout   std_logic;
            aud_sdat:   inout   std_logic;
            -- SW LED etc.
            key:        in      std_logic_vector(3 downto 0);
            sw:         in      std_logic_vector(9 downto 0);
            led:        out     std_logic_vector(9 downto 0)
        );
end sound;

architecture RTL of sound is
    component master_pll is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk(100MHz)
            outclk_1 : out std_logic;        -- outclk1.clk(15.295081MHz)
            locked   : out std_logic         --  locked.export
        );
    end component ;

    component reset is
        port (  pll_lock:   in  std_logic;
                clk:        in  std_logic;
                reset:      out std_logic );
    end component;

    component wm8731_control is
        port (
                clk:        in      std_logic;
                rst:        in      std_logic;
                aud_sclk:   inout   std_logic;
                aud_sdat:   inout   std_logic;
                busy:       out     std_logic
             );
    end component;

    component wm8731_i2s is
        port (
                clk:        in      std_logic;
                rst:        in      std_logic;
                aud_bclk:   in      std_logic;
                daclrck:    in      std_logic;
                dacdat:     out     std_logic;
                wave_dat:   in      std_logic_vector(15 downto 0)
             );
    end component;

    component clk_division is
        port (  ratio:  in  std_logic_vector(7 downto 0);
                clk_m:  in  std_logic;
                clk_d:  out std_logic
            );
    end component;

    component gen_clk_65536hz is
        port (  clk:    in  std_logic;
                q:      out std_logic
            );
    end component;

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
                 toneno:    in  std_logic_vector(6 downto 0);
                 q:         out std_logic_vector(15 downto 0)
             );
    end component;

    component noteno IS
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            q		: OUT STD_LOGIC_VECTOR (13 DOWNTO 0)
        );
    END component;

    -- master clock control
    signal clk:         std_logic; -- master system clock(100MHz)
    signal rst:         std_logic; -- master system reset signal
    signal pll_lock:    std_logic;
    signal clk_d:       std_logic; -- variable clock for signal tap
    
    -- WM8731 Control
    signal wm8731_ctrl_busy: std_logic;
    signal wave_dat: std_logic_vector(15 downto 0);

    -- noteno input
    signal freq: std_logic_vector(15 downto 0);

    -- clock for osc
    signal clock_osc: std_logic;

    -- osc square
    signal q_square: std_logic_vector(15 downto 0);
    signal q_triangle: std_logic_vector(15 downto 0);
    signal q_sawtooth: std_logic_vector(15 downto 0);
    signal q_sin: std_logic_vector(15 downto 0);
    
begin
    --master clock conotrol
    pll_master: master_pll port map(refclk=>clk50, rst=>not key(0), outclk_0=>clk, outclk_1=>aud_xck, locked=>pll_lock);
    reset_master: reset port map(pll_lock=>pll_lock, clk=>clk, reset=>rst);
    clk_div: clk_division port map(ratio=>sw(7 downto 0), clk_m=>clk, clk_d=>clk_d);

    -- WM8731
    wm8731_ctrl: wm8731_control port map(clk=>clk, rst=>rst, aud_sclk=>aud_sclk ,aud_sdat=>aud_sdat, busy=>wm8731_ctrl_busy);
    wm8731_i2s1: wm8731_i2s port map(clk=>clk, rst=>rst, aud_bclk=>aud_bclk, daclrck=>daclrck, 
                                     dacdat=>dacdat, wave_dat=>wave_dat);

    -- noteno to frequency
    trance_freq: noteno port map (address => sw(6 downto 0), clock=>clk, q=>freq(13 downto 0));
    freq(15 downto 14) <= "00";

    -- osc kari(440Hz)
    clk_osc: gen_clk_65536hz port map(clk=>clk, q=>clock_osc);
    osc_s: osc_square port map(clk_s=>clock_osc, f=>freq, q=>q_square);
    osc_t: osc_triangle port map(clk_s=>clock_osc, f=>freq, q=>q_triangle);
    osc_sow: osc_sawtooth port map(clk_s=>clock_osc, f=>freq, q=>q_sawtooth);
    osc_sin1: osc_sin port map(clk=>clk, clk_s=>clock_osc, toneno=>sw(6 downto 0), q=>q_sin);
    with sw(9 downto 8) select
        wave_dat <= q_sin       when "00",
                    q_triangle  when "01",
                    q_sawtooth  when "10",
                    q_square    when "11",
                    (others => 'X') when others;

    -- print etc.
    led(9 downto 0) <= freq(9 downto 0); 

end RTL;
