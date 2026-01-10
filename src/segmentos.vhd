library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity segmentos is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        disp_code : in  std_logic_vector(19 downto 0);

        segments  : out std_logic_vector(7 downto 0); -- dp + abcdefg (activo-bajo)
        selector  : out std_logic_vector(3 downto 0)  -- activo-alto
    );
end segmentos;

architecture Behavioral of segmentos is

    -- Refresco: tick multiplexado a ~4kHz => ~1kHz por dígito
    constant TICK_MAX : integer := 31250 - 1; -- 125MHz / 4000 Hz
    signal tick_cnt   : integer range 0 to TICK_MAX := 0;

    -- Selector de qué dígito estamos iluminando (0 a 3)
    signal digit_sel  : unsigned(1 downto 0) := (others => '0');

    -- Señales internas registradas para estabilidad
    signal current_char : std_logic_vector(4 downto 0) := (others => '0');
    signal seg_pat      : std_logic_vector(6 downto 0) := (others => '1');

begin

    -- PROCESO ÚNICO SÍNCRONO: Controla refresco, selección y decodificación
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tick_cnt     <= 0;
                digit_sel    <= (others => '0');
                selector     <= "0000";
                current_char <= (others => '0');
                seg_pat      <= (others => '1'); -- Apagado
            else
                -- 1. Contador de tiempo para el refresco visual
                if tick_cnt = TICK_MAX then
                    tick_cnt  <= 0;
                    digit_sel <= digit_sel + 1;
                else
                    tick_cnt <= tick_cnt + 1;
                end if;

                -- 2. Multiplexación: Elegimos qué trozo de disp_code mostrar
                case digit_sel is
                    when "00" =>
                        selector     <= "0001"; -- Dígito derecha
                        current_char <= disp_code(4 downto 0);
                    when "01" => 
                        selector     <= "0010"; 
                        current_char <= disp_code(9 downto 5);
                    when "10" => 
                        selector     <= "0100"; 
                        current_char <= disp_code(14 downto 10);
                    when others => 
                        selector     <= "1000"; -- Dígito izquierda
                        current_char <= disp_code(19 downto 15);
                end case;

                -- 3. Decodificación de carácter a patrón de 7 segmentos
                -- Esta lógica se convierte en una ROM/LUT dentro de la FPGA
                case current_char is
                    when CHAR_0    => seg_pat <= SEG_0;
                    when CHAR_1    => seg_pat <= SEG_1;
                    when CHAR_2    => seg_pat <= SEG_2;
                    when CHAR_3    => seg_pat <= SEG_3;
                    when CHAR_4    => seg_pat <= SEG_4;
                    when CHAR_5    => seg_pat <= SEG_5;
                    when CHAR_6    => seg_pat <= SEG_6;
                    when CHAR_7    => seg_pat <= SEG_7;
                    when CHAR_8    => seg_pat <= SEG_8;
                    when CHAR_9    => seg_pat <= SEG_9;

                    when CHAR_A    => seg_pat <= SEG_A;
                    when CHAR_b    => seg_pat <= SEG_b;
                    when CHAR_C    => seg_pat <= SEG_C;
                    when CHAR_F    => seg_pat <= SEG_F;
                    when CHAR_h    => seg_pat <= SEG_h;
                    when CHAR_J    => seg_pat <= SEG_J;
                    when CHAR_G    => seg_pat <= SEG_G;
                    when CHAR_P    => seg_pat <= SEG_P;
                    when CHAR_U    => seg_pat <= SEG_U;
                    when CHAR_E    => seg_pat <= SEG_E;
                    when CHAR_Cmin => seg_pat <= SEG_Cmin;
                    when CHAR_n    => seg_pat <= SEG_n;
                    when CHAR_I    => seg_pat <= SEG_I;

                    when CHAR_BLANK => seg_pat <= (others => '1');
                    when others     => seg_pat <= (others => '1');
                end case;
            end if;
        end if;
    end process;

    -- 4. Asignación de salida final
    -- Concatenamos '1' en el MSB para mantener el punto decimal (dp) siempre apagado
    segments <= '1' & seg_pat;

end Behavioral;