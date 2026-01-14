library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- FSM: Resolucion de Ronda
-- Este modulo realiza el escrutinio: calcula el total de piedras,
-- busca quien ha acertado, actualiza puntos y decide si hay un ganador final.
entity fsm_resolve is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;

        -- Control de fase (Handshake con FSM principal)
        start           : in  std_logic;
        done            : out std_logic;

        -- Temporizador externo (control de visualizacion de 5s)
        timer_start     : out std_logic;
        timeout_5s      : in  std_logic;

        -- Datos del juego (leidos desde el game_regbank)
        num_players_vec : in  std_logic_vector(2 downto 0);
        piedras         : in  t_player_array;
        apuestas        : in  t_player_array;
        puntos          : in  t_player_array;

        -- Interfaz de escritura para actualizar el Register Bank
        we_puntos       : out std_logic;
        in_puntos       : out integer range 0 to MAX_PLAYERS;
        winner_idx      : out integer range 0 to MAX_PLAYERS;

        -- Indicador de fin de partida (alguien llego a 3 victorias)
        end_game        : out std_logic;

        -- Bus de datos para el display de 7 segmentos
        disp_code       : out std_logic_vector(19 downto 0)
    );
end fsm_resolve;

architecture behavioral of fsm_resolve is

    -- Definicion de los estados de la fase de escrutinio
    type state_type is (
        S_IDLE,         -- Reposo
        S_EXTRACTIONS,  -- Mostrar piedras que tenia cada uno
        S_TOTAL,        -- Mostrar la suma total de piedras
        S_BETS,         -- Mostrar que aposto cada uno
        S_WINNER,       -- Mostrar ganador de la ronda (GA x)
        S_ROUNDS,       -- Mostrar victorias acumuladas
        S_END           -- Fin de la partida (Alguien gano 3 veces)
    );

    signal state : state_type;
    
    -- Señales internas de proceso
    signal round_winner_idx : integer range 0 to MAX_PLAYERS;
    signal game_winner_idx  : integer range 0 to MAX_PLAYERS;
    signal winner_latched   : integer range 0 to MAX_PLAYERS;
    signal score_written    : std_logic;
    
    -- Arrays temporales para calculos en formato unsigned
    type t_u5_array is array (1 to MAX_PLAYERS) of unsigned(4 downto 0);
    signal piedras_u  : t_u5_array;
    signal apuestas_u : t_u5_array;
    signal puntos_u   : t_u5_array;

    signal num_players  : integer range 2 to MAX_PLAYERS;
    signal total_stones : unsigned(4 downto 0);
    signal total_tens   : integer range 0 to 1; 
    signal total_units  : integer range 0 to 9;

    signal done_internal        : std_logic;
    signal timer_start_internal : std_logic;

begin

    -- 1. CONVERSION DE TIPOS Y CALCULOS PREVIOS
    num_players <= to_integer(unsigned(num_players_vec));
   
    gen_type_conversion : for i in 1 to MAX_PLAYERS generate
    begin
        piedras_u(i)  <= to_unsigned(piedras(i), 5);
        apuestas_u(i) <= to_unsigned(apuestas(i), 5);
        puntos_u(i)   <= to_unsigned(puntos(i), 5);
    end generate; 

    -- Sumatorio total de piedras en la mesa
    total_stones <= piedras_u(1) + piedras_u(2) + piedras_u(3) + piedras_u(4);
    
    -- Descomposicion para el display (Ej: 12 -> 1 y 2)
    total_tens   <= to_integer(total_stones) / 10;
    total_units  <= to_integer(total_stones) mod 10;

    -- 2. PROCESO: IDENTIFICAR GANADOR DE RONDA
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                round_winner_idx <= 0;
            else
                round_winner_idx <= 0; -- Por defecto nadie gana
                for i in 1 to MAX_PLAYERS loop
                    if i <= num_players then 
                        if apuestas_u(i) = total_stones then 
                            round_winner_idx <= i; -- El ultimo en la lista que acierte gana
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- 3. PROCESO: IDENTIFICAR SI ALGUIEN HA GANADO EL JUEGO (3 Victorias)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                game_winner_idx <= 0;
            else
                game_winner_idx <= 0;
                for i in 1 to MAX_PLAYERS loop
                    if i <= num_players then
                        if puntos_u(i) = 3 then 
                            game_winner_idx <= i;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- 4. FSM PRINCIPAL DE RESOLUCION
    FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_IDLE;
                done_internal <= '0';
                timer_start_internal <= '0';
            else
                case state is
                    when S_IDLE =>
                        timer_start_internal <= '0';
                        done_internal <= '0';
                        if start = '1' then
                            state <= S_EXTRACTIONS;
                            timer_start_internal <= '1';
                        end if;

                    when S_EXTRACTIONS => -- Muestra piedras (5s)
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_TOTAL;
                            timer_start_internal <= '1';
                        end if;

                    when S_TOTAL =>       -- Muestra suma total (5s)
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_BETS;
                            timer_start_internal <= '1';
                        end if;

                    when S_BETS =>        -- Muestra apuestas (5s)
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_WINNER;
                            timer_start_internal <= '1';
                        end if;

                    when S_WINNER =>      -- Muestra quien acerto (5s)
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_ROUNDS;
                            timer_start_internal <= '1';
                        end if;

                    when S_ROUNDS =>      -- Muestra marcador global (5s)
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            if game_winner_idx = 0 then
                                state <= S_IDLE; -- Sigue el juego
                                done_internal <= '1';
                            else
                                state <= S_END;  -- Alguien gano 3 rondas
                            end if;
                        end if;

                    when S_END =>         -- Bloqueo final (Fin de partida)
                        -- FIX: Si recibimos 'start', es que la FSM Principal ha comenzado 
                        -- una nueva partida y necesita resolver la primera ronda. Salimos del bloqueo.
                        if start = '1' then
                            state <= S_EXTRACTIONS;    -- Volvemos al inicio de la secuencia de resolución
                            timer_start_internal <= '1'; -- Arrancamos el temporizador para mostrar las piedras
                        end if;
                        
                    when others => state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

    -- 4.1 LATCH DEL GANADOR Y BLOQUEO DE ESCRITURA MULTIPLE
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                winner_latched <= 0;
                score_written  <= '0';
            else
                case state is
                    when S_BETS =>
                        if timeout_5s = '1' then
                            winner_latched <= round_winner_idx;
                            score_written  <= '0';
                        end if;
                    when S_WINNER =>
                        if timeout_5s = '1' then
                            score_written <= '1';
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- 5. ASIGNACION DE SALIDAS
    timer_start <= timer_start_internal;
    done        <= done_internal;
    end_game    <= '1' when state = S_END else '0';
    winner_idx  <= winner_latched;

    -- Actualizacion de puntos: Se dispara solo un ciclo cuando acaba S_WINNER
    we_puntos <= '1' when (state = S_WINNER and timeout_5s = '1' and winner_latched /= 0 and score_written = '0') else '0';
    in_puntos <= to_integer(puntos_u(winner_latched)) + 1 when winner_latched /= 0 else 0;

    -- Gestion de mensajes en el Display
    with state select
        disp_code <= std_logic_vector(piedras_u(1))  & std_logic_vector(piedras_u(2))  & std_logic_vector(piedras_u(3))  & std_logic_vector(piedras_u(4))  when S_EXTRACTIONS,
                     CHAR_BLANK & CHAR_BLANK & std_logic_vector(to_unsigned(total_tens, 5)) & std_logic_vector(to_unsigned(total_units, 5))            when S_TOTAL,
                     std_logic_vector(apuestas_u(1)) & std_logic_vector(apuestas_u(2)) & std_logic_vector(apuestas_u(3)) & std_logic_vector(apuestas_u(4)) when S_BETS,
                     CHAR_G & CHAR_A & CHAR_BLANK & std_logic_vector(to_unsigned(winner_latched,5))                                                     when S_WINNER,
                     std_logic_vector(puntos_u(1))   & std_logic_vector(puntos_u(2))   & std_logic_vector(puntos_u(3))   & std_logic_vector(puntos_u(4))   when S_ROUNDS,
                     CHAR_F & CHAR_I & CHAR_n & std_logic_vector(to_unsigned(game_winner_idx,5))                                                      when S_END,
                     CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK                                                                                when others;
    
end architecture behavioral;
