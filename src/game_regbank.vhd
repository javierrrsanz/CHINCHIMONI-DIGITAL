library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Usamos los tipos t_player_array

entity game_regbank is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        
        -- ===========================
        -- PUERTOS DE ESCRITURA (Write)
        -- ===========================
        
        -- 1. Configuración de Jugadores (Desde FSM_SELECT_PLAYERS)
        we_num_players  : in  std_logic;
        in_num_players  : in  std_logic_vector(2 downto 0); -- Recibimos vector 3 bits
        
        -- 2. Piedras (Desde FSM_EXTRACTION - Futuro)
        we_piedras      : in  std_logic;
        player_idx_p    : in  integer range 1 to MAX_PLAYERS; -- Quién guarda (1..4)
        in_piedras      : in  integer range 0 to MAX_PIEDRAS; -- Cuántas (0..3)
        
        -- 3. Apuestas (Desde FSM_BETTING - Futuro)
        we_apuesta      : in  std_logic;
        player_idx_a    : in  integer range 1 to MAX_PLAYERS; -- Quién apuesta
        in_apuesta      : in  integer range 0 to MAX_APUESTA; -- Cuánto (0..12)
        
        -- 4. Puntuación (Desde FSM_RESOLVER - Futuro)
        we_puntos       : in  std_logic;
        winner_idx      : in  integer range 0 to MAX_PLAYERS; -- Quién ganó la ronda (0=Nadie)
        in_puntos       : in  integer range 0 to MAX_PLAYERS; -- No usado, solo para sintaxis
        
        -- ===========================
        -- PUERTOS DE LECTURA (Read)
        -- ===========================
        -- Salen continuamente, no necesitan enable
        
        out_num_players_vec : out std_logic_vector(2 downto 0); -- Para display
        out_piedras         : out t_player_array; -- Array con las piedras de todos
        out_apuestas        : out t_player_array; -- Array con las apuestas de todos
        out_puntos          : out t_player_array; -- Array con las victorias
        
    );
end game_regbank;

architecture Behavioral of game_regbank is

    -- Registros Internos (Memoria)
    -- Inicializamos a 2 jugadores por defecto
    signal reg_num_players : integer range 0 to MAX_PLAYERS; 
    
    -- Inicializamos arrays a cero (definidos en pkg)
    signal reg_piedras     : t_player_array := (others => 0);
    signal reg_apuestas    : t_player_array := (others => 0);
    signal reg_puntos      : t_player_array := (others => 0);

begin

    -- Proceso de Escritura Síncrono
    process(clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                -- Reset del juego: Limpiamos todo
                reg_num_players <= 0;
                reg_piedras     <= (others => 0);
                reg_apuestas    <= (others => 0);
                reg_puntos      <= (others => 0);
            else
                -- 1. Guardar Número de Jugadores
                if we_num_players = '1' then
                    -- Convertimos vector a integer para guardarlo fácil
                    reg_num_players <= to_integer(unsigned(in_num_players));
                    -- Por seguridad, al cambiar jugadores reiniciamos puntos
                    reg_puntos <= (others => 0); 
                end if;
                
                -- 2. Guardar Piedras
                if we_piedras = '1' then
                    reg_piedras(player_idx_p) <= in_piedras;
                end if;
                
                -- 3. Guardar Apuestas
                if we_apuesta = '1' then
                    reg_apuestas(player_idx_a) <= in_apuesta;
                end if;
                
                -- 4. Actualizar Puntos (Incrementar victorias)
                if we_puntos = '1' then
                    if winner_idx /= 0 then -- Solo si hay un ganador válido (1..4)
                        reg_puntos(winner_idx) <= in_puntos;
                    end if;
                end if;
                
            end if;
        end if;
    end process;

    -- ==========================================
    -- Lógica Combinacional de Salida (Lectura)
    -- ==========================================

    -- 1. Conversión de integer a vector para el Top
    out_num_players_vec <= std_logic_vector(to_unsigned(reg_num_players, 3));
    
    -- 2. Salida directa de arrays
    out_piedras  <= reg_piedras;
    out_apuestas <= reg_apuestas;
    out_puntos   <= reg_puntos;

end Behavioral;