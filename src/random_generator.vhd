library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity random_generator is
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic; -- Solo para inicialización de la FPGA (Power-on)
        
        -- Salida de 4 bits (Valores 0 a 15)
        -- La IA usará esto para decidir piedras (0-3) y apuestas (0-12)
        rnd_out : out std_logic_vector(3 downto 0)
    );
end random_generator;

architecture Behavioral of random_generator is

    -- Contador interno de 4 bits (unsigned para poder sumar)
    -- Se inicializa a 0, pero luego correrá libremente.
    signal counter : unsigned(3 downto 0) := (others => '0');

begin

    -- Proceso libre a 125 MHz
    -- NO reseteamos el contador con el reset del juego para garantizar
    -- que el valor sea impredecible (depende del tiempo que la FPGA lleve encendida)
    process(clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                counter <= (others => '0'); -- Solo al encender la placa
            else
                -- Cuenta continua ciclo a ciclo: 0, 1, 2... 15, 0, 1...
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Salida continua
    rnd_out <= std_logic_vector(counter);

end Behavioral;