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
        num_players_vec : in std_logic_vector(2 downto 0);
        piedras     : in t_player_array;
        apuestas    : in t_player_array;
        puntos      : in t_player_array;

        -- Interfaz con game_regbank
        we_puntos   : out std_logic;
        in_puntos   : out integer range 0 to MAX_PLAYERS;
        winner_idx   : out integer range 0 to MAX_PLAYERS;

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
    
    signal round_winner_idx   : integer range 0 to MAX_PLAYERS;
    signal game_winner_idx   : integer range 0 to MAX_PLAYERS;
    
    -- Señales del Register Bank
    type t_u5_array is array (1 to MAX_PLAYERS)of unsigned(4 downto 0);
    signal piedras_u : t_u5_array;
    signal apuestas_u : t_u5_array;
    signal puntos_u : t_u5_array;

    signal num_players : integer range 2 to MAX_PLAYERS;
    signal total_stones : unsigned(4 downto 0);

    signal total_tens  : integer range 0 to 1; -- Para mostrar en display
    signal total_units : integer range 0 to 9;


    -- señales de control
    signal done_internal : std_logic;
    signal timer_start_internal : std_logic;



begin

   -- Conversión de entradas a unsigned/integer

    num_players <= to_integer(unsigned(num_players_vec)) ;
   
    gen_type_change : for i in 1 to MAX_PLAYERS generate
    begin
        piedras_u(i)  <= to_unsigned(piedras(i), 5);
        apuestas_u(i) <= to_unsigned(apuestas(i), 5);
        puntos_u(i)   <= to_unsigned(puntos(i), 5);
    end generate; 

    total_stones <= piedras_u(1) + piedras_u(2) + piedras_u(3) + piedras_u(4);
    total_tens  <= to_integer(total_stones) / 10;
    total_units <= to_integer(total_stones) mod 10;


    Round_Winner : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                round_winner_idx <= 0;
            else
                round_winner_idx <= 0;
                for i in 1 to num_players loop
                    if apuestas_u(i) = total_stones then -- Asi ahora se queda como ganador el último que acierte
                        round_winner_idx <= i;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    Game_Winner : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                game_winner_idx <= 0;
            else
                for i in 1 to num_players loop
                    if puntos_u(i) = to_unsigned(3, 5) then 
                        game_winner_idx <= i;
                    end if;
                end loop;
            end if;
        end if;
    end process;


    FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= S_IDLE;
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

                    when S_EXTRACTIONS =>
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_TOTAL;
                            timer_start_internal <= '1';
                        end if;
                       

                    when S_TOTAL =>
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_BETS;
                            timer_start_internal <= '1';
                        end if;

                    when S_BETS =>
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_WINNER;
                            timer_start_internal <= '1';
                        end if;

                    when S_WINNER =>
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            state <= S_ROUNDS;
                            timer_start_internal <= '1';
                        end if;

                    when S_ROUNDS =>
                        timer_start_internal <= '0';
                        if timeout_5s = '1' then
                            if game_winner_idx = 0 then
                                state <= S_IDLE; -- Nueva ronda
                                done_internal <= '1';
                            else
                                state <= S_END; -- Fin de fase
                            end if;

                        end if;

                    when S_END =>
                        null;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process FSM_PROCESS;

    -- Lógica de salidas
    
    timer_start <= timer_start_internal;

    -- Escritura de puntos
    we_puntos <= '1' when (state = S_WINNER and timeout_5s = '1' and round_winner_idx /= 0) else '0';
    in_puntos <= to_integer(unsigned(puntos_u(round_winner_idx))) + 1 when (state = S_WINNER and timeout_5s = '1'and round_winner_idx /= 0) else 0;
    winner_idx <= round_winner_idx;

    done <= done_internal;

    -- Fin de partida (placeholder)
    end_game <= '1' when state = S_END else '0';

    -- Display (placeholder)
    with state select
        disp_code <= std_logic_vector(piedras_u(1)) & std_logic_vector(piedras_u(2)) & std_logic_vector(piedras_u(3)) & std_logic_vector(piedras_u(4))      when S_EXTRACTIONS,
                     CHAR_BLANK & CHAR_BLANK  & std_logic_vector(to_unsigned(total_tens, 5)) & std_logic_vector(to_unsigned(total_units, 5))                when S_TOTAL,
                     std_logic_vector(apuestas_u(1)) & std_logic_vector(apuestas_u(2)) & std_logic_vector(apuestas_u(3)) & std_logic_vector(apuestas_u(4))  when S_BETS,
                     CHAR_G & CHAR_A & CHAR_BLANK & std_logic_vector(to_unsigned(round_winner_idx,5))                                                       when S_WINNER,
                     std_logic_vector(puntos_u(1)) & std_logic_vector(puntos_u(2)) & std_logic_vector(puntos_u(3)) & std_logic_vector(puntos_u(4))          when S_ROUNDS,
                     CHAR_F & CHAR_I & CHAR_n & std_logic_vector(to_unsigned(round_winner_idx,5))                                                           when S_END,
                     CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK                                                                                      when others;
    
end architecture behavioral;
