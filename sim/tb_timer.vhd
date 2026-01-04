library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity timer_bloque_tb is
end timer_bloque_tb;

architecture Behavioral of timer_bloque_tb is

    -- Componente
    component timer_bloque
        Port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            start   : in  std_logic;
            timeout : out std_logic
        );
    end component;

    -- Señales
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '0';
    signal start   : std_logic := '0';
    signal timeout : std_logic;

    -- Periodo de reloj (125 MHz = 8 ns)
    constant clk_period : time := 8 ns;

begin

    -- Instancia
    uut: timer_bloque port map (
        clk => clk,
        reset => reset,
        start => start,
        timeout => timeout
    );

    -- Generador de reloj
    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Estímulos
    stim_proc: process
    begin		
        -- 1. Inicialización y Reset
        reset <= '1';
        wait for 40 ns;
        reset <= '0';
        wait for 100 ns;

        -- 2. Prueba de arranque del timer
        report "Iniciando timer...";
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- 3. Espera al Timeout
        -- NOTA IMPORTANTE: Si TIMEOUT_5S_CYC es muy grande, 
        -- este 'wait until' puede tardar minutos en el simulador.
        -- Se recomienda reducir el valor en el pkg para el test.
        wait until timeout = '1';
        report "Timeout detectado con éxito";

        -- 4. Verificar que se apaga solo (pulso de un ciclo)
        wait for clk_period;
        if timeout = '0' then
            report "Correcto: El timeout ha sido un pulso de un ciclo";
        end if;

        -- 5. Probar Reset a mitad de cuenta
        wait for 1 us;
        start <= '1';
        wait for clk_period;
        start <= '0';
        wait for 100 us; -- Simulamos que está contando
        
        report "Probando start a mitad de cuenta...";
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- Verificar que no sale timeout tras el start
        wait for 500 us; 
        
        wait for 10 us;
        assert false report "Simulacion terminada. Revisa las ondas." severity failure;
    end process;

end Behavioral;
