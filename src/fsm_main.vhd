library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entidad: fsm_main
-- Descripción: Orquestador del juego. Controla las transiciones entre fases.
entity fsm_main is
    Port (
        clk              : in  std_logic;
        reset            : in  std_logic; -- Reset global (B0)
        
        -- Botón específico para reiniciar tras Game Over (B3)
        btn_reinicio     : in  std_logic; 

        -- Señales de "Trabajo Terminado" (Inputs desde las FSMs esclavas)
        done_config      : in  std_logic; -- Fin FSM_SELECT_PLAYERS
        done_extract     : in  std_logic; -- Fin FSM_EXTRACTION
        done_bet         : in  std_logic; -- Fin FSM_BETTING
        done_resolve     : in  std_logic; -- Fin FSM_RESOLVER

        -- Bandera de victoria (viene del Datapath)
        game_over_flag   : in  std_logic; 

        -- Señales de control (Salidas hacia FSMs esclavas)
        start_config     : out std_logic;
        start_extract    : out std_logic;
        start_bet        : out std_logic;
        start_resolve    : out std_logic;
        
        -- Señal para resetear registros de piedras y apuestas (regbank)
        new_round        : out std_logic

        -- Señal indicador de fase actual 
        current_phase    : out std_logic_vector(1 downto 0);

    );
end fsm_main;

architecture Behavioral of fsm_main is

    -- Nombres de estado coincidentes con las FSMs esclavas
    type t_state is (
        S_RESET,           -- Estado inicial de limpieza
        S_SELECT_PLAYERS,  -- Fase 1: Elegir jugadores
        S_EXTRACTION,      -- Fase 2: Sacar piedras
        S_BET,             -- Fase 3: Apostar
        S_RESOLVE,         -- Fase 4: Resolver ronda
    );
    signal current_state, next_state : t_state;

    signal new_round_reg : std_logic;

begin

    -- 1. Registro de Estado (Síncrono)
    process(clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                current_state <= S_RESET;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- 2. Lógica de Transición y Salidas
    process(current_state, done_config, done_extract, done_bet, done_resolve, btn_reinicio)
    begin
        -- Valores por defecto (evita latches)
        next_state <= current_state;
        
        start_config     <= '0';
        start_extract    <= '0';
        start_bet        <= '0';
        start_resolve    <= '0';
        new_round_reg    <= '0';

        case current_state is
            
            -- Estado Inicial: Limpieza
            when S_RESET =>
                next_state <= S_SELECT_PLAYERS;

            -- FASE 1: Selección de Jugadores
            when S_SELECT_PLAYERS =>
                start_resolve <= '0';
                start_config <= '1';
                if done_config = '1' then
                    next_state <= S_EXTRACTION;
                end if;

            -- FASE 2: Extracción de Piedras
            when S_EXTRACTION =>
                start_config <= '0';
                start_extract <= '1';
                if done_extract = '1' then
                    next_state <= S_BET;
                end if;

            -- FASE 3: Apuestas
            when S_BET =>
                start_extract <= '0';
                start_bet <= '1';
                if done_bet = '1' then
                    next_state <= S_RESOLVE;
                end if;

            -- FASE 4: Resolución de la Ronda
            when S_RESOLVE =>
                start_bet <= '0';
                start_resolve <= '1';
                if done_resolve = '1' then
                    next_state <= S_EXTRACTION;
                    new_round_reg <= '1'; -- Señal de nueva ronda
                elsif btn_reinicio = '1' then
                    next_state <= S_RESET; -- Reiniciar partida en cualquier momento
                end if;

        end case;
    end process;

    -- 3. Señal de Nueva Ronda
    new_round <= new_round_reg when current_state = S_RESOLVE else '0';

    -- 4. Salida de Fase Actual
    with current_state select
        current_phase <= "00" when S_SELECT_PLAYERS,
                         "01" when S_EXTRACTION,
                         "10" when S_BET,
                         "11" when S_RESOLVE,
                         "00" when others;
                         
end Behavioral;