library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- IMPORTANTE: Usamos el paquete adaptado
use work.pkg_chinchimoni.ALL;

entity FSM_SELECT_PLAYERS is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        
        -- Control (Estandarizado)
        start      : in  std_logic; -- Antes INIT_FASE
        done       : out std_logic; -- Antes FIN_FASE
        
        -- Hardware
        confirm    : in  std_logic; -- Botón limpio (tick)
        switches   : in  std_logic_vector(3 downto 0);
        
        -- Timer
        timer_start: out std_logic;
        timeout_5s : in  std_logic;
        
        -- Salidas
        players_out: out std_logic_vector(2 downto 0); -- A Datapath
        disp_code  : out std_logic_vector(15 downto 0) -- A Display Manager (16 bits)
    );
end FSM_SELECT_PLAYERS;

architecture Behavioral of FSM_SELECT_PLAYERS is
    type state_type is (S_IDLE, S_WAIT_CONFIRM, S_CHECK, S_ERROR, S_SHOW_OK, S_DONE);
    signal state, next_state : state_type;
    
    signal num_jugadores : unsigned(3 downto 0);
    signal players_reg   : std_logic_vector(2 downto 0); -- Registro interno

begin

    num_jugadores <= unsigned(switches);

    -- Proceso Secuencial
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_IDLE;
                players_reg <= (others => '0');
            else
                state <= next_state;
                
                -- Guardamos el número de jugadores si es válido y confirmamos
                if (state = S_CHECK) and (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
                    players_reg <= std_logic_vector(num_jugadores(2 downto 0));
                end if;
            end if;
        end if;
    end process;

    -- Lógica Combinacional
    process (state, start, confirm, num_jugadores, timeout_5s, players_reg)
        -- Variable auxiliar para convertir el número de jugadores a vector display
        variable v_num_disp : std_logic_vector(3 downto 0);
    begin
        -- Valores por defecto
        next_state <= state;
        done <= '0';
        timer_start <= '0';
        players_out <= players_reg;
        
        -- Por defecto display apagado (o lo que queramos)
        disp_code <= CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK; 

        -- Conversión rápida del switch a formato caracter para usar abajo
        v_num_disp := std_logic_vector(num_jugadores);

        case state is
            when S_IDLE =>
                if start = '1' then
                    next_state <= S_WAIT_CONFIRM;
                end if;

            when S_WAIT_CONFIRM =>
                -- Mostrar "JUG X" (Donde X es lo que marcan los switches)
                -- Usamos las constantes adaptadas del PKG:
                -- J (CHAR_J) | U (CHAR_U) | G (CHAR_G) | Num (v_num_disp)
                disp_code <= CHAR_J & CHAR_U & CHAR_G & v_num_disp;
                
                if confirm = '1' then
                    next_state <= S_CHECK;
                end if;

            when S_CHECK =>
                -- Validar rango (2 a 4) usando constantes del PKG
                if (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
                    timer_start <= '1'; -- Iniciamos cuenta de 5s para el mensaje de OK
                    next_state <= S_SHOW_OK;
                else
                    timer_start <= '1'; -- Iniciamos cuenta de 5s para el mensaje de Error
                    next_state <= S_ERROR;
                end if;

            when S_ERROR =>
                -- Mostrar "Err " (Definido en PKG como MSG_ERR)
                disp_code <= MSG_ERR;
                
                if timeout_5s = '1' then
                    next_state <= S_WAIT_CONFIRM;
                end if;

            when S_SHOW_OK =>
                -- Mostrar "JUG C" (Jugadores Confirmados) o "J-XC"
                -- Vamos a poner: J | Num | Guion | C (Confirmado)
                disp_code <= CHAR_J & players_reg(2) & players_reg(1) & players_reg(0) & CHAR_C; 
                -- Oops, eso son bits individuales. Mejor: J | Blank | Num | C
                disp_code <= CHAR_J & CHAR_BLANK & ("0" & players_reg) & CHAR_C;
                
                if timeout_5s = '1' then
                    next_state <= S_DONE;
                end if;

            when S_DONE =>
                done <= '1';
                -- Mantener último mensaje o apagar
                disp_code <= CHAR_J & CHAR_BLANK & ("0" & players_reg) & CHAR_C;
                
                if start = '0' then -- Handshake: Esperar a que Main quite el start
                    next_state <= S_IDLE;
                end if;
        end case;
    end process;

end Behavioral;