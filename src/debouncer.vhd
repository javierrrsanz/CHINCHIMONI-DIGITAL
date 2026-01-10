library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL; -- Importante para usar DEBOUNCE_CYC

-- Este modulo sirve para limpiar la señal de los botones
-- Los botones reales tienen rebotes metalicos que pueden engañar a la FSM
entity debouncer is
    Port (
        clk      : in  std_logic; -- Reloj de la placa (125 MHz)
        reset    : in  std_logic; -- Señal de reset
        boton    : in  std_logic; -- Entrada del pulsador fisico
        filtrado : out std_logic  -- Pulso de salida ya limpio
    );
end debouncer;

architecture Behavioral of debouncer is
    
    -- Señales para la cadena de sincronizacion y deteccion de flanco
    -- Q1, Q2 y Q3 nos ayudan a evitar problemas de metaestabilidad
    signal Q1, Q2, Q3, nQ3, flanco : std_logic;
    
    -- Usamos la constante del paquete para el tiempo de espera (unos 20ms)
    constant cont_max : integer := DEBOUNCE_CYC;
    signal cuenta     : integer range 0 to DEBOUNCE_CYC;
    signal E, T       : std_logic; -- E habilita la cuenta, T indica fin del tiempo
    
    -- Maquina de estados para gestionar la pulsacion
    type State_t is (S_Nada, S_Boton);
    signal STATE : State_t;
    
begin

-- Proceso P1: Sincronizador de entrada
-- Metemos la señal en una cadena de flip-flops para que sea estable
P1: process(clk, reset)
begin
    if (reset = '1') then
        Q1 <= '0';
        Q2 <= '0';
        Q3 <= '0';
    elsif rising_edge(clk) then
        Q1 <= boton;
        Q2 <= Q1;
        Q3 <= Q2;
    end if;
end process;

-- Logica para detectar cuando el boton pasa de 0 a 1
nQ3    <= not Q3;
flanco <= nQ3 and Q2;

-- Proceso Temp: Es el temporizador de seguridad
-- Cuando E se activa, cuenta hasta llegar al maximo para confirmar la pulsacion
Temp: process(clk, reset)
begin
    if (reset = '1') then
        cuenta <= 0;
        T      <= '0';
    elsif rising_edge(clk) then
        if (E = '1') then
            if (cuenta < cont_max) then
                cuenta <= cuenta + 1;
                T      <= '0';
            else
                cuenta <= 0;
                T      <= '1'; -- Tiempo cumplido con exito
            end if;
        else
            cuenta <= 0;
            T      <= '0';
        end if;
    end if;
end process;
            
-- Proceso FSM: Controla el flujo del anti-rebotes
FSM: process(clk, reset)
begin
    if (reset = '1') then
        STATE <= S_Nada;
    elsif rising_edge(clk) then
        case STATE is
            -- Esperando a detectar que alguien pulsa
            when S_Nada =>
                if (flanco = '1') then
                    STATE <= S_Boton; -- Hemos visto un flanco, vamos a comprobarlo
                else
                    STATE <= S_Nada;
                end if;
            
            -- Estamos en modo espera para filtrar rebotes
            when S_Boton =>
                if (T = '1') then
                    STATE <= S_Nada; -- Ya ha pasado el tiempo de seguridad
                else
                    STATE <= S_Boton; -- Seguimos esperando a que el contador termine
                end if;    
        end case;
    end if;
end process;        
      
-- Logica de control para las señales internas
E <= '1' when (STATE = S_Boton) else '0'; 

-- La salida final se activa solo si despues de esperar el tiempo el boton sigue pulsado
-- Esto nos asegura que no ha sido un ruido electrico pasajero
filtrado <= '1' when (STATE = S_Boton and Q2 = '1' and T = '1') else '0';

end Behavioral;