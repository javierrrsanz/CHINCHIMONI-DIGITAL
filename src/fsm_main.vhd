library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- FSM Main: El Orquestador del Sistema
-- Controla el flujo principal del juego, activando cada fase en orden
-- y gestionando el multiplexado de los mensajes para el display.
entity fsm_main is
    Port (
        clk               : in  std_logic;
        reset             : in  std_logic; -- Reset global
        
        -- Entrada de control de usuario
        btn_reinicio      : in  std_logic; -- Boton para volver a empezar (B3)

        -- Señales de "Handshake" desde las FSMs esclavas
        done_config       : in  std_logic; -- Termino de elegir jugadores
        done_extract      : in  std_logic; -- Termino de sacar piedras
        done_bet          : in  std_logic; -- Termino de apostar
        done_resolve      : in  std_logic; -- Termino de resolver ronda

        -- Estado del juego
        game_over_flag    : in  std_logic; -- '1' si alguien llego a 3 victorias

        -- Señales de activacion (Hacia FSMs esclavas)
        start_config      : out std_logic;
        start_extract     : out std_logic;
        start_bet         : out std_logic;
        start_resolve     : out std_logic;
        
        -- Control del Banco de Registros
        new_round         : out std_logic; -- Pulso para limpiar ronda previa
        current_phase     : out std_logic_vector(1 downto 0); -- Codigo de fase para LEDs/Debug

        -- Entradas de datos de visualizacion de cada fase
        disp_code_config  : in  std_logic_vector(19 downto 0);
        disp_code_extract : in  std_logic_vector(19 downto 0);
        disp_code_bet     : in  std_logic_vector(19 downto 0);
        disp_code_resolve : in  std_logic_vector(19 downto 0);     

        -- Salida final del bus de datos hacia el decodificador de 7 segmentos
        disp_code_out     : out std_logic_vector(19 downto 0)
    );
end fsm_main;

architecture Behavioral of fsm_main is

    -- Definicion de los estados maestros
    type t_state is (
        S_RESET,           -- Estado de inicializacion
        S_SELECT_PLAYERS,  -- Fase 1: Configuracion inicial
        S_EXTRACTION,      -- Fase 2: Manos cerradas (piedras)
        S_BET,             -- Fase 3: Apuestas
        S_RESOLVE          -- Fase 4: Escrutinio y marcador
    );

    signal current_state, next_state : t_state;
    signal new_round_reg : std_logic;

begin

    -- 1. REGISTRO DE ESTADO (Logica Secuencial)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= S_RESET;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- 2. LOGICA DE TRANSICION Y CONTROL (Logica Combinacional)
    process(current_state, done_config, done_extract, done_bet, done_resolve, btn_reinicio, game_over_flag)
    begin
        -- Valores por defecto para evitar la creacion de latches indeseados
        next_state    <= current_state;
        start_config  <= '0';
        start_extract <= '0';
        start_bet     <= '0';
        start_resolve <= '0';
        new_round_reg <= '0';

        case current_state is
            
            when S_RESET =>
                next_state <= S_SELECT_PLAYERS;

            -- FASE 1: Se activa la FSM de seleccion de jugadores
            when S_SELECT_PLAYERS =>
                start_config <= '1';
                if done_config = '1' then
                    next_state <= S_EXTRACTION;
                end if;

            -- FASE 2: Los jugadores eligen sus piedras
            when S_EXTRACTION =>
                start_extract <= '1';
                if done_extract = '1' then
                    next_state <= S_BET;
                end if;

            -- FASE 3: Se realizan las apuestas (incluyendo IA)
            when S_BET =>
                start_bet <= '1';
                if done_bet = '1' then
                    next_state <= S_RESOLVE;
                end if;

            -- FASE 4: Se muestra el resultado
            when S_RESOLVE =>
                start_resolve <= '1';
                if done_resolve = '1' then
                    -- Si nadie ha ganado la partida (3 rondas), volvemos a jugar
                    if game_over_flag = '0' then
                        next_state    <= S_EXTRACTION;
                        new_round_reg <= '1'; -- Pulso para limpiar regbank
                    else
                        -- Si hay ganador final, nos quedamos en este estado
                        -- mostrando el mensaje de FIN hasta que se pulse reinicio
                        next_state <= S_RESOLVE; 
                    end if;
                end if;
                
                -- El boton de reinicio nos permite volver a S_RESET en cualquier momento
                if btn_reinicio = '1' then
                    next_state <= S_RESET;
                end if;

            when others =>
                next_state <= S_RESET;
        end case;
    end process;

    -- 3. LOGICA DE SALIDA: Sincronizacion de señales de control
    new_round <= new_round_reg when current_state = S_RESOLVE else '0';

    -- Codificador de fase para uso externo (LEDS de estado)
    with current_state select
        current_phase <= "00" when S_SELECT_PLAYERS,
                         "01" when S_EXTRACTION,
                         "10" when S_BET,
                         "11" when S_RESOLVE,
                         "00" when others;

    -- 4. MULTIPLEXOR DE MENSAJES PARA EL DISPLAY
    -- Seleccionamos que informacion se envia a los 7 segmentos segun la fase
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                disp_code_out <= (others => '1'); -- Mensaje vacio en reset
            else
                case current_state is
                    when S_SELECT_PLAYERS => disp_code_out <= disp_code_config;
                    when S_EXTRACTION    => disp_code_out <= disp_code_extract;
                    when S_BET           => disp_code_out <= disp_code_bet;
                    when S_RESOLVE       => disp_code_out <= disp_code_resolve;
                    when others          => disp_code_out <= (others => '1');
                end case;
            end if;
        end if;
    end process;
                   
end Behavioral;