
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chinchimoni_top is
    Port (
        clk       : in  std_logic;                      -- Reloj 125 MHz
        reset     : in  std_logic;                      -- Botón de reinicio
        botones   : in  std_logic_vector(2 downto 0);   -- B1=continuar, B2=confirmar, B3=reinicio
        switches  : in  std_logic_vector(3 downto 0);   -- Switches para selección/apuestas
        mode      : in  std_logic_vector(1 downto 0);   -- Modo de juego
        segments  : out std_logic_vector(7 downto 0);   -- Señales para display 7 segmentos
        selector  : out std_logic_vector(3 downto 0);   -- Selección de dígitos
        leds      : out std_logic_vector(7 downto 0)    -- LEDs para puntos/apuestas
    );
end chinchimoni_top;

architecture Structural of chinchimoni_top is

    -- Señales internas para interconexión
    signal estado_actual : std_logic_vector(3 downto 0);
    signal tiempo_listo  : std_logic;
    signal valor_random  : std_logic_vector(3 downto 0);
    signal entradas_ok   : std_logic;
    signal datos_switch  : std_logic_vector(3 downto 0);
    signal jugador_ai    : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------
    -- Bloque FSM: Control del juego
    --------------------------------------------------------------------
    fsm_control: entity work.control_fsm
        port map (
            clk        => clk,
            reset      => reset,
            botones    => botones,
            switches   => datos_switch,
            mode       => mode,
            tiempo_ok  => tiempo_listo,
            random_val => valor_random,
            ai_val     => jugador_ai,
            estado     => estado_actual,
            leds       => leds
        );

    --------------------------------------------------------------------
    -- Bloque Control de Displays
    --------------------------------------------------------------------
    display_ctrl: entity work.display_manager
        port map (
            clk      => clk,
            estado   => estado_actual,
            segments => segments,
            selector => selector
        );

    --------------------------------------------------------------------
    -- Bloque Control de LEDs
    --------------------------------------------------------------------
    leds_ctrl: entity work.led_manager
        port map (
            clk    => clk,
            estado => estado_actual,
            leds   => leds
        );

    --------------------------------------------------------------------
    -- Bloque Timer (temporización y refresco)
    --------------------------------------------------------------------
    timer_ctrl: entity work.timer
        port map (
            clk       => clk,
            tiempo_ok => tiempo_listo
        );

    --------------------------------------------------------------------
    -- Bloque Botones (lectura y validación)
    --------------------------------------------------------------------
    botones_ctrl: entity work.botones
        port map (
            clk      => clk,
            botones  => botones
        );

    --------------------------------------------------------------------
    -- Bloque Switches (lectura y validación)
    --------------------------------------------------------------------
    switches_ctrl: entity work.switches
        port map (
            clk      => clk,
            switches => switches,
            valor    => datos_switch
        );

    --------------------------------------------------------------------
    -- Bloque Anti-rebotes
    --------------------------------------------------------------------
    debouncer_ctrl: entity work.debouncer
        port map (
            clk      => clk,
            botones  => botones,
            limpio   => entradas_ok
        );

    --------------------------------------------------------------------
    -- Bloque Generación Aleatoria
    --------------------------------------------------------------------
    random_gen: entity work.random_generator
        port map (
            clk    => clk,
            valor  => valor_random
        );

    --------------------------------------------------------------------
    -- Bloque AI Player
    --------------------------------------------------------------------
    ai_player_ctrl: entity work.ai_player
        port map (
            clk       => clk,
            random_in => valor_random,
            ai_val    => jugador_ai
        );

end Structural;
