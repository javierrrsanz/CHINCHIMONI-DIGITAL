library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Generador de numeros aleatorios basado en contador rapido
-- Este bloque aprovecha la alta velocidad del reloj (125 MHz) para generar
-- un valor que cambia tan rapido que resulta impredecible para el usuario.
entity random_generator is
    Port (
        clk     : in  std_logic; -- Reloj del sistema (125 MHz)
        reset   : in  std_logic; -- Reset inicial de la placa
        
        -- Salida de 4 bits (Valores de 0 a 15)
        -- Se usa en la IA para elegir piedras (0-3) y calcular apuestas.
        rnd_out : out std_logic_vector(3 downto 0)
    );
end random_generator;

architecture Behavioral of random_generator is

    -- Contador interno de 4 bits. 
    -- Al ser de 4 bits, vuelve a 0 automaticamente al llegar a 15.
    signal counter : unsigned(3 downto 0) := (others => '0');

begin

    -- Proceso de conteo continuo a maxima velocidad
    -- La clave de la aleatoriedad es que el contador no se resetea con la logica 
    -- normal del juego, sino que depende del tiempo total de ejecucion.
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Inicializacion al encender la FPGA o pulsar reset general
                counter <= (others => '0');
            else
                -- El contador suma 1 en cada ciclo de reloj (cada 8 nanosegundos)
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Pasamos el valor del contador a la salida convirtiendolo a vector de bits
    rnd_out <= std_logic_vector(counter);

end Behavioral;