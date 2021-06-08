# clock
create_clock -name clk50 -period 20.000 [get_ports {clk50}]
derive_pll_clocks
derive_clock_uncertainty

# io
set_false_path -from [get_ports {key[0] key[1] key[2] key[3]}]
set_false_path -from [get_ports {sw[0] sw[1] sw[2] sw[3] sw[4] sw[5] sw[6] sw[7] sw[8] sw[9]}]
set_false_path -to [get_ports {led[0] led[1] led[2] led[3] led[4] led[5] led[6] led[7] led[8] led[9]}]

#WM8731
set_false_path -from [get_ports {aud_sdat aud_sclk}]
set_false_path -to [get_ports {aud_sclk aud_sdat}]
set_false_path -to [get_ports *]
set_false_path -from [get_ports {aud_bclk daclrck}]
