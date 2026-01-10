library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- Modulo que gestiona la inteligencia del Jugador 1 (la placa)
-- Decide de forma automatica cuantas piedras sacar y que apuesta realizar
entity ai_player is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        extraction_req  : in  std_logic;  -- Señal para pedir que la IA elija sus piedras
        bet_req         : in  std_logic;  -- Señal para pedir que la IA haga su apuesta
        rnd_val         : in  std_logic_vector(3 downto 0); -- Valor aleatorio del contador
        rondadejuego    : in  integer range 0 to 100;       -- Contador de la ronda actual
        num_players     : in  std_logic_vector(2 downto 0); -- Jugadores activos en la partida
        piedras_ia      : in  integer range 0 to MAX_PIEDRAS; -- Piedras que hemos sacado nosotros
        decision_out    : out integer range 0 to MAX_APUESTA; -- Resultado enviado a la FSM principal
        decision_done   : out std_logic   -- Indica que la decision ya es valida
    );
end ai_player;

architecture Behavioral of ai_player is
    -- Estados para controlar el flujo de pensamiento de la maquina
    type state_type is (IDLE, DECIDE_EXTRACT, DECIDE_BET, DONE);
    signal state : state_type;
    
    signal temp_decision : integer range 0 to MAX_APUESTA;
    signal rnd_int       : integer range 0 to 15;
    signal apuesta_maxima : integer range 0 to MAX_APUESTA;
begin

    -- Pasamos el valor aleatorio a entero para operar con el
    rnd_int <= to_integer(unsigned(rnd_val));
    
    -- Calculamos el limite de la mesa segun el numero de jugadores (jugadores * 3)
    -- He añadido el punto y coma que faltaba para que compile
    apuesta_maxima <= to_integer(unsigned(num_players)) * 3;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state         <= IDLE;
                decision_out  <= 0;
                temp_decision <= 0;
                decision_done <= '0';
            else
                case state is
                    -- Esperando a que el controlador principal nos de paso
                    when IDLE =>
                        decision_done <= '0';
                        if extraction_req = '1' then
                            state <= DECIDE_EXTRACT;
                        elsif bet_req = '1' then
                            state <= DECIDE_BET;
                        end if;

                    -- Fase de extraccion de piedras
                    when DECIDE_EXTRACT =>
                        -- Segun las reglas, en la ronda inicial no podemos sacar 0
                        if rondadejuego = 0 then
                            -- Sacamos obligatoriamente 1, 2 o 3 piedras
                            temp_decision <= 1 + (rnd_int mod 3);
                        else
                            -- En rondas normales podemos sacar de 0 a 3
                            temp_decision <= rnd_int mod 4;
                        end if;
                        state <= DONE;

                    -- Fase de apuesta
                    when DECIDE_BET =>
                        -- La IA apuesta sus piedras mas un extra aleatorio
                        -- No puede mentir: la apuesta siempre sera mayor o igual a sus piedras
                        -- El rango se ajusta dinamicamente con apuesta_maxima
                        temp_decision <= piedras_ia + (rnd_int mod (apuesta_maxima - piedras_ia + 1));
                        state <= DONE;

                    -- Confirmamos la decision y esperamos al handshake
                    when DONE =>
                        decision_out <= temp_decision;
                        decision_done <= '1';
                        
                        -- Volvemos a reposo cuando el controlador principal baja la peticion
                        if extraction_req = '0' and bet_req = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;