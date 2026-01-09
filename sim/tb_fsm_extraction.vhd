library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity tb_FSM_EXTRACTION is
end tb_FSM_EXTRACTION;

architecture Behavioral of tb_FSM_EXTRACTION is

    -- Definición de periodo de reloj
    constant CLK_PERIOD : time := 10 ns;

    -- Señales del DUT
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal start        : std_logic := '0';
    signal done         : std_logic;
    signal confirm      : std_logic := '0';
    signal switches     : std_logic_vector(3 downto 0) := (others => '0');
    
    -- Señal nueva de IA
    signal ai_extraction_request : std_logic;

    signal timer_start  : std_logic;
    signal timeout_5s   : std_logic := '0';

    signal num_players  : integer := 4;
    signal rondadejuego : integer range 0 to 100 := 0;

    signal we_piedras   : std_logic;
    signal player_idx_p : integer range 1 to MAX_PLAYERS;
    signal in_piedras   : integer range 0 to MAX_PIEDRAS;
    signal disp_code    : std_logic_vector(19 downto 0);

begin

    -- Generación de Reloj
    clk <= not clk after CLK_PERIOD/2;

    -- Instancia del DUT
    DUT: entity work.FSM_EXTRACTION
        port map (
            clk          => clk,
            reset        => reset,
            start        => start,
            done         => done,
            confirm      => confirm,
            switches     => switches,
            
            -- Puerto de IA conectado
            ai_extraction_request => ai_extraction_request,

            timer_start  => timer_start,
            timeout_5s   => timeout_5s,

            num_players  => num_players,
            rondadejuego => rondadejuego,

            we_piedras   => we_piedras,
            player_idx_p => player_idx_p,
            in_piedras   => in_piedras,

            disp_code    => disp_code
        );

    -- Proceso de Estímulos
    stim : process
        -- Procedimiento auxiliar para pulsar confirmación
        procedure do_confirm is
        begin
            wait for CLK_PERIOD;
            confirm <= '1';
            wait for CLK_PERIOD;
            confirm <= '0';
        end procedure;

        -- Procedimiento para simular timeout
        procedure do_timeout is
        begin
            wait for CLK_PERIOD*5; 
            timeout_5s <= '1';
            wait for CLK_PERIOD;
            timeout_5s <= '0';
        end procedure;

    begin

        report "===== INICIO TEST FSM_EXTRACTION =====";

        -- 1) Reset
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        wait for 20 ns;

        -- 2) Configuración de partida
        num_players <= 2; -- Probamos con 2 jugadores
        rondadejuego <= 0; -- Ronda 0 (Regla especial: no sacar 0 piedras)

        -- 3) Iniciar FSM
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;

        --------------------------------------------------------------
        -- JUGADOR 1: Intenta sacar 0 piedras en Ronda 0 (ILEGAL)
        --------------------------------------------------------------
        report ">> Test J1: 0 piedras en Ronda 0 (Debe fallar)";
        switches <= "0000"; -- 0
        do_confirm;
        
        -- Esperamos un ciclo para que la FSM evalúe
        wait until rising_edge(clk);
        assert disp_code(4 downto 0) = CHAR_E 
            report "ERROR: Debería dar error al sacar 0 piedras en ronda 0" severity error;
        
        do_timeout; -- Pasamos el tiempo de error

        -- JUGADOR 1: Saca 2 piedras (LEGAL)
        report ">> Test J1: 2 piedras (Correcto)";
        switches <= "0010"; 
        do_confirm;
        
        wait until rising_edge(clk);
        assert disp_code(4 downto 0) /= CHAR_E report "ERROR: 2 piedras debería ser válido" severity error;
        
        do_timeout; -- Pasamos tiempo de éxito -> Turno J2

        --------------------------------------------------------------
        -- JUGADOR 2: Saca 4 piedras (ILEGAL > 3)
        --------------------------------------------------------------
        report ">> Test J2: 4 piedras (Debe fallar)";
        switches <= "0100"; -- 4
        do_confirm;
        
        wait until rising_edge(clk);
        assert disp_code(4 downto 0) = CHAR_E report "ERROR: >3 piedras no detectado" severity error;
        
        do_timeout;

        -- JUGADOR 2: Saca 1 piedra (LEGAL)
        report ">> Test J2: 1 piedra (Correcto y Fin)";
        switches <= "0001";
        do_confirm;
        
        wait until rising_edge(clk);
        assert we_piedras = '0' report "Aun no debe escribir" severity note; -- Escribe tras timeout
        
        do_timeout; 

        -- Verificamos fin
        wait for CLK_PERIOD;
        assert done = '1' report "ERROR: La FSM no terminó tras el último jugador" severity error;

        report "===== FIN TEST FSM_EXTRACTION =====";
        wait;
    end process;

end Behavioral;