library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity tb_game_regbank is
end entity;

architecture TB of tb_game_regbank is

    -- Señales del DUT
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- Escrituras
    signal we_num_players : std_logic := '0';
    signal in_num_players : std_logic_vector(2 downto 0) := (others => '0');

    signal we_piedras   : std_logic := '0';
    signal player_idx_p : integer range 1 to MAX_PLAYERS := 1;
    signal in_piedras   : integer range 0 to MAX_PIEDRAS := 0;

    signal we_apuesta   : std_logic := '0';
    signal player_idx_a : integer range 1 to MAX_PLAYERS := 1;
    signal in_apuesta   : integer range 0 to MAX_APUESTA := 0;

    signal we_puntos    : std_logic := '0';
    signal winner_idx   : integer range 0 to MAX_PLAYERS := 0;
    
    -- SEÑALES NUEVAS
    signal in_puntos    : integer range 0 to MAX_PLAYERS := 0; 
    signal new_round    : std_logic := '0'; 

    -- Lectura
    signal out_num_players_vec : std_logic_vector(2 downto 0);
    signal out_piedras         : t_player_array;
    signal out_apuestas        : t_player_array;
    signal out_puntos          : t_player_array;
    
    -- SEÑAL NUEVA
    signal out_rondadejuego    : integer range 0 to 100;

    -- DUT (Actualizado para coincidir con src/game_regbank.vhd)
    component game_regbank
        port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            
            we_num_players  : in  std_logic;
            in_num_players  : in  std_logic_vector(2 downto 0);
            
            we_piedras      : in  std_logic;
            player_idx_p    : in  integer range 1 to MAX_PLAYERS;
            in_piedras      : in  integer range 0 to MAX_PIEDRAS;
            
            we_apuesta      : in  std_logic;
            player_idx_a    : in  integer range 1 to MAX_PLAYERS;
            in_apuesta      : in  integer range 0 to MAX_APUESTA;
            
            we_puntos       : in  std_logic;
            winner_idx      : in  integer range 0 to MAX_PLAYERS;
            in_puntos       : in  integer range 0 to MAX_PLAYERS;

            new_round       : in  std_logic;

            out_num_players_vec : out std_logic_vector(2 downto 0);
            out_piedras         : out t_player_array;
            out_apuestas        : out t_player_array;
            out_puntos          : out t_player_array;
            out_rondadejuego    : out integer range 0 to 100
        );
    end component;

begin

    --------------------------------------------------------------------
    -- GENERADOR DE RELOJ
    --------------------------------------------------------------------
    clk <= not clk after 10 ns;

    --------------------------------------------------------------------
    -- INSTANCIACIÓN DEL DUT
    --------------------------------------------------------------------
    DUT : game_regbank
        port map(
            clk => clk,
            reset => reset,

            we_num_players => we_num_players,
            in_num_players => in_num_players,

            we_piedras => we_piedras,
            player_idx_p => player_idx_p,
            in_piedras => in_piedras,

            we_apuesta => we_apuesta,
            player_idx_a => player_idx_a,
            in_apuesta => in_apuesta,

            we_puntos => we_puntos,
            winner_idx => winner_idx,
            in_puntos => in_puntos,

            new_round => new_round,

            out_num_players_vec => out_num_players_vec,
            out_piedras         => out_piedras,
            out_apuestas        => out_apuestas,
            out_puntos          => out_puntos,
            out_rondadejuego    => out_rondadejuego
        );

    --------------------------------------------------------------------
    -- ESTÍMULOS
    --------------------------------------------------------------------
    stim : process
    begin

        ----------------------------------------------------------------
        -- 1) RESET
        ----------------------------------------------------------------
        reset <= '1';
        wait for 40 ns;
        reset <= '0';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 2) ESCRIBIR JUGADORES (Debe resetear ronda a 0)
        ----------------------------------------------------------------
        report ">> Test 2: Escribir 3 Jugadores";
        in_num_players <= "011"; 
        we_num_players <= '1';
        wait until rising_edge(clk);
        we_num_players <= '0';
        wait for 20 ns;
        
        assert out_rondadejuego = 0 
            report "ERROR: La ronda no se inicializó a 0" severity error;

        ----------------------------------------------------------------
        -- 3) SIMULAR NUEVA RONDA
        ----------------------------------------------------------------
        report ">> Test 3: Incrementar Ronda";
        new_round <= '1';
        wait until rising_edge(clk);
        new_round <= '0';
        wait for 20 ns;

        assert out_rondadejuego = 1 
            report "ERROR: La ronda no incrementó" severity error;

        ----------------------------------------------------------------
        -- 4) REINICIO DE PARTIDA (El FIX del Reinicio Sucio)
        ----------------------------------------------------------------
        report ">> Test 4: Reinicio de partida (Escribir jugadores de nuevo)";
        -- Simulamos que se pulsa 'Reinicio' y se vuelve a seleccionar jugadores
        we_num_players <= '1';
        wait until rising_edge(clk);
        we_num_players <= '0';
        wait for 20 ns;

        assert out_rondadejuego = 0 
            report "ERROR CRÍTICO: La ronda no se reseteó al reiniciar partida" severity error;

        ----------------------------------------------------------------
        -- 5) ESCRITURA DE PIEDRAS
        ----------------------------------------------------------------
        report ">> Test 5: Escritura de piedras";
        player_idx_p <= 1;
        in_piedras   <= 2;
        we_piedras   <= '1';
        wait until rising_edge(clk);
        we_piedras   <= '0';
        wait for 20 ns;
        
        assert out_piedras(1) = 2 report "Error guardando piedras J1" severity error;

        report "===== TEST FINALIZADO CON ÉXITO =====";
        wait;
    end process;

end TB;