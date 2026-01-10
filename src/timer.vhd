library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Importante para usar TIMEOUT_5S_CYC

-- Bloque temporizador de 5 segundos
-- Sirve para que los mensajes del display se mantengan legibles un tiempo
-- o para saltar la espera si el jugador pulsa el boton correspondiente.
entity timer_bloque is
    Port (
        clk     : in  std_logic; -- Reloj de 125 MHz
        reset   : in  std_logic; -- Reset del sistema
        start   : in  std_logic; -- Señal para empezar a contar
        skip    : in  std_logic; -- Entrada para saltar la espera (boton continuar)
        timeout : out std_logic  -- Pulso que indica que el tiempo ha terminado
    );
end timer_bloque;

architecture Behavioral of timer_bloque is
    -- Usamos la constante definida en el paquete para el tiempo de 5s
    signal cuenta : integer range 0 to TIMEOUT_5S_CYC;
    signal activo : std_logic; -- Indica si el temporizador esta corriendo
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Reset general: dejamos todo a cero
            if reset = '1' then
                cuenta  <= 0;
                activo  <= '0';
                timeout <= '0';
            else
                -- Logica de control por prioridades
                
                -- PRIORIDAD 1: Inicio del temporizador
                -- Si recibimos start, empezamos la cuenta desde cero.
                if start = '1' then
                    activo  <= '1';
                    cuenta  <= 0;
                    timeout <= '0';
                
                -- PRIORIDAD 2: Salto manual (Boton Continuar)
                -- Si el timer esta funcionando y pulsamos skip, terminamos al instante.
                elsif activo = '1' and skip = '1' then
                    timeout <= '1';
                    activo  <= '0'; -- Lo apagamos para que no siga contando
                    cuenta  <= 0;

                -- PRIORIDAD 3: Funcionamiento normal
                elsif activo = '1' then
                    -- Comprobamos si hemos llegado al final del tiempo (5 segundos)
                    if cuenta = TIMEOUT_5S_CYC - 1 then
                        timeout <= '1';
                        activo  <= '0';
                        cuenta  <= 0;
                    else
                        -- Seguimos sumando ciclos de reloj
                        cuenta  <= cuenta + 1;
                        timeout <= '0';
                    end if;
                else
                    -- Si no esta activo, la salida siempre es cero
                    timeout <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;