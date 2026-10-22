
# Enable
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports en];

# Mux select
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports mux_sel];

# Input A: SW0-SW3
set_property -dict {PACKAGE_PIN R1 IOSTANDARD LVCMOS33} [get_ports {input_a[0]}];
set_property -dict {PACKAGE_PIN N4 IOSTANDARD LVCMOS33} [get_ports {input_a[1]}];
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {input_a[2]}];
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {input_a[3]}];

# Input B: SW4-SW7
set_property -dict {PACKAGE_PIN P2 IOSTANDARD LVCMOS33} [get_ports {input_b[0]}];
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {input_b[1]}];
set_property -dict {PACKAGE_PIN P4 IOSTANDARD LVCMOS33} [get_ports {input_b[2]}];
set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS33} [get_ports {input_b[3]}];

# Output C: LD2_0-LD2_3
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {output_c[0]}];
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {output_c[1]}];
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {output_c[2]}];
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {output_c[3]}];

