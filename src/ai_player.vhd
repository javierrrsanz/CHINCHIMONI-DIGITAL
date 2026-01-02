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
        apuestas_actuales   : in  t_player_array; -- Para no repetir

        -- Salidas de decisión
        decision_out        : out integer range 0 to MAX_APUESTA;
        decision_ready      : out std_logic
    );
end ai_player;

architecture Behavioral of ai_player is
    type state_type is (IDLE, DECIDE_EXTRACT, DECIDE_BET, VALIDATE_BET, DONE);
    signal state : state_type;
    
    signal temp_decision : integer range 0 to MAX_APUESTA;
    signal rnd_int       : integer;

begin

    rnd_int <= to_integer(unsigned(rnd_val));

    process(clk)
        variable v_valida : boolean;
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                state <= IDLE;
                decision_ready <= '0';
            else
                case state is
                    when IDLE =>
                        decision_ready <= '0';
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
                        state <= VALIDATE_BET;

                    when VALIDATE_BET =>
                        v_valida := true;
                        
                        -- Regla 1: No repetir apuesta
                        for i in 1 to MAX_PLAYERS loop
                            if apuestas_actuales(i) = temp_decision then
                                v_valida := false;
                            end if;
                        end loop;

                        -- Regla 2: En primera ronda no mentir (apuesta <= piedras_propias)
                        --if primera_ronda = '1' and temp_decision > piedras_ia then
                            --v_valida := false;
                        --end if;

                        if v_valida then
                            state <= DONE;
                        else
                            -- Si no es válida, "re-lanzamos" sumando 1 (o esperando otro ciclo de rnd)
                            if temp_decision >= 12 then
                                temp_decision <= piedras_ia;
                            else
                                temp_decision <= temp_decision + 1;
                            end if;
                        end if;

                    when DONE =>
                        decision_out <= temp_decision;
                        decision_ready <= '1';
                        -- Esperamos a que la FSM baje el request
                        if extraction_req = '0' and bet_req = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;