--====================================================================
--  Testbench: leds_control_tb.vhd
--  Objetivo : Banco de pruebas síncrono para leds_control.vhd (Vivado)
--             - Genera reloj a 125 MHz
--             - Aplica reset y lo libera en flanco de subida
--             - Fuerza out_apuestas y player_idx_a
--             - Activa/desactiva leds_enable
--             - Comprueba que la barra de LEDs coincide con la apuesta
--
--  Recordatorio de comportamiento esperado:
--    - Si leds_enable='0'  => leds = "000...0"
--    - Si leds_enable='1'  => leds(i)='1' para i < apuesta_val, si no '0'
--      (con i de 0 a 11)
--
--  IMPORTANTE:
--    En el DUT, leds <= mask dentro del mismo proceso donde mask se actualiza
--    con <=. Esto suele introducir 1 ciclo de retardo (leds muestra el mask
--    "anterior"). Por eso, en este TB comprobamos 2 ciclos despues de cambiar
--    estimulos, para evitar falsos fallos.
--====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;  -- MAX_PLAYERS, MAX_APUESTA, t_player_array

entity tb_leds_control is
end entity;

architecture tb of tb_leds_control is

    --========================
    -- Parametros de reloj
    --========================
    constant clk_period : time := 8 ns; -- 125 MHz

    --========================
    -- Senales para el DUT
    --========================
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';

    signal leds_enable  : std_logic := '0';
    signal player_idx_a : integer range 1 to MAX_PLAYERS := 1;
    signal out_apuestas : t_player_array := (others => 0);

    signal leds         : std_logic_vector(11 downto 0);

    constant LEDS_OFF : std_logic_vector(11 downto 0) := (others => '0');
    --========================
    -- Funcion auxiliar: genera la mascara esperada para N LEDs encendidos
    -- Encendemos leds(i)='1' para i < n, con i = 0..11
    --========================
    function expected_mask(n : integer) return std_logic_vector is
        variable m : std_logic_vector(11 downto 0) := (others => '0');
    begin
        for i in 0 to 11 loop
            if i < n then
                m(i) := '1';
            else
                m(i) := '0';
            end if;
        end loop;
        return m;
    end function;

begin

    --========================
    -- Instancia del DUT
    --========================
    uut : entity work.leds_control
        port map(
            clk          => clk,
            reset        => reset,
            leds_enable  => leds_enable,
            player_idx_a => player_idx_a,
            out_apuestas => out_apuestas,
            leds         => leds
        );

    --========================
    -- Generador de reloj
    --========================
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    --========================
    -- Proceso de estimulos (sincrono)
    --========================
    stim_proc : process
        variable exp : std_logic_vector(11 downto 0);
        variable val : integer;
    begin
        ------------------------------------------------------------
        -- 1) Reset sincrono
        ------------------------------------------------------------
       -- Reset sincrono
            reset <= '1';                 -- ACTIVAMOS reset
            wait for 3*clk_period;        -- lo mantenemos 3 ciclos
            reset <= '0';                 -- lo liberamos

        -- Comprobación tras reset (1-2 ciclos)
        wait for clk_period;
        wait for clk_period;
        
        assert leds = LEDS_OFF
            report "Tras reset, leds no esta a 0."
            severity error;

        ------------------------------------------------------------
        -- 2) Cargamos apuestas de ejemplo para jugadores
        --    (puedes ajustar los valores a lo que uses en tu FSM)
        ------------------------------------------------------------
        wait for clk_period;
        out_apuestas(1) <= 0;   -- jugador 1: 0 (ningún LED)
        out_apuestas(2) <= 3;   -- jugador 2: 3 LEDs
        out_apuestas(3) <= 7;   -- jugador 3: 7 LEDs
        out_apuestas(4) <= 12;  -- jugador 4: 12 LEDs (barra completa)

        ------------------------------------------------------------
        -- 3) Caso: leds_enable = 0 => siempre apagados
        ------------------------------------------------------------
        wait for clk_period;
        leds_enable  <= '0';
        player_idx_a <= 2;  -- aunque sea 3, no debe verse

        -- Esperamos 2 ciclos (por posible retardo interno)
       wait for clk_period;
       wait for clk_period;

        assert leds = LEDS_OFF
            report "Con leds_enable=0, los LEDs deberian estar apagados."
            severity error;

        ------------------------------------------------------------
        -- 4) Caso: leds_enable = 1 y seleccionamos varios jugadores
        ------------------------------------------------------------
        leds_enable <= '1';

        -- ---- Jugador 1: apuesta 0 ----
        wait for clk_period;
        player_idx_a <= 1;

        wait for clk_period;
        wait for clk_period;
        val := out_apuestas(1);
        exp := expected_mask(val);

        assert leds = exp
          report "Fallo jugador 2: LEDs no coinciden con la apuesta"
            severity error;

        -- ---- Jugador 2: apuesta 3 ----
        wait for clk_period;
        player_idx_a <= 2;

        wait for clk_period;
        wait for clk_period;
        val := out_apuestas(2);
        exp := expected_mask(val);

        assert leds = exp
           report "Fallo jugador 2: LEDs no coinciden con la apuesta"
            severity error;

        -- ---- Jugador 3: apuesta 7 ----
        wait for clk_period;
        player_idx_a <= 3;

        wait for clk_period;
        wait for clk_period;
        val := out_apuestas(3);
        exp := expected_mask(val);

        assert leds = exp
          report "Fallo jugador 2: LEDs no coinciden con la apuesta"
            severity error;

        -- ---- Jugador 4: apuesta 12 (barra completa) ----
        wait for clk_period;
        player_idx_a <= 4;

        wait for clk_period;
        wait for clk_period;
        val := out_apuestas(4);
        exp := expected_mask(val);

        assert leds = exp
           report "Fallo jugador 2: LEDs no coinciden con la apuesta"
            severity error;

        ------------------------------------------------------------
        -- 5) Cambio dinamico de apuesta (simula que el registro cambia)
        ------------------------------------------------------------
        -- Cambiamos la apuesta del jugador 2 de 3 -> 5 y comprobamos
        wait for clk_period;
        player_idx_a      <= 2;
        out_apuestas(2)   <= 5;

        wait for clk_period;
        wait for clk_period;

        val := 5;
        exp := expected_mask(val);

        assert leds = exp
          report "Fallo jugador 2: LEDs no coinciden con la apuesta"
            severity error;

        ------------------------------------------------------------
        -- 6) Desactivar enable en caliente
        ------------------------------------------------------------
        wait for clk_period;
        leds_enable <= '0';

        wait for clk_period;
        wait for clk_period;
        assert leds = LEDS_OFF
            report "Al desactivar leds_enable, los LEDs deberian apagarse."
            severity error;

        -- Fin de simulacion
        assert false report "Simulacion finalizada (parada intencionada)." severity failure;
    end process;

end architecture;
