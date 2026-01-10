library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Paquete global del Chinchimoni Digital
-- Contiene todas las constantes, tipos y definiciones de caracteres para
-- que el diseño sea modular y facil de mantener.
package pkg_chinchimoni is

    -- =============================================================
    -- 1. CONSTANTES DE TIEMPO Y RELOJ (Ajustado a PYNQ-Z2)
    -- =============================================================
    constant CLK_FREQ_HZ     : integer := 125_000_000; -- Reloj base de 125 MHz
    
    -- Tiempo de Visualizacion (5 segundos segun el enunciado)
    -- Para simulacion en Vivado se recomienda bajar este valor a 1000
    constant TIMEOUT_5S_CYC  : integer := 5 * CLK_FREQ_HZ; 
    
    -- Filtro de antirebotes para botones (20ms)
    constant DEBOUNCE_CYC    : integer := 2_500_000;

    -- =============================================================
    -- 2. REGLAS FISICAS DEL JUEGO
    -- =============================================================
    constant MIN_PLAYERS : integer := 2;
    constant MAX_PLAYERS : integer := 4;
    constant MAX_PIEDRAS : integer := 3; 
    constant MAX_APUESTA : integer := MAX_PLAYERS * MAX_PIEDRAS; -- Maximo 12

    -- =============================================================
    -- 3. TIPOS DE DATOS PERSONALIZADOS
    -- =============================================================
    -- Array para almacenar las apuestas o piedras de los 4 posibles jugadores
    type t_player_array is array (1 to MAX_PLAYERS) of integer range 0 to 15;

    -- =============================================================
    -- 4. CODIGOS DE CONTROL DE CARACTERES (Logica interna)
    -- =============================================================
    -- Usamos 5 bits para identificar cada letra o numero de forma unica
    
    -- Numeros del 0 al 9
    constant CHAR_0 : std_logic_vector(4 downto 0) := "00000";
    constant CHAR_1 : std_logic_vector(4 downto 0) := "00001";
    constant CHAR_2 : std_logic_vector(4 downto 0) := "00010";
    constant CHAR_3 : std_logic_vector(4 downto 0) := "00011";
    constant CHAR_4 : std_logic_vector(4 downto 0) := "00100";
    constant CHAR_5 : std_logic_vector(4 downto 0) := "00101";
    constant CHAR_6 : std_logic_vector(4 downto 0) := "00110";
    constant CHAR_7 : std_logic_vector(4 downto 0) := "00111";
    constant CHAR_8 : std_logic_vector(4 downto 0) := "01000";
    constant CHAR_9 : std_logic_vector(4 downto 0) := "01001";

    -- Letras para mensajes (JUG, ch, AP, FIn, Err)
    constant CHAR_A    : std_logic_vector(4 downto 0) := "01010"; 
    constant CHAR_b    : std_logic_vector(4 downto 0) := "01011"; 
    constant CHAR_C    : std_logic_vector(4 downto 0) := "01100"; 
    constant CHAR_F    : std_logic_vector(4 downto 0) := "01101"; 
    constant CHAR_h    : std_logic_vector(4 downto 0) := "01110"; 
    constant CHAR_J    : std_logic_vector(4 downto 0) := "01111"; 
    constant CHAR_G    : std_logic_vector(4 downto 0) := "10000"; 
    constant CHAR_P    : std_logic_vector(4 downto 0) := "10001"; 
    constant CHAR_U    : std_logic_vector(4 downto 0) := "10010"; 
    constant CHAR_E    : std_logic_vector(4 downto 0) := "10011"; 
    constant CHAR_Cmin : std_logic_vector(4 downto 0) := "10100"; 
    constant CHAR_n    : std_logic_vector(4 downto 0) := "10101"; 
    constant CHAR_I    : std_logic_vector(4 downto 0) := "10110"; 
    constant CHAR_BLANK : std_logic_vector(4 downto 0) := "11111"; 

    -- Mensaje de Error rapido (E E E E)
    constant MSG_ERR : std_logic_vector(19 downto 0) := CHAR_E & CHAR_E & CHAR_E & CHAR_E;

    -- =============================================================
    -- 5. PATRONES FISICOS PARA 7 SEGMENTOS (Activo en BAJA)
    -- =============================================================
    -- Cada bit controla un segmento: "abcdefg"
    -- Un '0' enciende el segmento, un '1' lo apaga.

    -- Dibujo de numeros
    constant SEG_0 : std_logic_vector(6 downto 0) := "0000001";
    constant SEG_1 : std_logic_vector(6 downto 0) := "1001111";
    constant SEG_2 : std_logic_vector(6 downto 0) := "0010010";   
    constant SEG_3 : std_logic_vector(6 downto 0) := "0000110";
    constant SEG_4 : std_logic_vector(6 downto 0) := "1001100";
    constant SEG_5 : std_logic_vector(6 downto 0) := "0100100";
    constant SEG_6 : std_logic_vector(6 downto 0) := "0100000";
    constant SEG_7 : std_logic_vector(6 downto 0) := "0001111";
    constant SEG_8 : std_logic_vector(6 downto 0) := "0000000";
    constant SEG_9 : std_logic_vector(6 downto 0) := "0000100";

    -- Dibujo de letras y simbolos especiales
    constant SEG_A    : std_logic_vector(6 downto 0) := "0001000";
    constant SEG_b    : std_logic_vector(6 downto 0) := "1100000";
    constant SEG_C    : std_logic_vector(6 downto 0) := "0110001";
    constant SEG_F    : std_logic_vector(6 downto 0) := "0111000";
    constant SEG_h    : std_logic_vector(6 downto 0) := "1101000";
    constant SEG_J    : std_logic_vector(6 downto 0) := "1000011";
    constant SEG_G    : std_logic_vector(6 downto 0) := "0100000";
    constant SEG_P    : std_logic_vector(6 downto 0) := "0011000";
    constant SEG_U    : std_logic_vector(6 downto 0) := "1000001"; 
    constant SEG_E    : std_logic_vector(6 downto 0) := "0110000";
    constant SEG_Cmin : std_logic_vector(6 downto 0) := "1110010";
    constant SEG_n    : std_logic_vector(6 downto 0) := "1101010";
    constant SEG_I    : std_logic_vector(6 downto 0) := "1001111";
    constant SEG_BLANK: std_logic_vector(6 downto 0) := "1111111"; -- Todos los segmentos apagados

end package pkg_chinchimoni;

package body pkg_chinchimoni is
    -- No se requieren subprogramas en el cuerpo del paquete
end package body;