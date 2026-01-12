library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- ============================================================================
-- ENTIDAD: CHINCHIMONI_TOP
-- DESCRIPCIÓN: Módulo raíz que instancia y conecta todos los componentes 
--              del juego (Control, Datapath, IA y Periféricos).
-- ============================================================================
entity chinchimoni_top is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic; -- Reset global (Switch 0)
        
        switches : in  std_logic_vector(3 downto 0); 
        botones  : in  std_logic_vector(3 downto 1); 
        -- botones(1)=Continuar/Skip, botones(2)=Reinicio Partida, botones(3)=Confirmar
        
        leds_4   : out std_logic_vector(3 downto 0); -- LEDs de estado/apuestas
        leds_8   : out std_logic_vector(7 downto 0); -- LEDs de estado/apuestas
        segments : out std_logic_vector(7 downto 0); -- Salida a 7 segmentos
        selector : out std_logic_vector(3 downto 0)  -- Selector de ánodo
    );
end chinchimoni_top;

architecture Structural of chinchimoni_top is

    -- ------------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ------------------------------------------------------------------------
    -- Botones con antirrebote/sincronizados
    signal btn_continuar, btn_reinicio, btn_confirmar : std_logic; 

    -- Handshake FSM Main <-> Esclavas
    signal start_config, start_extract, start_bet, start_resolve : std_logic;
    signal done_config, done_extract, done_bet, done_resolve    : std_logic;
    signal new_round, game_over_flag : std_logic;

    -- Datos del Banco de Registros (Datapath)
    signal out_num_players_vec : std_logic_vector(2 downto 0);
    signal out_piedras, out_apuestas, out_puntos : t_player_array;
    signal out_rondadejuego : integer range 0 to 100;

    -- Señales de escritura al Banco de Registros
    signal we_num_players, we_piedras, we_apuesta, we_puntos : std_logic;
    signal in_num_players_vec : std_logic_vector(2 downto 0);
    signal player_idx_p, player_idx_a : integer range 0 to MAX_PLAYERS;
    signal winner_idx_round           : integer range 1 to MAX_PLAYERS;
    signal in_piedras                 : integer range 0 to MAX_PIEDRAS;
    signal in_apuesta                 : integer range 0 to MAX_APUESTA;
    signal in_puntos_val              : integer range 0 to MAX_PLAYERS;

    -- Buses de visualización (Displays)
    signal disp_code_config, disp_code_extract, disp_code_bet : std_logic_vector(19 downto 0);
    signal disp_code_resolve, disp_code_final                 : std_logic_vector(19 downto 0);

    -- Timer Global
    signal timer_start_global : std_logic;
    signal t_start_cfg, t_start_ext, t_start_bet, t_start_res : std_logic;
    signal timeout_5s : std_logic;
    
    -- Interfaz Inteligencia Artificial (IA)
    signal ai_extract_req, ai_bet_req : std_logic;
    signal rnd_val : std_logic_vector(3 downto 0);
    signal ai_decision_out  : integer range 0 to MAX_APUESTA;
    signal ai_decision_done : std_logic;
    signal switches_mux     : std_logic_vector(3 downto 0);
    signal confirm_mux      : std_logic;                    

    -- Señales LEDs
    signal leds_enable_bet : std_logic;
    signal leds_12bit      : std_logic_vector(11 downto 0);

begin

    -- ------------------------------------------------------------------------
    -- 1. ENTRADAS Y PERIFÉRICOS DE CONTROL
    -- ------------------------------------------------------------------------
    inst_buttons: entity work.buttons
    port map(
        clk => clk, reset => reset,
        in_continuar => botones(1), in_reinicio => botones(2), in_confirmar => botones(3),
        out_continuar => btn_continuar, out_reinicio => btn_reinicio, out_confirmar => btn_confirmar
    );

    -- ------------------------------------------------------------------------
    -- 2. SUBSISTEMA DE INTELIGENCIA ARTIFICIAL (IA)
    -- ------------------------------------------------------------------------
    inst_rng: entity work.random_generator
    port map( clk => clk, reset => reset, rnd_out => rnd_val );

    inst_ai: entity work.ai_player
    port map(
        clk => clk, reset => reset,
        extraction_req => ai_extract_req, bet_req => ai_bet_req,
        rnd_val => rnd_val, rondadejuego => out_rondadejuego,
        piedras_ia => out_piedras(1), decision_out => ai_decision_out,
        decision_done => ai_decision_done, num_players => out_num_players_vec
    );

    -- Mux de Entrada: Elige entre los switches físicos o la decisión de la IA
    inst_input_mux: entity work.input_mux
    port map (
        clk => clk, reset => reset,
        ai_extract_req => ai_extract_req, ai_bet_req => ai_bet_req,
        ai_decision => ai_decision_out, decision_done => ai_decision_done,
        switches_human => switches, confirm_human => btn_confirmar,
        switches_mux => switches_mux, confirm_mux => confirm_mux
    );

    -- ------------------------------------------------------------------------
    -- 3. GESTIÓN DE DATOS (REGBANK)
    -- ------------------------------------------------------------------------
    inst_regbank: entity work.game_regbank
    port map(
        clk => clk, reset => reset,
        we_num_players => we_num_players, in_num_players => in_num_players_vec,
        we_piedras => we_piedras, player_idx_p => player_idx_p, in_piedras => in_piedras,
        we_apuesta => we_apuesta, player_idx_a => player_idx_a, in_apuesta => in_apuesta,
        we_puntos => we_puntos, winner_idx => winner_idx_round, in_puntos => in_puntos_val,
        new_round => new_round,
        out_num_players_vec => out_num_players_vec, out_piedras => out_piedras,
        out_apuestas => out_apuestas, out_puntos => out_puntos, out_rondadejuego => out_rondadejuego
    );

    -- ------------------------------------------------------------------------
    -- 4. CONTROLADOR MAESTRO (FSM MAIN)
    -- ------------------------------------------------------------------------
    inst_fsm_main: entity work.fsm_main
    port map(
        clk => clk, reset => reset, btn_reinicio => btn_reinicio,
        done_config => done_config, done_extract => done_extract,
        done_bet => done_bet, done_resolve => done_resolve,
        game_over_flag => game_over_flag,
        start_config => start_config, start_extract => start_extract,
        start_bet => start_bet, start_resolve => start_resolve,
        new_round => new_round, current_phase => open, 
        disp_code_config => disp_code_config, disp_code_extract => disp_code_extract,
        disp_code_bet => disp_code_bet, disp_code_resolve => disp_code_resolve,
        disp_code_out => disp_code_final
    );

    -- ------------------------------------------------------------------------
    -- 5. FSMs ESCLAVAS (Lógica de cada fase)
    -- ------------------------------------------------------------------------
    
    -- Fase 1: Configuración de Jugadores
    inst_fsm_select: entity work.FSM_SELECT_PLAYERS
    port map(
        clk => clk, reset => reset, start => start_config, done => done_config,
        confirm => btn_confirmar, switches => switches,
        timer_start => t_start_cfg, timeout_5s => timeout_5s,
        we_players_out => we_num_players, players_out => in_num_players_vec,
        disp_code => disp_code_config
    );

    -- Fase 2: Extracción de piedras
    inst_fsm_extract: entity work.FSM_EXTRACTION
    port map(
        clk => clk, reset => reset, start => start_extract, done => done_extract,
        confirm => confirm_mux, switches => switches_mux,
        ai_extraction_request => ai_extract_req,
        timer_start => t_start_ext, timeout_5s => timeout_5s,
        num_players => to_integer(unsigned(out_num_players_vec)),
        rondadejuego => out_rondadejuego,
        we_piedras => we_piedras, player_idx_p => player_idx_p, in_piedras => in_piedras,
        disp_code => disp_code_extract
    );

    -- Fase 3: Apuestas
    inst_fsm_bet: entity work.fsm_bet
    port map(
        clk => clk, reset => reset, start => start_bet, done => done_bet,
        confirm => confirm_mux, switches => switches_mux,
        ai_request_bet => ai_bet_req,
        timer_start => t_start_bet, timeout_5s => timeout_5s,
        rondadejuego => out_rondadejuego, out_num_players_vec => out_num_players_vec,
        apuestas_reg => out_apuestas, piedras_reg => out_piedras,
        we_apuesta => we_apuesta, player_idx_a => player_idx_a, in_apuesta => in_apuesta,
        leds_enable => leds_enable_bet, disp_code => disp_code_bet
    );

    -- Fase 4: Resolución de la ronda
    inst_fsm_resolve: entity work.fsm_resolve
    port map(
        clk => clk, reset => reset, start => start_resolve, done => done_resolve,
        timer_start => t_start_res, timeout_5s => timeout_5s,
        num_players_vec => out_num_players_vec, piedras => out_piedras,
        apuestas => out_apuestas, puntos => out_puntos,
        we_puntos => we_puntos, in_puntos => in_puntos_val, winner_idx => winner_idx_round,
        end_game => game_over_flag, disp_code => disp_code_resolve
    );

    -- ------------------------------------------------------------------------
    -- 6. TEMPORIZACIÓN Y VISUALIZACIÓN
    -- ------------------------------------------------------------------------
    
    -- El timer se activa si CUALQUIERA de las FSMs esclavas lo solicita
    timer_start_global <= t_start_cfg or t_start_ext or t_start_bet or t_start_res;

    inst_timer: entity work.timer_bloque
    port map(
        clk => clk, reset => reset,
        start => timer_start_global,
        skip => btn_continuar,  -- Permite al usuario saltar los 5s de espera
        timeout => timeout_5s
    );

    -- Control de LEDs (Muestra apuestas durante la fase 3)
    inst_leds_ctrl: entity work.leds_control
    port map(
        clk => clk, reset => reset, leds_enable => leds_enable_bet,
        player_idx_a => player_idx_a, out_apuestas => out_apuestas, leds => leds_12bit
    );

    leds_4 <= leds_12bit(11 downto 8);
    leds_8 <= leds_12bit(7 downto 0);

    -- Driver de los Displays de 7 segmentos
    inst_segments: entity work.segmentos
    port map(
        clk => clk, reset => reset, disp_code => disp_code_final,
        segments => segments, selector => selector
    );

end Structural;