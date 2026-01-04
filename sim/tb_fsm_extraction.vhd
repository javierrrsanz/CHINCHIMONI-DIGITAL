library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity tb_FSM_EXTRACTION is
end tb_FSM_EXTRACTION;

architecture Behavioral of tb_FSM_EXTRACTION is

    -- Señales del DUT
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';

    signal start        : std_logic := '0';
    signal done         : std_logic;

    signal confirm      : std_logic := '0';
    signal switches     : std_logic_vector(3 downto 0) := (others => '0');

    signal timer_start  : std_logic;
    signal timeout_5s   : std_logic := '0';

    signal num_players  : integer := 4;
    signal rondadejuego : integer range 0 to 100 := 0;

    signal we_piedras   : std_logic;
    signal player_idx_p : integer range 1 to MAX_PLAYERS;
    signal in_piedras   : integer range 0 to MAX_PIEDRAS;

    signal disp_code    : std_logic_vector(19 downto 0);

begin

    --------------------------------------------------------------------
    -- Reloj
    --------------------------------------------------------------------
    clk <= not clk after 5 ns;


    --------------------------------------------------------------------
    -- Instancia del DUT
    --------------------------------------------------------------------
    DUT: entity work.FSM_EXTRACTION
        port map (
            clk          => clk,
            reset        => reset,

            start        => start,
            done         => done,

            confirm      => confirm,
            switches     => switches,

            timer_start  => timer_start,
            timeout_5s   => timeout_5s,

            num_players  => num_players,
            rondadejuego => rondadejuego,

            we_piedras   => we_piedras,
            player_idx_p => player_idx_p,
            in_piedras   => in_piedras,

            disp_code    => disp_code
        );


    --------------------------------------------------------------------
    -- SECUENCIA PRINCIPAL DEL TEST
    --------------------------------------------------------------------
    stim : process
    begin

        --------------------------------------------------------------
        -- 1) RESET INICIAL
        --------------------------------------------------------------
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        wait for 20 ns;

        --------------------------------------------------------------
        -- 2) Lanzamos la FSM
        --------------------------------------------------------------
        start <= '1';
        wait for 20 ns;
        start <= '0';

        --------------------------------------------------------------
        -- === JUGADOR 1 ===  (válido)
        --------------------------------------------------------------
        switches <= "0010";              -- valor válido: 2
        wait for 20 ns;

        confirm <= '1';
        wait for 20 ns;
        confirm <= '0';
        
        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';


        --------------------------------------------------------------
        -- === JUGADOR 2 === (PRIMERO INVALIDO → LUEGO VALIDACIÓN)
        --------------------------------------------------------------
        
        switches <= "0101";              -- valor inválido (>3)
        wait for 20 ns;

        confirm <= '1';                  -- provoca S_ERROR
        wait for 20 ns;
        confirm <= '0';

        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';


        -- Ahora metemos valor válido
        switches <= "0001";
        wait for 20 ns;

        confirm <= '1';
        wait for 20 ns;
        confirm <= '0';

        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';

        --------------------------------------------------------------
        -- === JUGADOR 3 === (válido)
        --------------------------------------------------------------
        
        switches <= "0011";              -- valor válido: 3
        wait for 20 ns;

        confirm <= '1';
        wait for 20 ns;
        confirm <= '0';

        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';

        --------------------------------------------------------------
        -- === JUGADOR 4 === (PRIMERO INVALIDO → LUEGO VALIDACIÓN)
        --------------------------------------------------------------
        switches <= "1001";              -- inválido (9)
        wait for 20 ns;

        confirm <= '1';
        wait for 20 ns;
        confirm <= '0';

        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';


        -- valor correcto
        switches <= "0010";
        wait for 20 ns;

        confirm <= '1';
        wait for 20 ns;
        confirm <= '0';

        wait for 60 ns;
        timeout_5s <= '1';
        wait for 10 ns;
        timeout_5s <= '0';

        --------------------------------------------------------------
        -- Esperamos final de fase
        --------------------------------------------------------------
        wait;


    end process;

end Behavioral;
