library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;  -- Para MAX_PLAYERS y t_player_array

entity leds_control is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        led_enable   : in  std_logic;                       -- Si = '1' mostramos LEDs
        player_idx_a : in  integer range 1 to MAX_PLAYERS;  -- Jugador que está apostando (1..4)
        out_apuestas : in  t_player_array;                  -- Apuestas de todos los jugadores

        leds         : out std_logic_vector(7 downto 0)      -- LEDs (activo-alto normalmente)
    );
end leds_control;

architecture Behavioral of leds_control is
    signal apuesta_sel : integer range 0 to 15 := 0;  -- t_player_array usa 0..15
begin

    -- Proceso 100% síncrono (como has pedido)
    process(clk, reset)
    begin
        if reset = '1' then
            leds        <= (others => '0');   -- Apaga todos los LEDs al reset
            apuesta_sel <= 0;

        elsif rising_edge(clk) then

            -- Guardamos la apuesta del jugador actual (registrado)
            apuesta_sel <= out_apuestas(player_idx_a);

            if led_enable = '1' then
                -- Mostramos la apuesta seleccionada en binario en los LEDs
                leds <= std_logic_vector(to_unsigned(apuesta_sel, 8));
            else
                -- Si led_enable=0, LEDs apagados
                leds <= (others => '0');
            end if;

        end if;
    end process;

end Behavioral;