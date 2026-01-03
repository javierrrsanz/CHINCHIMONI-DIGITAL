library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_main_tb is
end fsm_main_tb;

architecture Behavioral of fsm_main_tb is

    component fsm_main
        Port (
            clk              : in  std_logic;
            reset            : in  std_logic;
            btn_reinicio     : in  std_logic;
            done_config      : in  std_logic;
            done_extract     : in  std_logic;
            done_bet         : in  std_logic;
            done_resolve     : in  std_logic;
            game_over_flag   : in  std_logic;
            start_config     : out std_logic;
            start_extract    : out std_logic;
            start_bet        : out std_logic;
            start_resolve    : out std_logic;
            reset_game_logic : out std_logic
        );
    end component;

    signal clk              : std_logic := '0';
    signal reset            : std_logic := '0';
    signal btn_reinicio     : std_logic := '0';
    signal done_config      : std_logic := '0';
    signal done_extract     : std_logic := '0';
    signal done_bet         : std_logic := '0';
    signal done_resolve     : std_logic := '0';
    signal game_over_flag   : std_logic := '0';
    signal start_config     : std_logic;
    signal start_extract    : std_logic;
    signal start_bet        : std_logic;
    signal start_resolve    : std_logic;
    signal reset_game_logic : std_logic;

    constant clk_period : time := 8 ns;

begin

    uut: fsm_main port map (
        clk => clk, reset => reset, btn_reinicio => btn_reinicio,
        done_config => done_config, done_extract => done_extract,
        done_bet => done_bet, done_resolve => done_resolve,
        game_over_flag => game_over_flag, start_config => start_config,
        start_extract => start_extract, start_bet => start_bet,
        start_resolve => start_resolve, reset_game_logic => reset_game_logic
    );

    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin		
        -- Inicialización
        reset <= '1';
        wait for  3*clk_period;
        reset <= '0';
        
        -- 1. Fase de Configuración
        
        wait for 10*clk_period; 
        done_config <= '1';
        wait for clk_period;
        done_config <= '0';

        -- 2. Fase de Extracción
        
        wait for 10*clk_period;
        done_extract <= '1';
        wait for clk_period;
        done_extract <= '0';

        -- 3. Fase de Apuesta
        wait for 10*clk_period;
        done_bet <= '1';
        wait for clk_period;
        done_bet <= '0';

        -- 4. Fase de Resolución (No Game Over)
        
        game_over_flag <= '0'; 
      wait for 10*clk_period;
        done_resolve <= '1';
        wait for clk_period;
        done_resolve <= '0';

        -- 5. Game Over directo (Ronda rápida)
        wait for 10*clk_period;
        done_extract <= '1'; wait for clk_period; done_extract <= '0';
        
        wait for 10*clk_period;
        done_bet <= '1'; wait for clk_period; done_bet <= '0';
        
        
        game_over_flag <= '1';
        wait for 10*clk_period;
        done_resolve <= '1';
        wait for clk_period;
        done_resolve <= '0';

        -- 6. Reinicio con B3
        wait for 20*clk_period;
        btn_reinicio <= '1';
        wait for clk_period;
        btn_reinicio <= '0';

        wait;
    end process;
end Behavioral;