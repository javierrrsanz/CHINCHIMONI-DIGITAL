library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;  -- Para MAX_PLAYERS y t_player_array



entity leds_control is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        leds_enable   : in  std_logic;
        player_idx_a : in  integer range 1 to MAX_PLAYERS;
        out_apuestas : in  t_player_array;

        leds         : out std_logic_vector(11 downto 0) --12 LEDs
    );
end leds_control;




architecture Behavioral of leds_control is
    
    signal apuesta_val : integer range 0 to MAX_APUESTA := 0;
    signal mask : std_logic_vector(11 downto 0) := (others => '0'); --señal que guarda el valor de los LEDs

begin

    process(clk, reset)
    
    begin
        if reset = '1' then
            mask <= (others => '0');
            leds <= (others => '0');

        elsif rising_edge(clk) then

            -- Valor estable leído del banco de registros
            apuesta_val := out_apuestas(player_idx_a);

            -- Construcción de barra decodificada
            for i in 0 to 11 loop
                if i < apuesta_val then
                    mask(i) <= '1';
                else
                    mask(i) <= '0';
                end if;
            end loop;

            -- Salida condicionada
            if leds_enable = '1' then
                leds <= mask;  --si el enable esta activo se muestra los LEDs guardados en mask
            else
                leds <= (others => '0');  ----si el enable no está activo no se muestra ningun LED
            end if;

        end if;
    end process;

end Behavioral;