library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Importamos MAX_PLAYERS y el tipo t_player_array

-- Banco de Registros del Juego
-- Funciona como la memoria central donde se almacena el estado de la partida.
-- Centraliza los datos para que la FSM, la IA y los Displays puedan consultarlos.
entity game_regbank is
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;
        
        -- =============================================================
        -- INTERFAZ DE ESCRITURA (Controlada por la FSM principal)
        -- =============================================================
        
        -- 1. Configuracion de la partida
        we_num_players      : in  std_logic; -- Enable para guardar num. jugadores
        in_num_players      : in  std_logic_vector(2 downto 0);
        
        -- 2. Registro de Piedras (Fase de extraccion)
        we_piedras          : in  std_logic;
        player_idx_p        : in  integer range 1 to MAX_PLAYERS; -- ID del jugador
        in_piedras          : in  integer range 0 to MAX_PIEDRAS; -- Cantidad
        
        -- 3. Registro de Apuestas (Fase de pujas)
        we_apuesta          : in  std_logic;
        player_idx_a        : in  integer range 1 to MAX_PLAYERS;
        in_apuesta          : in  integer range 0 to MAX_APUESTA;
        
        -- 4. Registro de Puntuacion (Fase de resolucion)
        we_puntos           : in  std_logic;
        winner_idx          : in  integer range 0 to MAX_PLAYERS; -- 0 si nadie gana
        in_puntos           : in  integer range 0 to MAX_PLAYERS; -- Valor a guardar

        -- Control de flujo
        new_round           : in  std_logic; -- Pulso para limpiar datos de la ronda anterior

        -- =============================================================
        -- INTERFAZ DE LECTURA (Salidas continuas)
        -- =============================================================
        out_num_players_vec : out std_logic_vector(2 downto 0);
        out_piedras         : out t_player_array; -- Array con piedras de todos
        out_apuestas        : out t_player_array; -- Array con apuestas de todos
        out_puntos          : out t_player_array; -- Array con victorias totales
        out_rondadejuego    : out integer range 0 to 100 -- Contador de rondas
    );
end game_regbank;

architecture Behavioral of game_regbank is

    -- REGISTROS INTERNOS (La memoria real en la FPGA)
    signal reg_rondadejuego : integer range 0 to 100;
    signal reg_num_players  : integer range 0 to MAX_PLAYERS;
    
    -- Inicializamos los arrays a cero usando el tipo definido en el package
    signal reg_piedras      : t_player_array := (others => 0);
    signal reg_apuestas     : t_player_array := (others => 0);
    signal reg_puntos       : t_player_array := (others => 0);

begin

    -- PROCESO DE ESCRITURA: Solo cambia los datos en el flanco de subida del reloj
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- RESET TOTAL: Volvemos al estado inicial de fabrica
                reg_num_players  <= 0;
                reg_rondadejuego <= 0;
                reg_piedras      <= (others => 0);
                reg_apuestas     <= (others => 0);
                reg_puntos       <= (others => 0);
            else
                -- GESTION DE NUEVA RONDA
                -- Al empezar ronda, sumamos el contador y borramos manos/apuestas
                if new_round = '1' then
                    reg_rondadejuego <= reg_rondadejuego + 1;
                    reg_piedras      <= (others => 0);
                    reg_apuestas     <= (others => 0);
                end if;

                -- 1. ACTUALIZAR JUGADORES
                if we_num_players = '1' then
                    reg_num_players <= to_integer(unsigned(in_num_players));
                    reg_puntos      <= (others => 0); -- Reiniciamos marcador al cambiar jugadores
                    reg_rondadejuego <= 0;            -- Empezamos partida de cero
                end if;
                
                -- 2. GUARDAR PIEDRAS (Solo del jugador que toca)
                if we_piedras = '1' then
                    reg_piedras(player_idx_p) <= in_piedras;
                end if;
                
                -- 3. GUARDAR APUESTAS
                if we_apuesta = '1' then
                    reg_apuestas(player_idx_a) <= in_apuesta;
                end if;
                
                -- 4. ACTUALIZAR MARCADOR
                if we_puntos = '1' then
                    if winner_idx /= 0 then 
                        reg_puntos(winner_idx) <= in_puntos;
                    end if;
                end if;
                
            end if;
        end if;
    end process;

    -- =============================================================
    -- LOGICA DE LECTURA (Asignaciones directas)
    -- =============================================================
    
    -- Convertimos el numero de jugadores a vector para el display
    out_num_players_vec <= std_logic_vector(to_unsigned(reg_num_players, 3));

    -- Sacamos los arrays completos para que el resto de bloques los usen
    out_piedras      <= reg_piedras;
    out_apuestas     <= reg_apuestas;
    out_puntos       <= reg_puntos;
    out_rondadejuego <= reg_rondadejuego;

end Behavioral;