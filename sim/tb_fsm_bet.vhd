library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity tb_fsm_bet is
end tb_fsm_bet;

architecture tb of tb_fsm_bet is

    constant CLK_PERIOD : time := 10 ns;

    -- Señales DUT
    signal clk                 : std_logic := '0';
    signal reset               : std_logic := '0';
    signal start               : std_logic := '0';
    signal done                : std_logic;
    signal confirm             : std_logic := '0';
    signal switches            : std_logic_vector(3 downto 0) := (others => '0');
    
    -- Señal nueva de IA
    signal ai_request_bet      : std_logic;

    signal timer_start         : std_logic;
    signal timeout_5s          : std_logic := '0';
    signal rondadejuego        : integer range 0 to 100 := 0;
    signal out_num_players_vec : std_logic_vector(2 downto 0) := "010"; 
    signal apuestas_reg        : t_player_array := (others => 0);
    signal piedras_reg         : t_player_array := (others => 0);
    signal we_apuesta          : std_logic;
    signal player_idx_a        : integer range 1 to MAX_PLAYERS;
    signal in_apuesta          : integer range 0 to MAX_APUESTA;
    signal leds_enable         : std_logic;
    signal disp_code           : std_logic_vector(19 downto 0);

begin

    clk <= not clk after CLK_PERIOD/2;

    DUT : entity work.fsm_bet
        port map (
            clk                 => clk,
            reset               => reset,
            start               => start,
            done                => done,
            confirm             => confirm,
            switches            => switches,
            ai_request_bet      => ai_request_bet,
            timer_start         => timer_start,
            timeout_5s          => timeout_5s,
            rondadejuego        => rondadejuego,
            out_num_players_vec => out_num_players_vec,
            apuestas_reg        => apuestas_reg,
            piedras_reg         => piedras_reg,
            we_apuesta          => we_apuesta,
            player_idx_a        => player_idx_a,
            in_apuesta          => in_apuesta,
            leds_enable         => leds_enable,
            disp_code           => disp_code
        );

    stimulus : process
        procedure do_bet(constant bet_value : integer) is
        begin
            switches <= std_logic_vector(to_unsigned(bet_value, 4));
            wait for CLK_PERIOD;
            confirm <= '1';
            wait for CLK_PERIOD;
            confirm <= '0';
        end procedure;

        procedure pulse_timeout is
        begin
            wait for CLK_PERIOD * 2;
            timeout_5s <= '1';
            wait for CLK_PERIOD;
            timeout_5s <= '0';
        end procedure;

    begin
        report "INICIO TEST FSM_BET";
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Configuracion: 2 Jugadores, Ronda 0
        out_num_players_vec <= "010"; 
        rondadejuego <= 0; 
        
        -- Simulamos piedras: J1=1, J2=2
        piedras_reg <= (others => 0);
        piedras_reg(1) <= 1;
        piedras_reg(2) <= 2;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

    
        -- TEST 1: MENTIRA (Apuesta < Piedras) en Ronda 0
       
        report ">> Test J1: Mentir (0 apuesta con 1 piedra)";
        do_bet(0);
        
        wait until rising_edge(clk);
        assert disp_code(4 downto 0) = CHAR_E 
            report "ERROR: No detecta mentira" severity error;
        
        pulse_timeout; -- Reset error

        
        -- TEST 2: APUESTA VALIDA
        
        report ">> Test J1: Apuesta valida (1)";
        do_bet(1);
        
        wait until rising_edge(clk);
        assert we_apuesta = '1' report "ERROR: Rechazo apuesta valida" severity error;
        
        -- IMPORTANTE: Actualizar registro simulado para el siguiente jugador
        apuestas_reg(1) <= 1; 
        pulse_timeout;

        
        -- TEST 3: REPETIR APUESTA
        
        report ">> Test J2: Repetir apuesta (1)";
        do_bet(1);
        
        wait until rising_edge(clk);
        assert disp_code(4 downto 0) = CHAR_E 
            report "ERROR: Permitio repetir apuesta" severity error;
        
        pulse_timeout;

        report "FIN TEST FSM_BET";
        wait;
    end process;

end architecture tb;