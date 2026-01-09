## Clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {clk}];

## Reset - Switch 0 (placa rosa SW0)
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {reset}]

#LEDs (placa rosa LD0-LD3)
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {leds_4[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {leds_4[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds_4[3]}]

## Botones (placa rosa BTN0-BTN3)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {botones[3]}]  #confirmacion
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {botones[2]}]  #reincio
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {botones[1]}]  #continuar


#Selectores Displays (placa negra)
set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { selector[0] }]; # Disp4
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { selector[1] }]; # Disp3
set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS33 } [get_ports { selector[2] }]; # Disp2 
set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { selector[3] }]; # Disp1

#Segments (placa negra)
set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { segments[0] }]; #--24 segment 0 (g)
set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { segments[1] }]; #--20 segment 1 (f)
set_property -dict { PACKAGE_PIN V6    IOSTANDARD LVCMOS33 } [get_ports { segments[2] }]; #--14 segment 2 (e)
set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { segments[3] }]; #--15 segment 3 (d)
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { segments[4] }]; #--23 segment 4 (c)
set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { segments[5] }]; #--8  segment 5 (b)
set_property -dict { PACKAGE_PIN Y9    IOSTANDARD LVCMOS33 } [get_ports { segments[6] }]; #--21 segment 6 (a)

#LEDs (placa negra)
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33}  [get_ports {leds_8[0]}];
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33}  [get_ports {leds_8[1]}];
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33}  [get_ports {leds_8[2]}]; 
set_property -dict { PACKAGE_PIN U7  IOSTANDARD LVCMOS33 } [get_ports {leds_8[3]}]; 
set_property -dict { PACKAGE_PIN V7  IOSTANDARD LVCMOS33 } [get_ports {leds_8[4]}];
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports {leds_8[5]}];
set_property -dict { PACKAGE_PIN V8  IOSTANDARD LVCMOS33 } [get_ports {leds_8[6]}]; 
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports {leds_8[7]}]; 

#SWITCHES (placa negra)
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { switches[3] }];
set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33 } [get_ports { switches[2] }];
set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33 } [get_ports { switches[1] }];
set_property -dict { PACKAGE_PIN W8    IOSTANDARD LVCMOS33 } [get_ports { switches[0] }];