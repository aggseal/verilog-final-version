## EGO1 pin constraints for dff.v
## 100 MHz onboard clock
set_property PACKAGE_PIN P17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk100 [get_ports clk]

## S1 pushbutton (active high when pressed)
set_property PACKAGE_PIN R17 [get_ports clr]
set_property IOSTANDARD LVCMOS33 [get_ports clr]

## SW7 slide switch: synchronous enable
set_property PACKAGE_PIN R1 [get_ports en]
set_property IOSTANDARD LVCMOS33 [get_ports en]

## SW0 slide switch: data input
set_property PACKAGE_PIN P5 [get_ports d]
set_property IOSTANDARD LVCMOS33 [get_ports d]

## GLD0 user LED (EGO1 LED0)
set_property PACKAGE_PIN K3 [get_ports q]
set_property IOSTANDARD LVCMOS33 [get_ports q]
