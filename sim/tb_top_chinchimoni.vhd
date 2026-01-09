library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity tb_chinchimoni_top is
end tb_chinchimoni_top;

architecture Behavioral of tb_chinchimoni_top is

    -- Declaración del componente a probar
    component chinchimoni_top
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            switches : in  std_logic_vector(3 downto 0);
            botones  : in  std_logic_vector(3 downto 0);
            leds_4   : out std_logic_vector(3 downto 0);
            leds_8   : out std_logic_vector(7 downto 0);
            segments : out std_logic_vector(7 downto 0);
            selector : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Señales de prueba
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal switches : std_logic_vector(3 downto 0) := (others => '0');
    signal botones  : std_logic_vector(3 downto 0) := (others => '0'); 
    
    signal leds_4   : std_logic_vector(3 downto 0);
    signal leds_8   : std_logic_vector(7 downto 0);
    signal segments : std_logic_vector(7 downto 0);
    signal selector : std_logic_vector(3 downto 0);

    -- Frecuencia de 125 MHz
    constant CLK_PERIOD : time := 8 ns;

    -- Procedimiento para simular la pulsación física del botón 'Confirmar' (BTN3)
    procedure pulsar_confirmar(signal btn : out std_logic_vector(3 downto 0)) is
    begin
        wait for 100 ns;
        btn(3) <= '1'; -- Presionamos
        wait for 30 ms; -- Mantenemos para superar el filtro anti-rebotes
        btn(3) <= '0'; -- Soltamos
        wait for 30 ms;
    end procedure;

begin

    -- Instancia del DUT
    uut: chinchimoni_top port map(
        clk => clk, reset => reset, switches => switches, botones => botones,
        leds_4 => leds_4, leds_8 => leds_8, segments => segments, selector => selector
    );

    -- Generación de reloj
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proceso principal de estímulos
    stim_proc: process
    begin
        -- 1. Reset inicial
        report ">> Reset del sistema...";
        reset <= '1'; 
        wait for 200 ns;
        reset <= '0';
        wait for 200 ns;

        -- 2. Configuración: 2 Jugadores
        report ">> Configuración: Seleccionando 2 jugadores...";
        switches <= "0010"; 
        wait for 1 us; 
        pulsar_confirmar(botones);
        
        -- Esperamos a que pase el tiempo de visualización de la configuración
        -- NOTA: Para simular, reducir TIMEOUT_5S_CYC en el paquete pkg_chinchimoni
        wait for 100 us; 

        -- 3. Extracción de Piedras
        report ">> Fase Extracción: Turno de la IA (J1)...";
        wait for 200 us; -- La IA juega automáticamente
        
        report ">> Fase Extracción: Turno Humano (J2). Sacamos 1 piedra...";
        switches <= "0001"; 
        pulsar_confirmar(botones);
        
        wait for 200 us; -- Transición a fase de apuestas

        -- 4. Apuestas
        report ">> Fase Apuestas: Turno de la IA (J1)...";
        wait for 200 us; -- La IA apuesta automáticamente
        
        report ">> Fase Apuestas: Turno Humano (J2). Apostamos 3...";
        switches <= "0011"; 
        pulsar_confirmar(botones);
        
        -- 5. Resolución
        report ">> Fase Resolución: Mostrando resultados...";
        wait for 1 ms; 

        assert false report "Simulación completada con éxito." severity failure;
    end process;

end Behavioral;