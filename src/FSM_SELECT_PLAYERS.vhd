library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Fundamental para MIN_PLAYERS, MAX_PLAYERS y caracteres

-- FSM: Seleccion de Jugadores
-- Esta maquina gestiona el inicio del juego. Permite elegir mediante los switches
-- cuantos jugadores participaran (2-4) y valida la seleccion antes de empezar.
entity FSM_SELECT_PLAYERS is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        
        -- Señales de control de la FSM principal
        start           : in  std_logic; -- Pulso para iniciar esta fase
        done            : out std_logic; -- Pulso que indica que la fase ha terminado
        
        -- Entradas de Hardware
        confirm         : in  std_logic; -- Boton de confirmar (ya filtrado)
        switches        : in  std_logic_vector(3 downto 0); -- Valor de los interruptores
        
        -- Interfaz con el Temporizador de 5s
        timer_start     : out std_logic; -- Dispara el contador
        timeout_5s      : in  std_logic; -- Indica que han pasado 5s
        
        -- Salidas hacia el Banco de Registros y Displays
        we_players_out  : out std_logic; -- Permiso para guardar en memoria
        players_out     : out std_logic_vector(2 downto 0); -- Valor a guardar
        disp_code       : out std_logic_vector(19 downto 0) -- Mensaje para el display
    );
end FSM_SELECT_PLAYERS;

architecture Behavioral of FSM_SELECT_PLAYERS is

    -- Definicion de los estados de la maquina
    type state_type is (
        S_INIT,          -- Esperando orden de la FSM principal
        S_WAIT_CONFIRM,  -- Esperando a que el usuario pulse confirmar
        S_CHECK,         -- Validando si el numero es correcto (2 a 4)
        S_ERROR,         -- Mostrando mensaje de error por seleccion invalida
        S_SHOW_OK,       -- Mostrando seleccion validada durante 5s
        S_DONE           -- Fin de la fase
    );
    signal state : state_type;

    -- Señales internas para manejo de datos
    signal num_jugadores : unsigned(4 downto 0);
    signal players_reg   : std_logic_vector(4 downto 0);

begin
    -- Convertimos los switches a unsigned añadiendo un bit de relleno para operar
    num_jugadores <= '0' & unsigned(switches);

    -- Proceso principal de la FSM
    FSM_PROC : process(clk, reset)
    begin
        if reset = '1' then
            state       <= S_INIT;
            players_reg <= (others => '0');

        elsif rising_edge(clk) then
            case state is
                
                -- Estado inicial: espera la señal 'start' del sistema
                when S_INIT =>
                    if start = '1' then
                        state <= S_WAIT_CONFIRM;
                    else
                        state <= S_INIT;
                    end if;
                
                -- Espera a que el usuario elija con los switches y confirme
                when S_WAIT_CONFIRM => 
                    if confirm = '1' then
                        state <= S_CHECK;
                    else    
                        state <= S_WAIT_CONFIRM;
                    end if;

                -- Comprobacion de reglas: ¿Esta entre 2 y 4?
                when S_CHECK => 
                    if (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
                        state       <= S_SHOW_OK;
                        players_reg <= std_logic_vector(num_jugadores); -- Guardamos valor valido
                    else
                        state       <= S_ERROR; -- Valor fuera de rango
                    end if;

                -- El usuario eligio mal: mostramos error 5 segundos y volvemos a pedir
                when S_ERROR =>
                    if timeout_5s = '1' then
                        state <= S_WAIT_CONFIRM;
                    end if;
                
                -- Todo correcto: mostramos el numero elegido 5 segundos
                when S_SHOW_OK =>
                    if timeout_5s = '1' then
                        state <= S_DONE;
                    end if;
                
                -- Enviamos pulso de finalizacion y volvemos a reposo
                when S_DONE =>
                    state <= S_INIT;

                when others =>
                    state <= S_INIT;
            end case;
        end if;
    end process;

    -- =============================================================
    -- LOGICA COMBINACIONAL DE SALIDAS
    -- =============================================================

    -- Solo activamos la escritura en el banco de registros al finalizar con exito
    we_players_out <= '1' when state = S_DONE else '0';

    -- Pasamos el valor registrado (3 bits son suficientes para 0-4)
    players_out    <= players_reg(2 downto 0);

    -- Disparamos el timer justo cuando entramos a chequear para que cuente en OK/ERROR
    timer_start    <= '1' when state = S_CHECK else '0';

    -- Indica a la FSM principal que hemos terminado
    done           <= '1' when state = S_DONE else '0';

    -- Control del display segun el estado (Mensajes Dinamicos)
    with state select
        disp_code <= CHAR_J & CHAR_U & CHAR_G & std_logic_vector(num_jugadores) when S_WAIT_CONFIRM, -- "JUG x" (en vivo)
                     CHAR_J & CHAR_U & CHAR_G & players_reg                   when S_SHOW_OK,     -- "JUG x" (fijo)
                     CHAR_J & CHAR_U & CHAR_G & CHAR_E                       when S_ERROR,       -- "JUG E" (Error)
                     CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK       when others;

end Behavioral;