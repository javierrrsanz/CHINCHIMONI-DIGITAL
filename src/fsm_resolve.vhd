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
    signal total_stones : integer range 0 to (MAX_PLAYERS * MAX_PIEDRAS);

    -- señales de control
    done_internal : std_logic;



begin

   -- Conversión de entradas a unsigned/integer

    num_players <= to_integer(unsigned(num_players_vec)) ;
   
    Type_Change : process(clk)
    begin
        if rising_edge(clk) then
           if reset = '1' then
               for i in 1 to MAX_PLAYERS loop
                   piedras_u(i) <= (others => '0');
                   apuestas_u(i) <= (others => '0');
               end loop;
               total_stones <= 0;
           else
               for i in 1 to num_players loop
                   piedras_u(i) <= to_unsigned(piedras(i), 5);
                   apuestas_u(i) <= to_unsigned(apuestas(i), 5);
                   puntos_u(i) <= to_unsigned(puntos(i), 5);
               end loop; 
               total_stones <= piedras_u(1)+piedras_u(2)+piedras_u(3)+piedras_u(4); 
           end if;  
        end if;
    end process;  

    FSM_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= S_IDLE;
                round_winner_idx  <= 0;
                game_winner_idx  <= 0;
                total_stones <= 0;

            else
                case state is

                    when S_IDLE =>
                        round_winner_idx  <= 0;
                        game_winner_idx  <= 0;
                        if start = '1' then
                            state <= S_EXTRACTIONS;
                        end if;

                    when S_EXTRACTIONS =>
                        if timeout_5s = '1' then
                            state <= S_TOTAL;
                        end if;
                       

                    when S_TOTAL =>
                        if timeout_5s = '1' then
                            state <= S_BETS;
                        end if;

                    when S_BETS =>
                        if timeout_5s = '1' then
                          for i in 1 to num_players loop
                              if apuestas_u(i) = total_stones then
                                  
                                  round_winner_idx <= i;
                              end if;
                          end loop;
                            state <= S_WINNER;
                        end if;

                    when S_WINNER =>
                        if timeout_5s = '1' then
                            state <= S_ROUNDS;

                        end if;

                    when S_ROUNDS =>
                        if timeout_5s = '1' then
                            for i in 1 to num_players loop
                                if puntos_u(i) = 3 then
                                    game_winner_idx <= i;
                                    state <= S_END;
                                end if;
                            end loop;
                            if game_winner_idx = 0 then
                                state <= S_IDLE; -- Nueva ronda
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
