library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity tb_fsm_resolve is
end tb_fsm_resolve;

architecture tb of tb_fsm_resolve is

    constant CLK_PERIOD : time := 10 ns;

    -- =====================
    -- Señales DUT
    -- =====================
    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';

    signal start           : std_logic := '0';
    signal done            : std_logic;

    signal timer_start     : std_logic;
    signal timeout_5s      : std_logic := '0';

    signal num_players_vec : std_logic_vector(2 downto 0) := "010"; -- default 2

    signal piedras         : t_player_array := (others => 0);
    signal apuestas        : t_player_array := (others => 0);
    signal puntos          : t_player_array := (others => 0);

    signal we_puntos       : std_logic;
    signal in_puntos       : integer range 0 to MAX_PLAYERS;
    signal winner_idx      : integer range 0 to MAX_PLAYERS;

    signal end_game        : std_logic;
    signal disp_code       : std_logic_vector(19 downto 0);

begin

    -- =====================
    -- Reloj
    -- =====================
    clk <= not clk after CLK_PERIOD/2;

    -- =====================
    -- DUT
    -- =====================
    DUT : entity work.fsm_resolve
        port map (
            clk            => clk,
            reset          => reset,
            start          => start,
            done           => done,
            timer_start    => timer_start,
            timeout_5s     => timeout_5s,
            num_players_vec=> num_players_vec,
            piedras        => piedras,
            apuestas       => apuestas,
            puntos         => puntos,
            we_puntos      => we_puntos,
            in_puntos      => in_puntos,
            winner_idx     => winner_idx,
            end_game       => end_game,
            disp_code      => disp_code
        );

    -- =====================
    -- STIMULUS
    -- =====================
    stimulus : process

        -- ---------------------------------------------------------
        -- PROCEDIMIENTOS
        -- ---------------------------------------------------------
        procedure pulse_start is
        begin
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
        end procedure;

        procedure pulse_timeout is
        begin
            timeout_5s <= '1';
            wait for CLK_PERIOD;
            timeout_5s <= '0';
        end procedure;

        -- Espera al siguiente flanco y comprueba un pulso de timer_start
        procedure expect_timer_start_pulse(constant msg : string) is
        begin
            wait until rising_edge(clk);
            assert timer_start = '1'
                report "?? timer_start NO se activó al entrar en pantalla: " & msg
                severity error;

            -- En el siguiente ciclo debería volver a 0
            wait until rising_edge(clk);
            assert timer_start = '0'
                report "?? timer_start no fue pulso de 1 ciclo en: " & msg
                severity error;

            report "?? timer_start OK (pulso) en: " & msg;
        end procedure;

        -- Comprueba display 4x5 bits
        procedure expect_disp(
            constant d3 : std_logic_vector(4 downto 0);
            constant d2 : std_logic_vector(4 downto 0);
            constant d1 : std_logic_vector(4 downto 0);
            constant d0 : std_logic_vector(4 downto 0);
            constant msg : string
        ) is
        begin
            wait until rising_edge(clk);
            assert disp_code = d3 & d2 & d1 & d0
                report "?? Display incorrecto: " & msg
                severity error;
            report "?? Display OK: " & msg;
        end procedure;

        -- Comprueba we_puntos y winner_idx
        procedure expect_round_winner(
            constant exp_winner : integer;
            constant exp_we     : std_logic;
            constant msg        : string
        ) is
        begin
            -- esperamos un ciclo para que Round_Winner proc + FSM salidas se estabilicen
            wait until rising_edge(clk);

            assert winner_idx = exp_winner
                report "?? winner_idx incorrecto en " & msg &
                       " (esperado=" & integer'image(exp_winner) &
                       ", leido=" & integer'image(winner_idx) & ")"
                severity error;

            assert we_puntos = exp_we
                report "?? we_puntos incorrecto en " & msg &
                       " (esperado=" & std_logic'image(exp_we) &
                       ", leido=" & std_logic'image(we_puntos) & ")"
                severity error;

            report "?? winner_idx / we_puntos OK en: " & msg;
        end procedure;

        -- Calcula display digits para TOTAL: "__TU"
        function to_u5(constant v : integer) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(v, 5));
        end function;

        -- Helper: prepara arrays "solo jugadores activos"
        procedure clear_all is
        begin
            piedras  <= (others => 0);
            apuestas <= (others => 0);
            puntos   <= (others => 0);
        end procedure;

        -- Simula una resolución completa (pasa por todas las pantallas)
        procedure run_full_resolution_cycle(constant msg : string) is
        begin
            report "---- Ciclo completo: " & msg;

            -- Entrar en EXTRACTIONS
            pulse_start;
            expect_timer_start_pulse("EXTRACTIONS");

            -- EXTRACTIONS (espera timeout para pasar a TOTAL)
            pulse_timeout;
            expect_timer_start_pulse("TOTAL");

            -- TOTAL -> BETS
            pulse_timeout;
            expect_timer_start_pulse("BETS");

            -- BETS -> WINNER
            pulse_timeout;
            expect_timer_start_pulse("WINNER");

            -- WINNER -> ROUNDS
            pulse_timeout;
            expect_timer_start_pulse("ROUNDS");

            -- ROUNDS -> (IDLE o END)
            pulse_timeout;
        end procedure;

    begin
        ------------------------------------------------------------
        -- RESET
        ------------------------------------------------------------
        report "===== RESET =====";
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';
        wait for 2*CLK_PERIOD;

        ------------------------------------------------------------
        -- TEST 0: secuencia básica de displays (2 jugadores) + sin ganador
        ------------------------------------------------------------
        report "===== TEST 0: 2 jugadores, sin ganador =====";
        clear_all;

        num_players_vec <= "010"; -- 2

        -- piedras: jugador1=1, jugador2=2 => total=3
        piedras(1) <= 1; piedras(2) <= 2;

        -- apuestas ninguna acierta total=3
        apuestas(1) <= 0; apuestas(2) <= 1;

        -- puntos iniciales
        puntos(1) <= 0; puntos(2) <= 0;

        -- EXTRACTIONS display: p1 p2 p3 p4 (p3,p4 = 0)
        pulse_start;
        expect_timer_start_pulse("EXTRACTIONS");
        expect_disp(to_u5(1), to_u5(2), to_u5(0), to_u5(0), "EXTRACTIONS muestra piedras");

        -- EXTRACTIONS -> TOTAL
        pulse_timeout;
        expect_timer_start_pulse("TOTAL");
        -- TOTAL display: "__TU" con tens/units de 3 => 0 y 3
        expect_disp(CHAR_BLANK, CHAR_BLANK, to_u5(0), to_u5(3), "TOTAL muestra 03");

        -- TOTAL -> BETS
        pulse_timeout;
        expect_timer_start_pulse("BETS");
        expect_disp(to_u5(0), to_u5(1), to_u5(0), to_u5(0), "BETS muestra apuestas");

        -- BETS -> WINNER
        pulse_timeout;
        expect_timer_start_pulse("WINNER");

        -- En WINNER no debería haber ganador (GA0) y no escribe puntos
        -- OJO: tu display pone "GA _ idx" donde idx es de 5 bits.
        expect_disp(CHAR_G, CHAR_A, CHAR_BLANK, to_u5(0), "WINNER muestra GA 0");
        expect_round_winner(0, '0', "WINNER sin ganador");

        -- WINNER -> ROUNDS
        pulse_timeout;
        expect_timer_start_pulse("ROUNDS");
        expect_disp(to_u5(0), to_u5(0), to_u5(0), to_u5(0), "ROUNDS muestra puntos");

        -- ROUNDS -> IDLE (game_winner_idx=0) y done=1 un ciclo
        pulse_timeout;
        wait until rising_edge(clk);
        assert done = '1'
            report "?? done no se activó al volver a IDLE (sin ganador final)"
            severity error;
        report "?? done OK al volver a IDLE (nueva ronda)";

        ------------------------------------------------------------
        -- TEST 1: 2 jugadores, ganador único (incrementa puntos)
        ------------------------------------------------------------
        report "===== TEST 1: 2 jugadores, ganador único =====";
        clear_all;
        num_players_vec <= "010";

        -- total=4
        piedras(1) <= 1; piedras(2) <= 3;

        -- jugador2 acierta
        apuestas(1) <= 0; apuestas(2) <= 4;

        -- puntos previos: p2=1
        puntos(1) <= 0; puntos(2) <= 1;

        -- ciclo completo hasta WINNER y comprobaciones clave
        run_full_resolution_cycle("2 jugadores, p2 acierta total=4");

        -- Tras el último timeout (ROUNDS->...), estamos ya en transición:
        -- Comprobamos que en el ciclo de salida de WINNER (cuando timeout_5s=1)
        -- se generó we_puntos=1 y winner_idx=2.
        -- Para hacerlo robusto, repetimos el patrón desde BETS->WINNER->... con checks locales.
        -- (Reejecutamos de forma controlada)

        -- Volvemos a IDLE ya (por done) en el ciclo anterior, así que relanzamos:
        pulse_start;
        expect_timer_start_pulse("EXTRACTIONS");
        pulse_timeout; expect_timer_start_pulse("TOTAL");
        pulse_timeout; expect_timer_start_pulse("BETS");
        pulse_timeout; expect_timer_start_pulse("WINNER");

        -- En estado WINNER (antes de timeout) winner_idx debe ser 2, pero we_puntos aún 0 (tu lógica usa timeout_5s)
        expect_disp(CHAR_G, CHAR_A, CHAR_BLANK, to_u5(2), "WINNER muestra GA 2 (ganador p2)");
        expect_round_winner(2, '0', "WINNER antes del timeout");

        -- Ahora damos timeout_5s=1 para disparar we_puntos
        pulse_timeout;
        wait until rising_edge(clk);
        assert we_puntos = '1'
            report "?? we_puntos no se activó en WINNER con timeout y ganador"
            severity error;

        assert in_puntos = (1 + 1)  -- puntos(2)=1 => +1
            report "?? in_puntos incorrecto (esperado 2) en ganador p2"
            severity error;

        report "?? Escritura de puntos OK: we_puntos=1 e in_puntos incrementado";

        ------------------------------------------------------------
        -- TEST 2: varios aciertan -> gana el último (por tu for loop)
        ------------------------------------------------------------
        report "===== TEST 2: 3 jugadores, varios aciertan (gana último) =====";
        clear_all;
        num_players_vec <= "011"; -- 3

        -- total=6 (2+2+2)
        piedras(1) <= 2; piedras(2) <= 2; piedras(3) <= 2;

        -- p1 y p3 aciertan (apuesta=6). Según tu proceso, al iterar i=1..3,
        -- el ganador final será i=3 (el último que cumple).
        apuestas(1) <= 6; apuestas(2) <= 0; apuestas(3) <= 6;

        puntos(1) <= 0; puntos(2) <= 0; puntos(3) <= 2;

        pulse_start;
        expect_timer_start_pulse("EXTRACTIONS");
        pulse_timeout; expect_timer_start_pulse("TOTAL");
        pulse_timeout; expect_timer_start_pulse("BETS");
        pulse_timeout; expect_timer_start_pulse("WINNER");

        expect_disp(CHAR_G, CHAR_A, CHAR_BLANK, to_u5(3), "WINNER GA 3 (último acierta)");
        expect_round_winner(3, '0', "WINNER antes timeout (multiacierto)");

        pulse_timeout;
        wait until rising_edge(clk);
        assert we_puntos = '1'
            report "?? we_puntos no se activó con multiacierto (debería escribir al último)"
            severity error;
        assert in_puntos = (2 + 1) -- p3=2
            report "?? in_puntos incorrecto para multiacierto (esperado 3)"
            severity error;
        report "?? Multiacierto OK: gana el último (p3) y suma punto";

        ------------------------------------------------------------
        -- TEST 3: fin de partida (alguien con 3 puntos) -> END
        ------------------------------------------------------------
        report "===== TEST 3: fin de partida (END) =====";
        clear_all;
        num_players_vec <= "100"; -- 4

        -- Da igual el total/apuestas para end_game: tu Game_Winner mira puntos=3
        puntos(1) <= 0; puntos(2) <= 3; puntos(3) <= 1; puntos(4) <= 0;

        -- Ejecutamos un ciclo y comprobamos que tras ROUNDS, va a END
        -- (Con tu FSM: en S_ROUNDS, si game_winner_idx /= 0 => S_END)
        piedras(1) <= 0; piedras(2) <= 0; piedras(3) <= 0; piedras(4) <= 0;
        apuestas(1) <= 0; apuestas(2) <= 0; apuestas(3) <= 0; apuestas(4) <= 0;

        pulse_start;
        expect_timer_start_pulse("EXTRACTIONS");
        pulse_timeout; expect_timer_start_pulse("TOTAL");
        pulse_timeout; expect_timer_start_pulse("BETS");
        pulse_timeout; expect_timer_start_pulse("WINNER");
        pulse_timeout; expect_timer_start_pulse("ROUNDS");

        -- En ROUNDS mostramos puntos
        expect_disp(to_u5(0), to_u5(3), to_u5(1), to_u5(0), "ROUNDS muestra puntos (p2=3)");

        -- ROUNDS -> END
        pulse_timeout;
        wait until rising_edge(clk);
        assert end_game = '1'
            report "?? end_game no se activó en estado END"
            severity error;
        report "?? END OK: end_game=1";

        -- Display en END: "FIn "
        expect_disp(CHAR_F, CHAR_I, CHAR_n, CHAR_BLANK, "END muestra Fin");

        report "===== TODOS LOS TESTS COMPLETADOS CORRECTAMENTE =====";
        wait;
    end process;

end architecture tb;
