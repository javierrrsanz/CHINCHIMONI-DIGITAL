library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Usamos nuestro paquete para saber cuántos ciclos son 5 segundos
use work.pkg_chinchimoni.ALL;

entity timer_bloque is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic; -- Reset síncrono
        
        -- Señal de inicio: un pulso que nos dice "¡Empieza a contar!"
        start     : in  std_logic; 
        
        -- Salida: avisa cuando han pasado los 5 segundos
        timeout   : out std_logic
    );
end timer_bloque;

architecture Behavioral of timer_bloque is

    -- Contador: cuenta desde 0 hasta el valor definido en el pkg (5 segs)
    signal cuenta : integer range 0 to TIMEOUT_5S_CYC;
    
    -- Bandera para saber si el cronómetro está en marcha
    signal activo : std_logic;

begin

    process(clk)
    begin
        -- Usamos la sintaxis clásica para detectar el flanco de subida
        if clk'event and clk = '1' then
            
            -- 1. Reset síncrono (siempre lo primero)
            if reset = '1' then
                cuenta <= 0;
                activo <= '0';
                timeout <= '0';
            
            else
                -- 2. Si nos llega la señal de arranque (start)
                if start = '1' then
                    activo <= '1';  -- Encendemos el timer
                    cuenta <= 0;    -- Reiniciamos la cuenta
                    timeout <= '0'; -- Bajamos la bandera de fin por si acaso
                
                -- 3. Si el timer está encendido, contamos
                elsif activo = '1' then
                    -- Comprobamos si hemos llegado al final
                    -- (Restamos 1 porque el 0 también cuenta)
                    if cuenta = TIMEOUT_5S_CYC - 1 then
                        timeout <= '1'; -- ¡Tiempo! Avisamos fuera
                        activo <= '0';  -- Apagamos el timer para ahorrar
                        cuenta <= 0;
                    else
                        -- Si no hemos acabado, seguimos sumando
                        cuenta <= cuenta + 1;
                        timeout <= '0';
                    end if;
                
                -- 4. Si no pasa nada, todo tranquilo
                else
                    timeout <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;