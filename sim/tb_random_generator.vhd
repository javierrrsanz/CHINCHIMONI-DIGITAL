library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_random_generator is
-- Entidad vacía para el Test Bench
end tb_random_generator;

architecture Behavioral of tb_random_generator is

    -- 1. Declaración del componente a probar
    component random_generator
        Port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            rnd_out : out std_logic_vector(3 downto 0)
        );
    end component;

    -- 2. Señales de interconexión
    signal clk_tb     : std_logic := '0';
    signal reset_tb   : std_logic := '0';
    signal rnd_out_tb : std_logic_vector(3 downto 0);

    -- 3. Definición del periodo de reloj (125 MHz = 8 ns)
    constant clk_period : time := 8 ns;

begin

    -- 4. Instancia de la unidad bajo prueba (UUT)
    uut: random_generator 
        port map (
            clk     => clk_tb,
            reset   => reset_tb,
            rnd_out => rnd_out_tb
        );

    -- 5. Proceso del reloj
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- 6. Proceso de estímulos
    stim_proc: process
    begin		
        -- Reset inicial del sistema
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';

        -- Dejamos que el contador corra libremente.
        -- Para ver al menos dos ciclos completos (0-15), 
        -- necesitamos esperar 32 ciclos de reloj (32 * 8ns = 256 ns).
        wait for 300 ns;

        -- Probamos un reset a mitad de funcionamiento para ver si vuelve a 0
        report "Probando reset asíncrono...";
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';

        -- Dejamos correr otro poco
        wait for 200 ns;

        -- Finalizamos la simulación
        assert false report "Simulación terminada. Revisa que rnd_out cambie cada 8ns." severity failure;
    end process;

end Behavioral;
