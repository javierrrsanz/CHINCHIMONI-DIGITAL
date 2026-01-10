library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- Modulo de control de displays de 7 segmentos
-- Gestiona la visualizacion multiplexada para mostrar 4 caracteres distintos
-- utilizando un unico bus de segmentos y un selector de digito.
entity segmentos is
    Port (
        clk       : in  std_logic; -- Reloj de 125 MHz
        reset     : in  std_logic; -- Reset del sistema
        disp_code : in  std_logic_vector(19 downto 0); -- 4 caracteres de 5 bits cada uno

        segments  : out std_logic_vector(7 downto 0); -- dp + abcdefg (activo-bajo)
        selector  : out std_logic_vector(3 downto 0)  -- Catodo/Anodo comun (activo-alto)
    );
end segmentos;

architecture Behavioral of segmentos is

    -- Configuracion del refresco:
    -- Buscamos una frecuencia de ~4kHz total para que cada digito se refresque a ~1kHz.
    -- Esto evita el parpadeo (flicker) detectable por el ojo humano.
    constant TICK_MAX : integer := 31250 - 1; -- Calculado para 125MHz / 4000Hz
    signal tick_cnt   : integer range 0 to TICK_MAX := 0;

    -- Puntero para saber que digito estamos iluminando en cada instante
    signal digit_sel  : unsigned(1 downto 0) := (others => '0');

    -- Señales para almacenar el caracter actual y su dibujo en segmentos
    signal current_char : std_logic_vector(4 downto 0) := (others => '0');
    signal seg_pat      : std_logic_vector(6 downto 0) := (others => '1');

begin

    -- PROCESO SINCRONO: Gestiona el tiempo, la multiplexacion y la ROM de caracteres
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tick_cnt     <= 0;
                digit_sel    <= (others => '0');
                selector     <= "0000";
                current_char <= (others => '0');
                seg_pat      <= (others => '1'); -- Todo apagado en reset
            else
                -- 1. Divisor de frecuencia para el refresco visual
                if tick_cnt = TICK_MAX then
                    tick_cnt  <= 0;
                    digit_sel <= digit_sel + 1; -- Saltamos al siguiente digito
                else
                    tick_cnt <= tick_cnt + 1;
                end if;

                -- 2. Multiplexacion: Segun el digito activo, seleccionamos su codigo
                -- Los displays se numeran de derecha (0) a izquierda (3)
                case digit_sel is
                    when "00" =>
                        selector     <= "0001"; -- Activamos el primer display
                        current_char <= disp_code(4 downto 0);
                    when "0