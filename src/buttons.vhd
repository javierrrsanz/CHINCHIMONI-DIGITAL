library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity buttons is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        -- Entradas físicas (vienen del archivo XDC)
       
        in_continuar : in std_logic;
        in_confirmar : in std_logic;
        in_reinicio  : in std_logic;
        
        -- Salidas limpias para el juego
        out_continuar : out std_logic;
        out_confirmar : out std_logic;
        out_reinicio  : out std_logic
    );
end buttons;

architecture Structural of buttons is

    -- Declaramos el componente debouncer que ya tienes
    component debouncer
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            boton    : in  std_logic;
            filtrado : out std_logic
        );
    end component;

begin

    -- Instancia para el Botón B1 (Continuar)
    deb_b1: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_continuar,
            filtrado => out_continuar
        );

    -- Instancia para el Botón B2 (Reinicio)
    deb_b2: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_reinicio,
            filtrado => out_reinicio
        );

    -- Instancia para el Botón B3 (Confirmación)
    deb_b3: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_confirmar,
            filtrado => out_confirmar
        );

end Structural; 