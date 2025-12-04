library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity FSM_EXTRACTION is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        -- Control de fase
        start        : in  std_logic;
        done         : out std_logic;

        -- Entradas del jugador (humanos + CPU)
        confirm      : in  std_logic;
        switches     : in  std_logic_vector(3 downto 0);

        -- Temporizador externo (5 s)
        timer_start  : out std_logic;
        timeout_5s   : in  std_logic;

        -- Información del juego
        num_players  : in integer range 1 to MAX_PLAYERS;  -- Hay que chequear como llega esta señal
        first_round  : in std_logic;   -- '1' si es la primera ronda (no se permite 0)

        -- Interfaz con el banco de registros (game_regbank)
        we_piedras   : out std_logic;
        player_idx_p : out integer range 1 to MAX_PLAYERS;
        in_piedras   : out integer range 0 to MAX_PIEDRAS;

        -- Display de 4 dígitos
        disp_code    : out std_logic_vector(15 downto 0)
    );
end FSM_EXTRACTION;

architecture behavioral of FSM_EXTRACTION is

-- Estados
  type state_type is (
        S_IDLE,     -- Esperando start
        S_WAIT,     -- Mostrar "chX" y esperar confirm
        S_CHECK,    -- Valida switches, arranca timer y (si válido) escribe
        S_ERROR,    -- Mostrar 'E' 5 s
        S_OK,       -- Mostrar 'C' 5 s
        S_DONE      -- Fase terminada
    );

  signal state           : state_type;

-- Signal registros
  signal player_idx      : integer range 1 to MAX_PLAYERS;
  signal piedras_value   : integer range 0 to MAX_PIEDRAS;
  signal val_int         : integer range 0 to MAX_PIEDRAS;

  signal player_idx_u    : unsigned(3 downto 0); -- Para visualizarlo con displays

begin

  val_int <= to_integer(unsigned(switches));

  FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state          <= S_IDLE;
                player_idx     <= 1;
                piedras_value  <= 0;

            else
                case state is

                    when S_IDLE =>
                        player_idx     <= 1;
                        if start = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_WAIT =>
                        -- Esperamos a que llegue un pulso de confirmación
                        if confirm = '1' then
                            state <= S_CHECK;
                        end if;

                    when S_CHECK =>
                        if (val_int >= 0) and (val_int <= MAX_PIEDRAS) and
                           not (first_round = '1' and val_int = 0) then
                            -- Selección válida
                            piedras_value  <= val_int;
                            state          <= S_OK;
                        else
                            -- Selección inválida
                            state          <= S_ERROR;
                        end if;

                    when S_ERROR =>
                        if timeout_5s = '1' then
                            state <= S_WAIT;
                        end if;

                    when S_OK =>
                        if timeout_5s = '1' then
                            if player_idx >= num_players then
                                -- Último jugador: fase terminada
                                state <= S_DONE;
                            else
                                -- Siguiente jugador
                                player_idx <= player_idx + 1;
                                state      <= S_WAIT;
                            end if;
                        end if;

                    when S_DONE =>
                        
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

-- Logica Combinacional Salidas

  we_piedras <= '1' when state = S_OK else '0';
  
  timer_start <= '1' when state = S_CHECK else '0';

  player_idx_u <= to_unsigned(player_idx,4);
  player_idx_p <= player_idx;

  in_piedras <= piedras_value;

  done <= '1' when state = S_DONE else '0';

  with state select
    disp_code <= CHAR_C & CHAR_H & std_logic_vector(player_idx_u) & CHAR_BLANK when S_WAIT,
                 CHAR_C & CHAR_H & std_logic_vector(player_idx_u) & CHAR_E     when S_ERROR,
                 CHAR_C & CHAR_H & std_logic_vector(player_idx_u) & CHAR_C     when S_OK,
                 CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK when others;


end behavioral;