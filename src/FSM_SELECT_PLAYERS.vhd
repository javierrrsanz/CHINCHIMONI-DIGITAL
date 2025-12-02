library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity FSM_SELECT_PLAYERS is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Control
        start       : in  std_logic;
        done        : out std_logic;
        
        -- Hardware
        confirm     : in  std_logic; -- Botón (pulso)
        switches    : in  std_logic_vector(3 downto 0);
        
        -- Timer
        timer_start : out std_logic;
        timeout_5s  : in  std_logic;
        
        -- Salidas
        players_out : out std_logic_vector(2 downto 0);
        disp_code   : out std_logic_vector(15 downto 0)
    );
end FSM_SELECT_PLAYERS;

architecture Behavioral of FSM_SELECT_PLAYERS is

    type t_state is (S_IDLE, S_WAIT_CONFIRM, S_CHECK, S_ERROR, S_SHOW_OK, S_DONE);
    signal current_state, next_state : t_state;
    
    signal num_jugadores : unsigned(3 downto 0);
    signal players_reg   : std_logic_vector(2 downto 0);

begin

    num_jugadores <= unsigned(switches);

    -- 1. Proceso Secuencial (Memoria de estado)
    process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                current_state <= S_IDLE;
                players_reg   <= (others => '0');
            else
                current_state <= next_state;
                
                -- Guardamos el valor validado solo en el momento del check correcto
                if (current_state = S_CHECK) and 
                   (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
                    players_reg <= std_logic_vector(num_jugadores(2 downto 0));
                end if;
            end if;
        end if;
    end process;

    -- 2. Lógica Combinacional (Salidas y Transiciones)
    process (current_state, start, confirm, num_jugadores, timeout_5s, players_reg)
        variable v_num_disp : std_logic_vector(3 downto 0);
    begin
        -- Valores por defecto para evitar latches
        next_state  <= current_state;
        done        <= '0';
        timer_start <= '0';
        players_out <= players_reg;
        
        -- Convertimos switch actual a vector de 4 bits para el display
        v_num_disp := std_logic_vector(num_jugadores);
        
        -- Por defecto mostramos JUG + valor actual de los switches
        -- J | U | G | Num
        disp_code <= CHAR_J & CHAR_U & CHAR_G & v_num_disp;

        case current_state is
            
            when S_IDLE =>
                disp_code <= CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK; -- Apagado
                if start = '1' then
                    next_state <= S_WAIT_CONFIRM;
                end if;

            when S_WAIT_CONFIRM =>
                -- Display muestra "JUG X" (asignado por defecto arriba)
                if confirm = '1' then
                    next_state <= S_CHECK;
                end if;

            when S_CHECK =>
                -- Validamos usando las constantes del PKG
                if (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
                    timer_start <= '1'; -- ¡Arrancamos timer!
                    next_state  <= S_SHOW_OK;
                else
                    timer_start <= '1'; -- ¡Arrancamos timer!
                    next_state  <= S_ERROR;
                end if;

            when S_ERROR =>
                -- Mensaje "Err "
                disp_code <= MSG_ERR;
                if timeout_5s = '1' then
                    next_state <= S_WAIT_CONFIRM;
                end if;

            when S_SHOW_OK =>
                -- Mensaje "J-XC" (Jugador X Confirmado)
                -- J | - | NumGuardado | C
                disp_code <= CHAR_J & CHAR_BLANK & ("0" & players_reg) & CHAR_C;
                
                if timeout_5s = '1' then
                    next_state <= S_DONE;
                end if;

            when S_DONE =>
                done <= '1';
                -- Mantenemos el mensaje de éxito
                disp_code <= CHAR_J & CHAR_BLANK & ("0" & players_reg) & CHAR_C;
                
                -- Esperamos a que el Master baje la señal start (Handshake)
                if start = '0' then
                    next_state <= S_IDLE;
                end if;
                
        end case;
    end process;

end Behavioral;