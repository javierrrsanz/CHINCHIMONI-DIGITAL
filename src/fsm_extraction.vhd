library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- FSM: Extraccion de Piedras
-- Gestiona el turno de cada jugador para que elija sus piedras (0-3).
-- Incluye la logica para solicitar la jugada de la IA cuando es el turno del Jugador 1.
entity FSM_EXTRACTION is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- Control de fase (Handshake con FSM Main)
        start         : in  std_logic;
        done          : out std_logic;

        -- Entradas de control
        confirm       : in  std_logic; -- Boton de confirmar (ya filtrado)
        switches      : in  std_logic_vector(3 downto 0); -- Valor de piedras

        -- Interfaz con el modulo de IA
        ai_extraction_request : out std_logic; -- Indica a la IA que debe "pensar"

        -- Temporizador externo
        timer_start   : out std_logic;
        timeout_5s    : in  std_logic;

        -- Estado global del juego
        num_players   : in integer range 1 to MAX_PLAYERS;  
        rondadejuego  : in integer range 0 to 100;   

        -- Interfaz de escritura al Register Bank
        we_piedras    : out std_logic;
        player_idx_p  : out integer range 1 to MAX_PLAYERS;
        in_piedras    : out integer range 0 to MAX_PIEDRAS;

        -- Bus de datos para el display (Mensajes tipo "Ch 1")
        disp_code     : out std_logic_vector(19 downto 0)
    );
end FSM_EXTRACTION;

architecture behavioral of FSM_EXTRACTION is

    type state_type is (
        S_IDLE,     -- Reposo
        S_WAIT,     -- Espera de confirmacion del jugador actual
        S_CHECK,    -- Validacion de la jugada
        S_ERROR,    -- Mensaje de error (Seleccion no valida)
        S_OK,       -- Registro de jugada exitoso
        S_DONE      -- Fin de la fase de extraccion
    );

    signal state            : state_type;
    signal player_idx       : integer range 1 to MAX_PLAYERS;
    signal piedras_value    : integer range 0 to MAX_PIEDRAS;
    signal val_int          : integer range 0 to 15;
    signal player_idx_u     : unsigned(4 downto 0); 
    signal ai_request_reg   : std_logic;
    signal ai_request_flag  : std_logic;

begin

    -- Conversion inmediata del valor de los switches para comparaciones
    val_int <= to_integer(unsigned(switches));

    FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state           <= S_IDLE;
                player_idx      <= 1;
                piedras_value   <= 0;
                ai_request_reg  <= '0';
                ai_request_flag <= '0';
            else
                case state is

                    when S_IDLE =>
                        player_idx      <= 1;
                        ai_request_flag <= '0';
                        if start = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_WAIT =>
                        -- Lógica de IA: Si es el Jugador 1, pedimos valor a la IA_PLAYER
                        if player_idx = 1 and ai_request_flag = '0' then
                            ai_request_reg  <= '1';
                            ai_request_flag <= '1';
                     
                        end if;

                        if confirm = '1' then
                            state <= S_CHECK;
                        end if;

                    when S_CHECK =>
                        ai_request_reg  <= '0';
                        ai_request_flag <= '0'; 

                        -- VALIDACION DE REGLAS:
                        -- 1. El valor debe estar entre 0 y 3 (MAX_PIEDRAS)
                        -- 2. Regla especial: En la ronda 0, no se pueden sacar 0 piedras
                        if (val_int >= 0) and (val_int <= MAX_PIEDRAS) and
                           not (rondadejuego = 0 and val_int = 0) then
                            piedras_value <= val_int;
                            state         <= S_OK;
                        else
                            state         <= S_ERROR;
                        end if;

                    when S_ERROR =>
                        if timeout_5s = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_OK =>
                        if timeout_5s = '1' then
                            -- ¿Han jugado ya todos?
                            if player_idx >= num_players then
                                state <= S_DONE;
                            else
                                player_idx <= player_idx + 1;
                                state      <= S_WAIT;
                            end if;
                        end if;

                    when S_DONE =>
                        state <= S_IDLE;
                        
                    when others => state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

    -- =============================================================
    -- LOGICA COMBINACIONAL DE SALIDAS
    -- =============================================================
    ai_extraction_request <= ai_request_reg;
    timer_start           <= '1' when state = S_CHECK else '0';
    done                  <= '1' when state = S_DONE  else '0';
    
    -- Escritura en el banco de registros: habilitada mientras se muestra "OK" (S_OK)
    we_piedras   <= '1' when (state = S_OK and timeout_5s = '0') else '0';
    player_idx_p <= player_idx;
    in_piedras   <= piedras_value;

    player_idx_u <= to_unsigned(player_idx, 5);

    -- Control del Display: Muestra "Ch X" (Ch = Chino/Piedras, X = Jugador)
    -- Añade un caracter al final: 'E' para Error, 'C' para Confirmado (OK)
    with state select
        disp_code <= CHAR_C & CHAR_h & std_logic_vector(player_idx_u) & CHAR_BLANK when S_WAIT,
                     CHAR_C & CHAR_h & std_logic_vector(player_idx_u) & CHAR_E     when S_ERROR,
                     CHAR_C & CHAR_h & std_logic_vector(player_idx_u) & CHAR_C     when S_OK,
                     CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK             when others;

end behavioral;