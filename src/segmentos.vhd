library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

-- ============================================================================
-- ENTIDAD: SEGMENTOS
-- DESCRIPCIÓN: Gestiona el refresco multiplexado de los 4 dígitos del display
--              de 7 segmentos. Recibe un bus de 20 bits (4 caracteres x 5 bits).
-- ============================================================================
entity segmentos is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        -- Bus de entrada: [19:15] Dig4, [14:10] Dig3, [9:5] Dig2, [4:0] Dig1
        disp_code : in  std_logic_vector(19 downto 0);
        -- Salidas físicas a la FPGA
        segments  : out std_logic_vector(7 downto 0); -- Catodos (A-G + DP)
        selector  : out std_logic_vector(3 downto 0)  -- Anodos (Selección dígito)
    );
end segmentos;

architecture Behavioral of segmentos is

    -- SEÑALES DE CONTROL DE TIEMPO
    -- Usamos un contador para generar una frecuencia de refresco (~1 KHz)
    signal prescaler : unsigned(15 downto 0) := (others => '0');
    signal digit_sel : unsigned(1 downto 0)  := "00"; -- Indica qué dígito toca iluminar
    
    -- SEÑALES INTERNAS PARA EL DECODER
    signal current_char : std_logic_vector(4 downto 0); -- El código de 5 bits actual

begin

    -- ------------------------------------------------------------------------
    -- 1. DIVISOR DE FRECUENCIA (Multiplexación)
    -- ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                prescaler <= (others => '0');
                digit_sel <= "00";
            else
                prescaler <= prescaler + 1;
                -- Cada vez que el contador desborda (aprox cada 1ms a 50MHz)
                -- pasamos al siguiente dígito para evitar parpadeos
                if prescaler = 0 then
                    digit_sel <= digit_sel + 1;
                end if;
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------------
    -- 2. MUX DE ENTRADA Y SELECTOR DE �?NODO
    -- ------------------------------------------------------------------------
    process(digit_sel, disp_code)
    begin
        case digit_sel is
            when "00" =>
                selector     <= "1110"; -- Activa Dígito 1 (Derecha)
                current_char <= disp_code(4 downto 0);
            when "01" =>
                selector     <= "1101"; -- Activa Dígito 2
                current_char <= disp_code(9 downto 5);
            when "10" =>
                selector     <= "1011"; -- Activa Dígito 3
                current_char <= disp_code(14 downto 10);
            when "11" =>
                selector     <= "0111"; -- Activa Dígito 4 (Izquierda)
                current_char <= disp_code(19 downto 15);
            when others =>
                selector     <= "1111";
                current_char <= "11111";
        end case;
    end process;

    -- ------------------------------------------------------------------------
    -- 3. DECODIFICADOR DE CARACTERES (ROM Lógica)
    -- Convierte el código de 5 bits al dibujo de 7 segmentos (Lógica Negativa)
    -- ------------------------------------------------------------------------
    process(current_char)
    begin
        case current_char is
            -- Números (0-9)
            when "00000" => segments <= "11000000"; -- 0
            when "00001" => segments <= "11111001"; -- 1
            when "00010" => segments <= "10100100"; -- 2
            when "00011" => segments <= "10110000"; -- 3
            when "00100" => segments <= "10011001"; -- 4
            when "00101" => segments <= "10010010"; -- 5
            when "00110" => segments <= "10000010"; -- 6
            when "00111" => segments <= "11111000"; -- 7
            when "01000" => segments <= "10000000"; -- 8
            when "01001" => segments <= "10010000"; -- 9
            
            -- Caracteres especiales (Definidos en tu pkg_chinchimoni)
            when CHAR_A  => segments <= "10001000"; -- 'A'
            when CHAR_P  => segments <= "10001100"; -- 'P'
            when CHAR_J  => segments <= "11100001"; -- 'J'
            when CHAR_U  => segments <= "11000001"; -- 'U'
            when CHAR_G  => segments <= "11000010"; -- 'G'
            when CHAR_E  => segments <= "10000110"; -- 'E' (Error)
            when CHAR_C  => segments <= "11000110"; -- 'C' (Confirmado/Ok)
            when CHAR_B  => segments <= "10000011"; -- 'b' (Bet/Apuesta)
            
            -- Otros
            when CHAR_BLANK => segments <= "11111111"; -- Apagado
            when others     => segments <= "11111111";
        end case;
    end process;

end Behavioral;