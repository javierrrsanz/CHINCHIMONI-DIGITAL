library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;


entity fsm_bet is
    Port (
        clk                : in  std_logic;
        reset              : in  std_logic;

        -- Control de fase
        start              : in  std_logic;
        done               : out std_logic;

        -- Entradas jugador
        confirm            : in  std_logic;
        switches           : in  std_logic_vector(3 downto 0);

        -- Request de AI_PLAYER para apostar
        ai_request_bet     : out  std_logic;

        -- Temporizador externo (pulso)
        timer_start        : out std_logic;
        timeout_5s         : in  std_logic;

        -- Estado de juego
        rondadejuego       : in integer range 0 to 100;

        -- Num jugadores desde regbank (vector 3 bits)
        out_num_players_vec: in  std_logic_vector(2 downto 0);

        -- Registros de apuestas (para no repetir)
        apuestas_reg       : in  t_player_array;

        -- Registros de piedras (para "no mentir" en primera ronda)
        piedras_reg        : in  t_player_array;

        -- Interfaz con game_regbank
        we_apuesta         : out std_logic;
        player_idx_a       : out integer range 1 to MAX_PLAYERS;
        in_apuesta         : out integer range 0 to MAX_APUESTA;

        -- Leds

        leds_enable       : out std_logic;

        -- Display
        disp_code          : out std_logic_vector(19 downto 0)
    );
end fsm_bet;

architecture behavioral of fsm_bet is


-- Estados
  type state_type is (
        S_IDLE,       -- Esperando start
        S_WAIT,       -- Mostrar "bX" y esperar confirm
        S_CHECK,      -- Valida switches, arranca timer y (si válido) escribe
        S_ERROR,      -- Mostrar 'E' 5 s
        S_OK,         -- Mostrar 'C' 5 s
        S_DONE        -- Fase terminada
    );

  signal state           : state_type;

  -- Senales internas
  signal player_idx      : integer range 1 to MAX_PLAYERS;
  signal apuesta_value   : integer range 0 to MAX_APUESTA;
  signal val_int         : integer range 0 to MAX_APUESTA;
  signal num_players     : integer range 1 to MAX_PLAYERS;
  signal player_idx_u    : unsigned(4 downto 0);

  signal repeated_bet    : std_logic;

  signal auxiliar        : integer range 1 to MAX_PLAYERS;
  signal offset   : integer range 0 to MAX_PLAYERS-1;

  signal ai_request_reg : std_logic;
  signal ai_request_flag : std_logic;


begin

  -- switches a entero
  val_int <= to_integer(unsigned(switches));

  -- Num jugadores desde vector
  num_players <= to_integer(unsigned(out_num_players_vec)); -- Antes había un +1 aquí, revisar

  -- Señal auxiliar de jugador real
  offset   <= rondadejuego mod num_players;
  auxiliar <= ((player_idx - 1 + offset) mod num_players) + 1; -- Ajuste de índice circular

  Repeated_bet_PROCESS : process(clk)
  begin
    if rising_edge(clk) then
        repeated_bet <= '0';
        for i in 1 to MAX_PLAYERS loop
            if (i < player_idx) and (apuestas_reg(((i - 1 + (rondadejuego mod num_players)) mod num_players) + 1) = val_int) then  -- Para que evalue la apuesta de los jugadores anteriores en el orden circular
                repeated_bet <= '1';
            end if;
        end loop;
    end if;
  end process Repeated_bet_PROCESS;

  FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state          <= S_IDLE;
                player_idx     <= 1;
                apuesta_value  <= 0;
                ai_request_reg <= '0';
                ai_request_flag <= '0';

            else
                case state is

                    when S_IDLE =>
                        player_idx     <= 1;
                        apuesta_value  <= 0;
                        ai_request_flag <= '0';
                        if start = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_WAIT =>
                        if auxiliar = 1 and ai_request_flag = '0' then
                            ai_request_reg <= '1';
                            ai_request_flag <= '1';
                        else
                            ai_request_reg <= '0';
                        end if;

                        if confirm = '1' then
                            state <= S_CHECK;
                        end if;

                    when S_CHECK =>
                        ai_request_flag <= '0';
                        -- Validar apuesta
                        if (val_int > MAX_APUESTA) or
                           (val_int = 0) or
                           (rondadejuego = 0 and val_int > piedras_reg(player_idx)) or
                           (repeated_bet = '1') then
                            -- Apuesta inválida
                            state <= S_ERROR;
                        else
                            -- Apuesta válida
                            apuesta_value <= val_int;
                            state <= S_OK;
                        end if;

                    when S_ERROR =>
                        if timeout_5s = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_OK =>                    
                        if timeout_5s = '1' then
                            -- Preparar siguiente jugador
                            if player_idx < num_players then
                                player_idx <= player_idx + 1;
                                state <= S_WAIT;
                            else
                                state <= S_DONE;
                            end if;
                        end if;

                    when S_DONE =>
                            state <= S_IDLE;
                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process FSM_PROCESS;

    -- Logica combinacional salidas

    ai_request_bet <= ai_request_reg;

    timer_start <= '1' when state = S_CHECK else '0';

    we_apuesta <= '1' when (state = S_OK and timeout_5s = '0') else '0';
    leds_enable <= '1' when state = S_OK else '0';

    player_idx_a <= auxiliar; -- Ajuste de índice circular
    player_idx_u <= to_unsigned(auxiliar,5);

    in_apuesta <= apuesta_value;

    done <= '1' when state = S_DONE else '0';

    with state select
    disp_code <=
       CHAR_A & CHAR_P & std_logic_vector(player_idx_u) & CHAR_BLANK when S_WAIT,
       CHAR_A & CHAR_P & std_logic_vector(player_idx_u) & CHAR_E     when S_ERROR,
       CHAR_A & CHAR_P & std_logic_vector(player_idx_u) & CHAR_C     when S_OK,
       CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK             when others;



end architecture behavioral;