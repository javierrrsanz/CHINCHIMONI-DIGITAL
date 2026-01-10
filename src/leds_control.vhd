library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Necesario para MAX_PLAYERS, MAX_APUESTA y t_player_array

-- Modulo de control de la barra de LEDs
-- Este bloque traduce el valor numerico de una apuesta (0-12) a una 
-- representacion visual tipo "barra de progreso" en los 12 LEDs de la placa.
entity leds_control is
    Port (
        clk          : in  std_logic; -- Reloj de 125 MHz
        reset        : in  std_logic; -- Reset del sistema

        leds_enable  : in  std_logic; -- Habilita o apaga la visualizacion
        player_idx_a : in  integer range 1 to MAX_PLAYERS; -- Jugador a consultar
        out_apuestas : in  t_player_array; -- Banco de datos con todas las apuestas

        leds         : out std_logic_vector(11 downto 0) -- Salida fisica a los 12 LEDs
    );
end leds_control;

architecture Behavioral of leds_control is
    
    signal apuesta_val : integer range 0 to MAX_APUESTA := 0;
    signal mask        : std_logic_vector(11 downto 0) := (others => '0'); -- Registro temporal para la barra

begin

    -- Proceso de decodificacion y control
    process(clk, reset)
    begin
        -- Reset asincrono: apaga todos los LEDs inmediatamente
        if reset = '1' then
            mask <= (others => '0');
            leds <= (others => '0');

        elsif rising_edge(clk) then

            -- 1. Captura del valor: Leemos la apuesta del jugador indicado
            -- Accedemos al array global definido en el package
            apuesta_val <= out_apuestas(player_idx_a);

            -- 2. Generacion de la barra (Termometro):
            -- Si la apuesta es 3, se encienden 3 LEDs (000...00111)
            -- Si la apuesta es 12, se encienden todos (111...11111)
            for i in 0 to 11 loop
                if i < apuesta_val then
                    mask(i) <= '1'; -- LED encendido
                else
                    mask(i) <= '0'; -- LED apagado
                end if;
            end loop;

            -- 3. Salida final condicionada:
            -- Solo mostramos la barra si la FSM nos da permiso (leds_enable)
            if leds_enable = '1' then
                leds <= mask;
            else
                leds <= (others => '0'); -- Ahorro de energia o estados de espera
            end if;

        end if;
    end process;

end Behavioral;