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

    -- No probamos estas
    signal we_apuesta   : std_logic := '0';
    signal player_idx_a : integer range 1 to MAX_PLAYERS := 1;
    signal in_apuesta   : integer range 0 to MAX_APUESTA := 0;

    signal we_puntos    : std_logic := '0';
    signal winner_idx   : integer range 0 to MAX_PLAYERS := 0;

    -- Lectura
    signal out_num_players_vec : std_logic_vector(2 downto 0);
    signal out_piedras         : t_player_array;
    signal out_apuestas        : t_player_array;
    signal out_puntos          : t_player_array;
    signal game_over           : std_logic;
    signal winner_global       : integer range 0 to MAX_PLAYERS;

    -- DUT
    component game_regbank
        port (
            clk   : in  std_logic;
            reset : in  std_logic;

            we_num_players : in std_logic;
            in_num_players : in std_logic_vector(2 downto 0);

            we_piedras   : in std_logic;
            player_idx_p : in integer;
            in_piedras   : in integer;

            we_apuesta   : in std_logic;
            player_idx_a : in integer;
            in_apuesta   : in integer;

            we_puntos    : in std_logic;
            winner_idx   : in integer;

            out_num_players_vec : out std_logic_vector(2 downto 0);
            out_piedras         : out t_player_array;
            out_apuestas        : out t_player_array;
            out_puntos          : out t_player_array;

            game_over     : out std_logic;
            winner_global : out integer
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

            out_num_players_vec => out_num_players_vec,
            out_piedras         => out_piedras,
            out_apuestas        => out_apuestas,
            out_puntos          => out_puntos,
            game_over           => game_over,
            winner_global       => winner_global
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
        -- 2) ESCRIBIR NÚMERO DE JUGADORES = 3
        ----------------------------------------------------------------
        in_num_players <= "011";      -- 3 jugadores
        wait for 15 ns;               -- NO hace falta coincidir con el enable

        we_num_players <= '1';
        wait until rising_edge(clk);
        we_num_players <= '0';

        wait for 40 ns;

        ----------------------------------------------------------------
        -- 3) PRUEBAS DE PIEDRAS (solo este registro por ahora)
        ----------------------------------------------------------------

        ---------------- Jugador 1 ----------------
        player_idx_p <= 1;
        in_piedras   <= 2;    -- 2 piedras
        we_piedras   <= '1';
        wait until rising_edge(clk);
        we_piedras   <= '0';
        wait for 20 ns;

        ---------------- Jugador 2 ----------------
        player_idx_p <= 2;
        in_piedras   <= 1;    -- 1 piedra
        we_piedras   <= '1';
        wait until rising_edge(clk);
        we_piedras   <= '0';
        wait for 20 ns;

        ---------------- Jugador 3 ----------------
        player_idx_p <= 3;
        in_piedras   <= 3;    -- 3 piedras
        we_piedras   <= '1';
        wait until rising_edge(clk);
        we_piedras   <= '0';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- FIN DE LA SIMULACIÓN
        ----------------------------------------------------------------
        wait;
    end process;

end TB;
