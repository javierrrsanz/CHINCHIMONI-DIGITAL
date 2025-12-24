library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_chinchimoni.ALL;

entity tb_fsm_bet is
end entity;

architecture sim of tb_fsm_bet is

  -- =========================
  -- Señales DUT
  -- =========================
  signal clk                 : std_logic := '0';
  signal reset               : std_logic := '0';

  signal start               : std_logic := '0';
  signal done                : std_logic;

  signal confirm             : std_logic := '0';
  signal switches            : std_logic_vector(3 downto 0) := (others => '0');

  signal timer_start         : std_logic;
  signal timeout_5s          : std_logic := '0';

  signal rondadejuego        : integer range 0 to 100 := 0;

  signal out_num_players_vec : std_logic_vector(2 downto 0) := (others => '0');

  signal apuestas_reg        : t_player_array := (others => 0);
  signal piedras_reg         : t_player_array := (others => 0);

  signal we_apuesta          : std_logic;
  signal player_idx_a        : integer range 1 to MAX_PLAYERS;
  signal in_apuesta          : integer range 0 to MAX_APUESTA;

  signal leds_enable         : std_logic;

  signal disp_code           : std_logic_vector(15 downto 0);

  -- Clock period (125 MHz => 8 ns)
  constant CLK_PERIOD : time := 8 ns;

  -- =========================
  -- Helpers (procedures)
  -- =========================
  procedure pulse_confirm(signal c : out std_logic) is
  begin
    c <= '1';
    wait for CLK_PERIOD;
    c <= '0';
    wait for CLK_PERIOD;
  end procedure;

  procedure pulse_timeout(signal t : out std_logic) is
  begin
    t <= '1';
    wait for CLK_PERIOD;
    t <= '0';
    wait for CLK_PERIOD;
  end procedure;

  procedure set_switches(signal sw : out std_logic_vector(3 downto 0); value : integer) is
  begin
    sw <= std_logic_vector(to_unsigned(value, 4));
    wait for CLK_PERIOD;
  end procedure;

begin

  -- =========================
  -- Instancia DUT
  -- =========================
  DUT: entity work.fsm_bet
    port map (
      clk                 => clk,
      reset               => reset,
      start               => start,
      done                => done,
      confirm             => confirm,
      switches            => switches,
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

  -- =========================
  -- Generación de reloj
  -- =========================
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
  end process;

  -- =========================
  -- Estímulos / Escenarios
  -- =========================
  stim : process
  begin
    -- ---------- INIT ----------
    -- Configuración: suponemos 2 jugadores humanos + CPU => total 3 jugadores.
    -- out_num_players_vec debe contener el valor que el DUT espera.
    -- OJO: tu DUT hace "+ 1". Así que para que num_players=3, pon vector=2.
    out_num_players_vec <= std_logic_vector(to_unsigned(2, 3)); -- 2 + 1 = 3 jugadores
    rondadejuego <= 0;

    -- Piedras por jugador (según tu indexado player_idx-1):
    -- jugador1 -> idx0, jugador2 -> idx1, jugador3 -> idx2
    piedras_reg <= (others => 0);
    piedras_reg(0) <= 1;  -- CPU sacó 1
    piedras_reg(1) <= 2;  -- jugador 2 sacó 2
    piedras_reg(2) <= 3;  -- jugador 3 sacó 3

    -- Apuestas iniciales todas a 0
    apuestas_reg <= (others => 0);

    -- Reset
    reset <= '1';
    wait for 5*CLK_PERIOD;
    reset <= '0';
    wait for 5*CLK_PERIOD;

    -- ---------- START PHASE ----------
    start <= '1';
    wait for 2*CLK_PERIOD;
    start <= '0';
    wait for 2*CLK_PERIOD;

    -- En este punto deberíamos estar en S_WAIT (AP1_)
    assert (disp_code(15 downto 12) = CHAR_A and disp_code(11 downto 8) = CHAR_P)
      report "No parece estar mostrando 'AP' en S_WAIT tras start." severity warning;

    -- ==========================================================
    -- ESCENARIO 1: RONDA 0 (no mentir), jugador 1 intenta apostar 0 (INVALIDO en tu FSM)
    -- ==========================================================
    set_switches(switches, 0);
    pulse_confirm(confirm);   -- S_WAIT -> S_CHECK -> (debería ir a S_ERROR)
    wait for 2*CLK_PERIOD;

    -- Debe mostrar AP1E
    assert (disp_code(3 downto 0) = CHAR_E)
      report "Esperaba estado ERROR (APxE) tras apostar 0." severity error;

    -- timeout para volver a S_WAIT
    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- ==========================================================
    -- ESCENARIO 2: RONDA 0, jugador 1 apuesta 2 con piedras=1 -> esto es MENTIR (val_int > piedras) => ERROR
    -- ==========================================================
    set_switches(switches, 2);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_E)
      report "Esperaba ERROR por mentir en ronda 0 (apuesta > piedras)." severity error;

    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- ==========================================================
    -- ESCENARIO 3: RONDA 0, jugador 1 apuesta 1 (igual a piedras=1) => OK
    -- ==========================================================
    set_switches(switches, 1);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_C)
      report "Esperaba OK (APxC) con apuesta válida." severity error;

    assert (we_apuesta = '1' and leds_enable = '1')
      report "Esperaba we_apuesta y leds_enable activos en S_OK." severity error;

    -- Avanzar al siguiente jugador (timeout)
    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- ==========================================================
    -- ESCENARIO 4: RONDA 0, jugador 2 forzamos error por 'apuestas_reg(player_idx-1) /= 0'
    --   Simulamos que su registro ya tiene algo (ojo: esto en realidad es un chequeo incorrecto, pero lo testeamos)
    -- ==========================================================
    apuestas_reg(1) <= 5;  -- "ya apostó" según esa condición
    wait for CLK_PERIOD;

    set_switches(switches, 2);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_E)
      report "Esperaba ERROR por (apuestas_reg(player_idx-1) /= 0)." severity error;

    -- Liberamos y reintentamos correctamente
    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    apuestas_reg(1) <= 0;
    wait for CLK_PERIOD;

    -- Apuesta válida ronda 0: debe ser <= piedras_reg(1)=2 (según tu lógica val_int > piedras => ERROR)
    set_switches(switches, 2);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_C)
      report "Esperaba OK para jugador 2 con apuesta 2 (piedras=2)." severity error;

    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- ==========================================================
    -- ESCENARIO 5: RONDA 0, jugador 3 apuesta válida (3)
    -- ==========================================================
    set_switches(switches, 3);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_C)
      report "Esperaba OK para jugador 3 con apuesta 3 (piedras=3)." severity error;

    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- Debe llegar a DONE
    assert (done = '1')
      report "Esperaba done=1 al finalizar la fase tras el último jugador." severity error;

    wait for 2*CLK_PERIOD;

    -- ==========================================================
    -- ESCENARIO 6: RONDA 1 (ya se permite mentir), reiniciamos fase y probamos mentir permitido
    -- ==========================================================
    rondadejuego <= 1;
    wait for 2*CLK_PERIOD;

    -- Start de nuevo
    start <= '1';
    wait for 2*CLK_PERIOD;
    start <= '0';
    wait for 2*CLK_PERIOD;

    -- jugador 1 (piedras=1) apuesta 3: en rondadejuego=1 debería ser OK (mentir permitido)
    set_switches(switches, 3);
    pulse_confirm(confirm);
    wait for 2*CLK_PERIOD;

    assert (disp_code(3 downto 0) = CHAR_C)
      report "Esperaba OK al mentir en ronda 1 (permitido)." severity error;

    pulse_timeout(timeout_5s);
    wait for 2*CLK_PERIOD;

    -- Finalizamos simulación
    report "TB completado: escenarios ejecutados." severity note;
    wait for 10*CLK_PERIOD;

    std.env.stop;
    wait;
  end process;

end architecture;
