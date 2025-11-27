
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_fsm is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        botones    : in  std_logic_vector(2 downto 0); -- continuar, confirmar, reinicio
        switches   : in  std_logic_vector(3 downto 0); -- valor introducido
        mode       : in  std_logic_vector(1 downto 0);
        tiempo_ok  : in  std_logic;                    -- señal del timer (5s)
        random_val : in  std_logic_vector(3 downto 0); -- valor aleatorio para AI
        ai_val     : in  std_logic_vector(3 downto 0); -- apuesta del jugador máquina
        estado     : out std_logic_vector(3 downto 0); -- estado actual (para displays)
        leds       : out std_logic_vector(7 downto 0)  -- puntos acumulados
    );
end control_fsm;

architecture Behavioral of control_fsm is

    -- Definición de estados
    type state_type is (
        INIT_SELECT_PLAYERS,
        EXTRACTION_P1, EXTRACTION_P2, EXTRACTION_P3, EXTRACTION_P4,
        BETTING_P1, BETTING_P2, BETTING_P3, BETTING_P4,
        RESOLVE_ROUND,
        UPDATE_SCORE,
        GAME_OVER
    );
    signal current_state, next_state : state_type;

begin

    -- Proceso síncrono para actualizar estado
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= INIT_SELECT_PLAYERS;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- Proceso combinacional para transiciones
    process(current_state, botones, tiempo_ok)
    begin
        next_state <= current_state; -- por defecto
        case current_state is

            when INIT_SELECT_PLAYERS =>
                if botones(1) = '1' then -- confirmar
                    next_state <= EXTRACTION_P1;
                end if;

            when EXTRACTION_P1 =>
                if botones(1) = '1' then
                    next_state <= EXTRACTION_P2;
                end if;

            when EXTRACTION_P2 =>
                if botones(1) = '1' then
                    next_state <= BETTING_P1;
                end if;

            when BETTING_P1 =>
                if botones(1) = '1' then
                    next_state <= BETTING_P2;
                end if;

            when BETTING_P2 =>
                if botones(1) = '1' then
                    next_state <= RESOLVE_ROUND;
                end if;

            when RESOLVE_ROUND =>
                if tiempo_ok = '1' then
                    next_state <= UPDATE_SCORE;
                end if;

            when UPDATE_SCORE =>
                -- Si alguien llegó a 3 puntos -> GAME_OVER
                next_state <= EXTRACTION_P1; -- o GAME_OVER según condición

            when GAME_OVER =>
                if botones(2) = '1' then -- reinicio
                    next_state <= INIT_SELECT_PLAYERS;
                end if;

            when others =>
                next_state <= INIT_SELECT_PLAYERS;

        end case;
    end process;

    -- Aquí iría la lógica de salida (estado para displays, LEDs)
    estado <= std_logic_vector(to_unsigned(state_type'pos(current_state), 4));

end Behavioral;
