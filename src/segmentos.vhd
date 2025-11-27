library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------
--  MÓDULO DE DISPLAY PARA CHINCHIMONI DIGITAL
--  - Controla los 4 displays mediante multiplexado.
--  - Decodifica dígitos BCD y letras utilizadas en el juego.
--  - Recibe un código de 16 bits (4 caracteres) desde la FSM.
--  - Cada carácter es un código de 4 bits.
--
--  msg_code(15:12) → display izquierda
--  msg_code(11:8)  → display 2
--  msg_code(7:4)   → display 1
--  msg_code(3:0)   → display derecha
--
--  Carácter especial "_" se representa como "1111".
--------------------------------------------------------------------

entity segmentos is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;

        -- Código de mensaje de 4 caracteres (4 bits por carácter)
        msg_code  : in  std_logic_vector(15 downto 0);

        segments  : out std_logic_vector(7 downto 0); -- a..g + dp
        selector  : out std_logic_vector(3 downto 0)  -- display seleccionado
    );
end segmentos;

architecture Behavioral of segmentos is

    ----------------------------------------------------------------
    -- Para refresco (~1 kHz por dígito)
    ----------------------------------------------------------------
    constant REFRESH_MAX : integer := 125000;

    signal refresh_cnt  : integer range 0 to REFRESH_MAX-1 := 0;
    signal tick_refresh : std_logic := '0';

    signal digit_sel : std_logic_vector(1 downto 0) := "00";  -- display activo

    -- Carácter actual (4 bits → tabla)
    signal current_char : std_logic_vector(3 downto 0);

    -- Segmentos decodificados (activo en '0')
    signal seg7 : std_logic_vector(6 downto 0);

    ----------------------------------------------------------------
    -- TABLA DE CARACTERES:
    -- Usamos códigos de 4 bits para letras y números:
    --
    -- 0000 → 0        0001 → 1        ... 
    -- 1000 → 8        1001 → 9
    -- 1010 → A        1011 → C
    -- 1100 → H        1101 → J
    -- 1110 → G        1111 → "_"
    --
    -- Letras para el juego:
    -- A, C, H, J, P, G, F, N, I, E, L, O, R, d
    ----------------------------------------------------------------

    function decode_char(ch : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case ch is
            -- Dígitos 0–9 (activos en '0')
            when "0000" => seg := "0000001"; -- 0
            when "0001" => seg := "1001111"; -- 1
            when "0010" => seg := "0010010"; -- 2
            when "0011" => seg := "0000110"; -- 3
            when "0100" => seg := "1001100"; -- 4
            when "0101" => seg := "0100100"; -- 5
            when "0110" => seg := "0100000"; -- 6
            when "0111" => seg := "0001111"; -- 7
            when "1000" => seg := "0000000"; -- 8
            when "1001" => seg := "0000100"; -- 9

            -- Letras necesarias para el juego:
            -- NOTA: el display es limitado, se usan representaciones aproximadas.
            when "1010" => seg := "0001000"; -- A
            when "1011" => seg := "0110001"; -- C
            when "1100" => seg := "1001000"; -- H
            when "1101" => seg := "1000111"; -- J
            when "1110" => seg := "0100000"; -- G
            when "0100" => seg := "1110000"; -- I
            when "0101" => seg := "0111000"; -- F
            when "0110" => seg := "1110001"; -- L
            when "0111" => seg := "0110000"; -- O
            when "1011" => seg := "0001001"; -- P
            when "1000" => seg := "0001001"; -- R (similar a P)
            when "0011" => seg := "0000100"; -- d (mini-d: aproximado)
            when others => seg := "1111111"; -- "_" o vacío
        end case;

        return seg;
    end function;

begin

    --------------------------------------------------------------
    -- 1) Tick de refresco
    --------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_cnt  <= 0;
            tick_refresh <= '0';
        elsif rising_edge(clk) then
            if refresh_cnt = REFRESH_MAX-1 then
                refresh_cnt  <= 0;
                tick_refresh <= '1';
            else
                refresh_cnt  <= refresh_cnt + 1;
                tick_refresh <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------
    -- 2) Multiplexación (cambio de display 0→1→2→3)
    --------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            digit_sel <= "00";
        elsif rising_edge(clk) then
            if tick_refresh = '1' then
                digit_sel <= std_logic_vector(unsigned(digit_sel) + 1);
            end if;
        end if;
    end process;

    --------------------------------------------------------------
    -- 3) Selección de carácter (4 bits) a partir del msg_code
    --------------------------------------------------------------
    process(digit_sel, msg_code)
    begin
        case digit_sel is
            when "00" =>
                current_char <= msg_code(3 downto 0);
                selector     <= "0001";

            when "01" =>
                current_char <= msg_code(7 downto 4);
                selector     <= "0010";

            when "10" =>
                current_char <= msg_code(11 downto 8);
                selector     <= "0100";

            when others =>   -- "11"
                current_char <= msg_code(15 downto 12);
                selector     <= "1000";
        end case;
    end process;

    --------------------------------------------------------------
    -- 4) Decodificación carácter → segmentos
    --------------------------------------------------------------
    process(current_char)
    begin
        seg7 <= decode_char(current_char);
    end process;

    --------------------------------------------------------------
    -- 5) Construcción final de salida
    --    dp apagado siempre (1)
    --------------------------------------------------------------
    segments <= '1' & seg7;

end Behavioral;

