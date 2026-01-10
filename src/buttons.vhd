library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Modulo de gestion de pulsadores
-- Este bloque centraliza las entradas fisicas de la placa y las pasa por un
-- circuito anti-rebotes para evitar falsas pulsaciones durante el juego.
entity buttons is
    Port (
        clk           : in  std_logic; -- Reloj de 125 MHz
        reset         : in  std_logic; -- Señal de inicializacion
        
        -- Entradas fisicas (conectadas a los pines de la placa Pynq-Z2)
        in_continuar  : in  std_logic; -- Pulsador para saltar esperas
        in_confirmar  : in  std_logic; -- Pulsador para validar selecciones
        in_reinicio   : in  std_logic; -- Pulsador para resetear la partida
        
        -- Salidas filtradas (señales limpias que van a la FSM principal)
        out_continuar : out std_logic;
        out_confirmar : out std_logic;
        out_reinicio  : out std_logic
    );
end buttons;

architecture Structural of buttons is

    -- Declaracion del componente debouncer (anti-rebotes)
    -- Se encarga de limpiar el ruido mecanico de cada pulsador.
    component debouncer
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            boton    : in  std_logic;
            filtrado : out std_logic
        );
    end component;

begin

    -- Instancia para el Boton de Continuar
    -- Permite pasar de pantalla en el display sin esperar los 5 segundos.
    deb_b1: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_continuar,
            filtrado => out_continuar
        );

    -- Instancia para el Boton de Reinicio
    -- Se utiliza para volver al estado inicial cuando termina una partida.
    deb_b2: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_reinicio,
            filtrado => out_reinicio
        );

    -- Instancia para el Boton de Confirmacion
    -- Es fundamental para validar el numero de jugadores, piedras y apuestas.
    deb_b3: debouncer 
        port map (
            clk      => clk,
            reset    => reset,
            boton    => in_confirmar,
            filtrado => out_confirmar
        );

end Structural;