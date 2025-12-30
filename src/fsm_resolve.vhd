library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity fsm_resolve is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;

        -- Control de fase
        start      : in  std_logic;
        done       : out std_logic;

        -- Temporizador externo (5 s)
        timer_start : out std_logic;
        timeout_5s  : in  std_logic;

        -- Datos del juego (desde regbank)
        piedras     : in t_player_array;
        apuestas    : in t_player_array;
        puntos      : in t_player_array;

        -- Interfaz con game_regbank
        we_puntos   : out std_logic;
        in_puntos   : out integer range 0 to MAX_PLAYERS;

        -- Fin de partida
        end_game    : out std_logic;

        -- Display
        disp_code   : out std_logic_vector(19 downto 0)
    );
end fsm_resolve;

architecture behavioral of fsm_resolve is

  
    -- ESTADOS
  
    type state_type is (
        S_IDLE,         -- Esperando start
        S_EXTRACTIONS,  -- Paso 1: piedras por jugador
        S_TOTAL,        -- Paso 2: total de piedras
        S_BETS,         -- Paso 3: apuestas
        S_WINNER,       -- Paso 4: ganador (GAx / GA0)
        S_ROUNDS,       -- Paso 5: rondas ganadas
        S_END           -- Fin de fase
    );

    signal state : state_type;

    
    -- SEÑALES INTERNAS (placeholder)
    
    signal winner_idx   : integer range 0 to MAX_PLAYERS;
    signal total_stones : integer range 0 to MAX_PLAYERS * MAX_PIEDRAS;

begin

      FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= S_IDLE;
                winner_idx  <= 0;
                total_stones <= 0;

            else
                case state is

                    when S_IDLE =>
                        if start = '1' then
                            state <= S_EXTRACTIONS;
                        end if;

                    when S_EXTRACTIONS =>
                        -- lógica futura
                        null;

                    when S_TOTAL =>
                        -- lógica futura
                        null;

                    when S_BETS =>
                        -- lógica futura
                        null;

                    when S_WINNER =>
                        -- lógica futura
                        null;

                    when S_ROUNDS =>
                        -- lógica futura
                        null;

                    when S_END =>
                        state <= S_IDLE;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process FSM_PROCESS;

        -- Temporizador: se activará en los estados que muestren info 5 s
    timer_start <= '0';  -- se ajustará después

    -- Escritura de puntos
    we_puntos <= '0';
    in_puntos <= winner_idx;

    -- Fin de fase
    done <= '1' when state = S_END else '0';

    -- Fin de partida (placeholder)
    end_game <= '0';

    -- Display (placeholder)
    disp_code <= CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK;

end architecture behavioral;
