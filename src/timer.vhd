library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity timer_bloque is
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        start   : in  std_logic;
        skip    : in  std_logic; -- NUEVA SEÑAL: Para saltar la espera
        timeout : out std_logic
    );
end timer_bloque;

architecture Behavioral of timer_bloque is
    -- Contador hasta 5 segundos (valor en pkg)
    signal cuenta : integer range 0 to TIMEOUT_5S_CYC;
    signal activo : std_logic;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cuenta <= 0;
                activo <= '0';
                timeout <= '0';
            else
                -- Prioridad 1: Inicio
                if start = '1' then
                    activo <= '1';
                    cuenta <= 0;
                    timeout <= '0';
                
                -- Prioridad 2: Saltar cuenta (Botón Continuar)
                -- Si el timer está activo y pulsamos skip, forzamos el fin.
                elsif activo = '1' and skip = '1' then
                    timeout <= '1';
                    activo  <= '0'; -- Apagamos el timer
                    cuenta  <= 0;

                -- Prioridad 3: Contar normal
                elsif activo = '1' then
                    if cuenta = TIMEOUT_5S_CYC - 1 then
                        timeout <= '1';
                        activo <= '0';
                        cuenta <= 0;
                    else
                        cuenta <= cuenta + 1;
                        timeout <= '0';
                    end if;
                else
                    timeout <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;