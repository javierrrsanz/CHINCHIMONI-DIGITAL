library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity tb_fsm_bet is
end tb_fsm_bet;

architecture tb of tb_fsm_bet is

    constant CLK_PERIOD : time := 10 ns;

    -- =====================
    -- Señales DUT
    -- =====================
    signal clk                 : std_logic := '0';
    signal reset               : std_logic := '0';
    signal start               : std_logic := '0';
    signal done                : std_logic;
    signal confirm             : std_logic := '0';
    signal switches            : std_logic_vector(3 downto 0) := (others => '0');
    
    signal ai_request_bet      : std_logic;

    signal timer_start         : std_logic;
    signal timeout_5s          : std_logic := '0';
    signal rondadejuego        : integer range 0 to 100 := 0;
    signal out_num_players_vec : std_logic_vector(2 downto 0) := "010"; -- default 2
    signal apuestas_reg        : t_player_array := (others => 0);
    signal piedras_reg         : t_player_array := (others => 0);
    signal we_apuesta          : std_logic;
    signal player_idx_a        : integer range 1 to MAX_PLAYERS;
    signal in_apuesta          : integer range 0 to MAX_APUESTA;
    signal leds_enable         : std_logic;
    signal disp_code           : std_logic_vector(19 downto 0);

begin

    -- =====================
    -- Reloj
    -- =====================
    clk <= not clk after CLK_PERIOD/2;

    -- =====================
    -- DUT
    -- =====================
    DUT : entity work.fsm_bet
        port map (
            clk                 => clk,
            reset               => reset,
            start               => start,
            done                => done,
            confirm             => confirm,
            switches            => switches,
            ai_request_bet      => ai_request_bet,
            timer_start         => timer_start,
            timeout_5s          => timeout_5s,
            rondadejuego        => rondadejuego,
            out_num_players_vec => out_num_players_vec,
            apuestas_reg        => apuestas_reg,
            piedras_reg         => piedras_reg,
            we_apuesta          => we_apuesta,
            player_idx_a        => player_idx_a,
            in_apuesta          => in_apuesta,
            leds_enable         => leds_enable,
            disp_code           => disp_code
        );

    -- =====================
    -- STIMULUS
    -- =====================
    stimulus : process

        -- Helper para apostar
        procedure do_bet(constant bet_value : integer) is
        begin
            switches <= std_logic_vector(to_unsigned(bet_value, 4));
            wait for CLK_PERIOD;
            confirm <= '1';
            wait for CLK_PERIOD;
            confirm <= '0';
        end procedure;

        procedure pulse_timeout is
        begin
            timeout_5s <= '1';
            wait for CLK_PERIOD;
            timeout_5s <= '0';
        end procedure;

        procedure expect_error(constant msg : string) is
        begin
            wait until rising_edge(clk);
            -- Verificamos si el display muestra 'E' (CHAR_E) en el dígito de la derecha (bits 4..0)
            assert disp_code(4 downto 0) = CHAR_E
                report "❌ ERROR esperado NO detectado: " & msg
                severity error;
            report "✔️ ERROR detectado correctamente: " & msg;
        end procedure;

        procedure expect_ok(constant msg : string) is
        begin
            wait until rising_edge(clk);
            assert we_apuesta = '1'
                report "❌ Apuesta válida rechazada: " & msg
                severity error;
            report "✔️ Apuesta válida aceptada: " & msg;
        end procedure;

    begin
        ------------------------------------------------------------
        -- RESET
        ------------------------------------------------------------
        report "===== RESET =====";
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';

        ------------------------------------------------------------
        -- TEST 1: NO MENTIR EN RONDA 0
        ------------------------------------------------------------
        report "===== TEST 1: NO MENTIR EN RONDA 0 =====";
        out_num_players_vec <= "010"; -- 2 jugadores
        rondadejuego <= 0; -- Ronda 0: Aplica regla de no mentir
        
        -- Simulamos piedras: J1 tiene 1 piedra, J2 tiene 2
        piedras_reg <= (others => 0);
        piedras_reg(1) <= 1;
        piedras_reg(2) <= 2;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- CASO A: INTENTO DE MENTIRA (Apostar MENOS de lo que tengo)
        -- Tengo 1 piedra, apuesto 0. Esto debe fallar.
        do_bet(0);
        expect_error("Jugador 1 intenta mentir (apuesta 0 teniendo 1)");
        pulse_timeout; -- Simulamos que pasa el tiempo de error y vuelve a pedir

        -- CASO B: APUESTA VÁLIDA (Igual o mayor a mis piedras)
        -- Tengo 1 piedra, apuesto 1. Esto debe funcionar.
        do_bet(1);
        expect_ok("Jugador 1 apuesta legal (1 teniendo 1)");
        
        -- Actualizamos el registro de apuestas "manualmente" para que el siguiente test lo vea
        apuestas_reg(1) <= 1; 
        pulse_timeout; -- Pasa al siguiente jugador

        ------------------------------------------------------------
        -- TEST 2: NO REPETIR APUESTAS
        ------------------------------------------------------------
        report "===== TEST 2: NO REPETIR APUESTAS =====";
        -- Estamos en la misma ronda, turno del siguiente jugador.
        -- J1 ya apostó '1'.
        
        -- J2 intenta apostar '1' también. Debe fallar.
        do_bet(1);
        expect_error("Jugador 2 intenta repetir apuesta 1");
        pulse_timeout;

        -- J2 apuesta '3'. Debe funcionar.
        do_bet(3);
        expect_ok("Jugador 2 apuesta distinta (3)");
        
        report "===== FIN DE TESTS =====";
        wait;
    end process;

end architecture tb;