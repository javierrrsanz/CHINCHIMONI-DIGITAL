library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity ai_player is
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;

        -- Interfaces con FSMs
        extraction_req      : in  std_logic; -- Viene de fsm_extraction
        bet_req             : in  std_logic; -- Viene de fsm_bet
        
        -- Datos del generador aleatorio
        rnd_val             : in  std_logic_vector(3 downto 0); -- Viene de random_generator

        -- Información del juego para decidir
        primera_ronda       : in  std_logic;
        piedras_ia          : in  integer range 0 to MAX_PIEDRAS;
       

        -- Salidas de decisión
        decision_out        : out integer range 0 to MAX_APUESTA;
        
    );
end ai_player;

architecture Behavioral of ai_player is
    type state_type is (IDLE, DECIDE_EXTRACT, DECIDE_BET, DONE);
    signal state : state_type;
    
    signal temp_decision : integer range 0 to MAX_APUESTA;
    signal rnd_int       : integer;

begin

    rnd_int <= to_integer(unsigned(rnd_val));

    process(clk)
        
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                state <= IDLE;
                
            else
                case state is
                    when IDLE =>
                        
                        if extraction_req = '1' then
                            state <= DECIDE_EXTRACT;
                        elsif bet_req = '1' then
                            state <= DECIDE_BET;
                        end if;

                    when DECIDE_EXTRACT =>
                        -- Limitamos el valor de 4 bits (0-15) a 0-3 usando mod 4
                        if primera_ronda = '1' then
                        temp_decision <= 1+ rnd_int mod 3;
                        else
                        temp_decision <= rnd_int mod 4;
                        end if;
                        state <= DONE;

                    when DECIDE_BET =>
                        -- Decisión inicial de apuesta (0 a 12)
                        temp_decision <= piedras_ia + rnd_int mod (13-piedras_ia);
                        state <= DONE;

                    

                    when DONE =>
                        decision_out <= temp_decision;
                        
                        -- Esperamos a que la FSM baje el request
                        if extraction_req = '0' and bet_req = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;