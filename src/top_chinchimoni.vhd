library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity chinchimoni_top is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic; -- Reset global (Switch 0)
        
        switches : in  std_logic_vector(3 downto 0); 
        botones  : in  std_logic_vector(3 downto 0); 
        -- botones(1)=Continuar, botones(2)=Reinicio, botones(3)=Confirmar
        
        leds_4   : out std_logic_vector(3 downto 0);
        leds_8   : out std_logic_vector(7 downto 0);
        segments : out std_logic_vector(7 downto 0);
        selector : out std_logic_vector(3 downto 0)
    );
end chinchimoni_top;

architecture Structural of chinchimoni_top is

    -- Señales internas de botones
    signal btn_continuar : std_logic;
    signal btn_reinicio  : std_logic; 
    signal btn_confirmar : std_logic; 

    -- Señales de control FSM
    signal start_config, start_extract, start_bet, start_resolve : std_logic;
    signal done_config, done_extract, done_bet, done_resolve : std_logic;
    signal new_round, game_over_flag : std_logic;

    -- Señales de datos (RegBank)
    signal out_num_players_vec : std_logic_vector(2 downto 0);
    signal out_piedras      : t_player_array;
    signal out_apuestas     : t_player_array;
    signal out_puntos       : t_player_array;
    signal out_rondadejuego : integer range 0 to 100;

    -- Señales de escritura
    signal we_num_players, we_piedras, we_apuesta, we_puntos : std_logic;
    signal in_num_players_vec : std_logic_vector(2 downto 0);
    signal player_idx_p, player_idx_a, winner_idx_round : integer range 0 to MAX_PLAYERS;
    signal in_piedras, in_apuesta, in_puntos_val : integer;

    -- Señales de visualización
    signal disp_code_config, disp_code_extract, disp_code_bet, disp_code_resolve, disp_code_final : std_logic_vector(19 downto 0);

    -- Señales del Timer
    signal timer_start_global : std_logic;
    signal t_start_cfg, t_start_ext, t_start_bet, t_start_res : std_logic;
    signal timeout_5s : std_logic;
    
    -- Señales IA
    signal ai_extract_req, ai_bet_req, ai_primera_ronda : std_logic;
    signal rnd_val : std_logic_vector(3 downto 0);
    signal ai_decision : integer range 0 to MAX_APUESTA;
    signal switches_mux : std_logic_vector(3 downto 0);
    signal confirm_mux  : std_logic;                    

    -- Señales LEDs
    signal leds_enable_bet : std_logic;
    signal leds_12bit      : std_logic_vector(11 downto 0);

begin

    -- 1. BOTONES
    inst_buttons: entity work.buttons
    port map(
        clk => clk, reset => reset,
        in_continuar => botones(1), in_confirmar => botones(3), in_reinicio => botones(2),
        out_continuar => btn_continuar, out_confirmar => btn_confirmar, out_reinicio => btn_reinicio
    );

    -- 2. IA Y RANDOM
    inst_rng: entity work.random_generator
    port map( clk => clk, reset => reset, rnd_out => rnd_val );

    ai_primera_ronda <= '1' when out_rondadejuego = 0 else '0';

    inst_ai: entity work.ai_player
    port map(
        clk => clk, reset => reset,
        extraction_req => ai_extract_req, bet_req => ai_bet_req,
        rnd_val => rnd_val, primera_ronda => ai_primera_ronda,
        piedras_ia => out_piedras(1), decision_out => ai_decision
    );

    -- 3. MUX ENTRADAS (IA vs Humano)
    process(ai_extract_req, ai_bet_req, ai_decision, switches, btn_confirmar)
    begin
        if (ai_extract_req = '1' or ai_bet_req = '1') then
            switches_mux <= std_logic_vector(to_unsigned(ai_decision, 4));
            confirm_mux  <= '1'; 
        else
            switches_mux <= switches;
            confirm_mux  <= btn_confirmar;
        end if;
    end process;

    -- 4. REGBANK
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

    -- 5. FSM PRINCIPAL
    inst_fsm_main: entity work.fsm_main
    port map(
        clk => clk, reset => reset, btn_reinicio => btn_reinicio,
        done_config => done_config, done_extract => done_extract,
        done_bet => done_bet, done_resolve => done_resolve,
        game_over_flag => game_over_flag,
        start_config => start_config, start_extract => start_extract,
        start_bet => start_bet, start_resolve => start_resolve,
        
        new_round => new_round,
        current_phase => open, -- CORRECCIÓN: Conectado a open
        disp_code_config => disp_code_config, disp_code_extract => disp_code_extract,
        disp_code_bet => disp_code_bet, disp_code_resolve => disp_code_resolve,
        disp_code_out => disp_code_final
    );

    -- 6. FSMs ESCLAVAS
    inst_fsm_select: entity work.FSM_SELECT_PLAYERS
    port map(
        clk => clk, reset => reset, start => start_config, done => done_config,
        confirm => btn_confirmar, switches => switches,
        timer_start => t_start_cfg, timeout_5s => timeout_5s,
        we_players_out => we_num_players, players_out => in_num_players_vec,
        disp_code => disp_code_config
    );

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

    inst_fsm_resolve: entity work.fsm_resolve
    port map(
        clk => clk, reset => reset, start => start_resolve, done => done_resolve,
        timer_start => t_start_res, timeout_5s => timeout_5s,
        num_players_vec => out_num_players_vec, piedras => out_piedras,
        apuestas => out_apuestas, puntos => out_puntos,
        we_puntos => we_puntos, in_puntos => in_puntos_val, winner_idx => winner_idx_round,
        end_game => game_over_flag, disp_code => disp_code_resolve
    );

    -- 7. TIMER (Con Skip conectado)
    timer_start_global <= t_start_cfg or t_start_ext or t_start_bet or t_start_res;

    inst_timer: entity work.timer_bloque
    port map(
        clk => clk, reset => reset,
        start => timer_start_global,
        skip => btn_continuar,  -- CONEXIÓN CRÍTICA: Permite saltar pantallas
        timeout => timeout_5s
    );

    -- 8. SALIDAS
    inst_leds_ctrl: entity work.leds_control
    port map(
        clk => clk, reset => reset, leds_enable => leds_enable_bet,
        player_idx_a => player_idx_a, out_apuestas => out_apuestas, leds => leds_12bit
    );

    leds_4 <= leds_12bit(3 downto 0);
    leds_8 <= leds_12bit(11 downto 4);

    inst_segments: entity work.segmentos
    port map(
        clk => clk, reset => reset, disp_code => disp_code_final,
        segments => segments, selector => selector
    );

end Structural;