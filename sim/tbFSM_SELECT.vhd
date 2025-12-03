library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_chinchimoni.all;

entity tb_FSM_SELECT_PLAYERS is
end tb_FSM_SELECT_PLAYERS;

architecture tb of tb_FSM_SELECT_PLAYERS is

    -- Señales del DUT
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';  -- Activo a nivel alto
    signal start       : std_logic := '0';
    signal confirm     : std_logic := '0';
    signal switches    : std_logic_vector(3 downto 0) := (others => '0');
    signal timeout_5s  : std_logic := '0';

    -- Salidas
    signal timer_start : std_logic;
    signal done        : std_logic;
    signal players_out : std_logic_vector(2 downto 0);
    signal disp_code   : std_logic_vector(15 downto 0);

    constant CLK_PERIOD : time := 8 us;

begin

    ---------------------------------------------------------------------
    -- INSTANCIACIÓN DEL DUT
    ---------------------------------------------------------------------
    DUT: entity work.FSM_SELECT_PLAYERS
    port map(
        clk         => clk,
        reset       => reset,
        start       => start,
        done        => done,
        confirm     => confirm,
        switches    => switches,
        timer_start => timer_start,
        timeout_5s  => timeout_5s,
        players_out => players_out,
        disp_code   => disp_code
    );

    ---------------------------------------------------------------------
    -- RELOJ 125 kHz
    ---------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    ---------------------------------------------------------------------
    -- ESTÍMULOS PRINCIPALES
    ---------------------------------------------------------------------
    stim_proc : process
    begin
        -----------------------------------------------------------------
        -- 1) Reset alto durante 3 ciclos
        -----------------------------------------------------------------
        reset <= '1';
        wait for 3*CLK_PERIOD;

        reset <= '0';  -- Salir de reset
        wait for 2*CLK_PERIOD;

        -----------------------------------------------------------------
        -- 2) Pulso de start de 1 ciclo
        -----------------------------------------------------------------
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;

        -----------------------------------------------------------------
        -- 3) switches = 6 = 0110 + pulso confirm
        -----------------------------------------------------------------
        switches <= "0110";
        wait for 2*CLK_PERIOD;

        confirm <= '1';
        wait for CLK_PERIOD;
        confirm <= '0';

        -- Simular que pasan 5s => timeout
        wait for 5*CLK_PERIOD;
        timeout_5s <= '1';
        wait for CLK_PERIOD;
        timeout_5s <= '0';
        wait for 5*CLK_PERIOD;

        -----------------------------------------------------------------
        -- 4) switches = 3 = 0011 + pulso confirm
        -----------------------------------------------------------------
        switches <= "0011";
        wait for 3*CLK_PERIOD;

        confirm <= '1';
        wait for CLK_PERIOD;
        confirm <= '0';

        -- Simular timeout nuevamente
        wait for 5*CLK_PERIOD;
        timeout_5s <= '1';
        wait for CLK_PERIOD;
        timeout_5s <= '0';

        -----------------------------------------------------------------
        -- 5) Esperar y finalizar simulación
        -----------------------------------------------------------------
        wait for 20*CLK_PERIOD;
        wait;
    end process;

end tb;
