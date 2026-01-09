library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity ai_player is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        extraction_req  : in  std_logic;
        bet_req         : in  std_logic;
        rnd_val         : in  std_logic_vector(3 downto 0);
        primera_ronda   : in  std_logic;
        piedras_ia      : in  integer range 0 to MAX_PIEDRAS;
        decision_out    : out integer range 0 to MAX_APUESTA
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
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                decision_out <= 0; -- CORRECCIÓN: Limpieza en reset
                temp_decision <= 0;
            else
                case state is
                    when IDLE =>
                        if extraction_req = '1' then
                            state <= DECIDE_EXTRACT;
                        elsif bet_req = '1' then
                            state <= DECIDE_BET;
                        end if;

                    when DECIDE_EXTRACT =>
                        -- IA para sacar piedras (0-3)
                        -- Si es ronda 0, no puede sacar 0 piedras (mínimo 1)
                        if primera_ronda = '1' then
                            temp_decision <= 1 + (rnd_int mod 3); -- 1, 2 o 3
                        else
                            temp_decision <= rnd_int mod 4;       -- 0, 1, 2 o 3
                        end if;
                        state <= DONE;

                    when DECIDE_BET =>
                        -- IA para apostar: Piedras propias + Aleatorio
                        -- Evita mentir por defecto (apuesta >= lo que tiene)
                        temp_decision <= piedras_ia + (rnd_int mod (13 - piedras_ia));
                        state <= DONE;

                    when DONE =>
                        decision_out <= temp_decision;
                        -- Esperamos handshake (que la FSM baje la petición)
                        if extraction_req = '0' and bet_req = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;