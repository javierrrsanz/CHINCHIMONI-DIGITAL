library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package pkg_chinchimoni is

    -- =============================================================
    -- 1. CONSTANTES DE TIEMPO Y RELOJ (Ajustado a PYNQ-Z2)
    -- =============================================================
    constant CLK_FREQ_HZ     : integer := 125_000_000; -- 125 MHz
    
    -- Tiempo de Visualización (5 segundos según PDF pág. 4)
    -- NOTA: Para simular en Vivado, cambia esto a 100 o 1000.
    constant TIMEOUT_5S_CYC  : integer := 5 * CLK_FREQ_HZ; 
    
    -- Filtro de Botones (20ms)
    constant DEBOUNCE_CYC    : integer := 2_500_000;

    -- =============================================================
    -- 2. REGLAS DEL JUEGO (PDF pág. 3)
    -- =============================================================
    constant MIN_PLAYERS : integer := 2;
    constant MAX_PLAYERS : integer := 4;
    constant MAX_PIEDRAS : integer := 3; 
    constant MAX_APUESTA : integer := MAX_PLAYERS * MAX_PIEDRAS; -- 12

    -- =============================================================
    -- 3. TIPOS DE DATOS
    -- =============================================================
    -- Array para guardar datos de los 4 jugadores
    type t_player_array is array (1 to MAX_PLAYERS) of integer range 0 to 15;

    -- =============================================================
    -- 4. CÓDIGOS DE DISPLAY (BINARIO PURO)(5 bits, sin reutilizaciones)
    -- =============================================================
    -- Mapa de caracteres de 4 bits para el display_manager.
    -- Ajustado para cubrir: JUG, ch, AP, GA, Fin, Err, C.
    
    -- Números 0-9 (Directos)
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

    -- Letras Especiales (Mapeadas a los huecos 10-15)
    constant CHAR_A : std_logic_vector(4 downto 0) := "01010"; -- para "AP" y 10 en Hexadecimal
    constant CHAR_b : std_logic_vector(4 downto 0) := "01011"; -- para 11 en Hexadecimal
    constant CHAR_C : std_logic_vector(4 downto 0) := "01100"; -- para "C"=Confirmación y 12 en Hexadecimal
    constant CHAR_F : std_logic_vector(4 downto 0) := "01101"; -- para "FIn"
    constant CHAR_h : std_logic_vector(4 downto 0) := "01110"; -- para "ch"
    constant CHAR_J : std_logic_vector(4 downto 0) := "01111"; -- para "JUG"
    constant CHAR_G : std_logic_vector(4 downto 0) := "10000"; -- para "JUG"
    constant CHAR_P : std_logic_vector(4 downto 0) := "10001"; -- para "AP"
    constant CHAR_U : std_logic_vector(4 downto 0) := "10010"; -- para "JUG"
    constant CHAR_E : std_logic_vector(4 downto 0) := "10011"; -- para "E"=Error
    constant CHAR_Cmin : std_logic_vector(4 downto 0) := "10100"; -- para "ch"
    constant CHAR_n : std_logic_vector(4 downto 0) := "10101"; -- para "FIn"
    constant CHAR_I : std_logic_vector(4 downto 0) := "10110"; -- para "FIn"

    constant CHAR_BLANK : std_logic_vector(4 downto 0) := "11111";  -- caracter de " " 

    -- Mensajes Predefinidos (Helpers) para hacer el código más limpio
    -- Ejemplo: "Err "
    constant MSG_ERR : std_logic_vector(19 downto 0) := CHAR_E & CHAR_E & CHAR_E & CHAR_E; -- Ojo con blank

    -- =============================================================
    -- 5. DISPLAY 7 SEGMENTOS 
    -- =============================================================
    
    -- Control de los segmentos a,b,c,d,e,f,g (7)
    -- Números 0-12 (Directos), activos en baja

    constant SEG_0  :  std_logic_vector(6 downto 0) := "0000001";
    constant SEG_1  :  std_logic_vector(6 downto 0) := "1001111";
    constant SEG_2  :  std_logic_vector(6 downto 0) := "0010010";   
    constant SEG_3  :  std_logic_vector(6 downto 0) := "0000110";
    constant SEG_4  :  std_logic_vector(6 downto 0) := "1001100";
    constant SEG_5  :  std_logic_vector(6 downto 0) := "0100100";
    constant SEG_6  :  std_logic_vector(6 downto 0) := "0100000";
    constant SEG_7  :  std_logic_vector(6 downto 0) := "0001111";
    constant SEG_8  :  std_logic_vector(6 downto 0) := "0000000";
    constant SEG_9  :  std_logic_vector(6 downto 0) := "0000100";
   

    constant SEG_BLANK  :  std_logic_vector(6 downto 0) := "1111110"; -- valor nulo 


    constant SEG_A : std_logic_vector(6 downto 0) := "0001000"; --Hexadecimal(10)
    constant SEG_b : std_logic_vector(6 downto 0) := "1100000"; --Hexadecimal(11)
    constant SEG_C : std_logic_vector(6 downto 0) := "0110001"; --Hexadecimal(12)
    constant SEG_F : std_logic_vector(6 downto 0) := "0111000";
    constant SEG_h : std_logic_vector(6 downto 0) := "1101000";
    constant SEG_J : std_logic_vector(6 downto 0) := "1000011";
    constant SEG_G : std_logic_vector(6 downto 0) := "0100000";
    constant SEG_P : std_logic_vector(6 downto 0) := "0011000";
    constant SEG_U : std_logic_vector(6 downto 0) := "1000001"; 
    constant SEG_E : std_logic_vector(6 downto 0) := "0110000";
    constant SEG_Cmin : std_logic_vector(6 downto 0) := "1110010";
    constant SEG_n : std_logic_vector(6 downto 0) := "1101010";
    constant SEG_I : std_logic_vector(6 downto 0) := "1001111";

end package pkg_chinchimoni;

package body pkg_chinchimoni is
end package body;