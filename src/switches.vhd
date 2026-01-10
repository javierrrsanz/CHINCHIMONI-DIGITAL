library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- Modulo Multiplexor de Entrada
-- Este bloque selecciona quien tiene el control del juego: el humano o la IA.
-- Si la IA esta calculando una jugada, sus valores pasan al sistema.
-- Si no, el sistema lee directamente los switches y botones de la placa.
entity input_mux is
    Port (
        clk            : in  std_logic; -- Reloj de 125 MHz
        reset          : in  std_logic; -- Reset del sistema

        -- Interfaz con el modulo de la IA
        ai_extract_req : in  std_logic; -- IA esta eligiendo monedas
        ai_bet_req     : in  std_logic; -- IA esta calculando apuesta
        ai_decision    : in  integer range 0 to MAX_APUESTA; -- Valor decidido por la IA
        decision_done  : in  std_logic; -- Flag de que la IA ha terminado

        -- Interfaz con los perifericos humanos (switches y botones filtrados)
        switches_human : in  std_logic_vector(3 downto 0);
        confirm_human  : in  std_logic;

        -- Salidas finales multiplexadas hacia la FSM principal
        switches_mux   : out std_logic_vector(3 downto 0);
        confirm_mux    : out std_logic
    );
end input_mux;

architecture Behavioral of input_mux is
begin

    -- Proceso de seleccion de datos sincronizado con el reloj
    process(clk)
    begin
        if rising_edge(clk) then
            -- Reset: limpiamos las salidas por seguridad
            if reset = '1' then
                switches_mux <= (others => '0');
                confirm_mux  <= '0';
            else
                -- PRIORIDAD: CONTROL DE LA IA
                -- Si cualquiera de las señales de peticion de la IA esta activa,
                -- el multiplexor ignora los controles fisicos de la placa.
                if (ai_extract_req = '1' or ai_bet_req = '1') then
                    
                    -- Convertimos el entero de la IA a vector para que la FSM lo entienda
                    switches_mux <= std_logic_vector(to_unsigned(ai_decision, 4));

                    -- La confirmacion es automatica: solo se activa cuando la IA termina
                    if decision_done = '1' then
                        confirm_mux <= '1';
                    else
                        confirm_mux <= '0';
                    end if;

                -- CONTROL HUMANO
                -- Si la IA no esta trabajando, el control vuelve al jugador
                else
                    switches_mux <= switches_human; -- Leemos los interruptores (SW0-SW3)
                    confirm_mux  <= confirm_human;  -- Leemos el boton de confirmar
                end if;
            end if;
        end if;
    end process;

end Behavioral;