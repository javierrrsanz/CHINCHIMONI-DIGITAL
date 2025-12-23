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
    -- 4. CÓDIGOS DE DISPLAY (BINARIO PURO)
    -- =============================================================
    -- Mapa de caracteres de 4 bits para el display_manager.
    -- Ajustado para cubrir: JUG, ch, AP, GA, Fin, Err, C.
    
    -- Números 0-9 (Directos)
    constant CHAR_0 : std_logic_vector(3 downto 0) := "0000"; -- También sirve para 'O'
    constant CHAR_1 : std_logic_vector(3 downto 0) := "0001"; -- También sirve para 'I'
    constant CHAR_2 : std_logic_vector(3 downto 0) := "0010";
    constant CHAR_3 : std_logic_vector(3 downto 0) := "0011";
    constant CHAR_4 : std_logic_vector(3 downto 0) := "0100";
    constant CHAR_5 : std_logic_vector(3 downto 0) := "0101"; -- También sirve para 'S'
    constant CHAR_6 : std_logic_vector(3 downto 0) := "0110"; -- También sirve para 'G' (GA, JUG)
    constant CHAR_7 : std_logic_vector(3 downto 0) := "0111";
    constant CHAR_8 : std_logic_vector(3 downto 0) := "1000";
    constant CHAR_9 : std_logic_vector(3 downto 0) := "1001";

    -- Letras Especiales (Mapeadas a los huecos 10-15)
    constant CHAR_A : std_logic_vector(3 downto 0) := "1010"; -- Para "AP" y "10"
    constant CHAR_C : std_logic_vector(3 downto 0) := "1011"; -- Para "ch" y "Confirm" y "11"
    constant CHAR_E : std_logic_vector(3 downto 0) := "1100"; -- Para "Err" y "12"
    constant CHAR_F : std_logic_vector(3 downto 0) := "1101"; -- Para "Fin" y "P" (AP)
    constant CHAR_H : std_logic_vector(3 downto 0) := "1110"; -- Para "ch" 
    constant CHAR_J : std_logic_vector(3 downto 0) := "1111"; -- Para "JUG" 
    
    -- Alias para facilitar la lectura del código en las FSMs
    constant CHAR_G : std_logic_vector(3 downto 0) := CHAR_6; -- Reutilizamos el 6
    constant CHAR_I : std_logic_vector(3 downto 0) := CHAR_1; -- Reutilizamos el 1
    constant CHAR_P : std_logic_vector(3 downto 0) := CHAR_F; -- Reutilizamos la F
    constant CHAR_U : std_logic_vector(3 downto 0) := CHAR_0; -- Reutilizamos el 0 (o V si tuvieramos)
    constant CHAR_BLANK : std_logic_vector(3 downto 0) := "1111"; -- J y Blank comparten slot si es necesario, o definimos apagado en lógica.
    
    -- Mensajes Predefinidos (Helpers) para hacer el código más limpio
    -- Ejemplo: "Err "
    constant MSG_ERR : std_logic_vector(15 downto 0) := CHAR_E & CHAR_E & CHAR_E & CHAR_E; -- Ojo con blank

    -- =============================================================
    -- 5. DISPLAY 7 SEGMENTOS ()
    -- =============================================================
    
    -- Control de los segmentos a,b,c,d,e,f,g (7)
    -- Números 0-12 (Directos)

    constant NUM_0  :  std_logic_vector(8 downto 0) := "1111110":
    constant NUM_1  :  std_logic_vector(8 downto 0) := "0110000":
    constant NUM_2  :  std_logic_vector(8 downto 0) := "1101101";
    constant NUM_3  :  std_logic_vector(8 downto 0) := "1111001";
    constant NUM_4  :  std_logic_vector(8 downto 0) := "0110011";
    constant NUM_5  :  std_logic_vector(8 downto 0) := "1011011";
    constant NUM_6  :  std_logic_vector(8 downto 0) := "1011111";
    constant NUM_7  :  std_logic_vector(8 downto 0) := "1110000";
    constant NUM_8  :  std_logic_vector(8 downto 0) := "1111111";
    constant NUM_9  :  std_logic_vector(8 downto 0) := "1111011";
    constant NUM_10 :  std_logic_vector(8 downto 0) := "1110111"; -- Hexadecimal(A)
    constant NUM_11 :  std_logic_vector(8 downto 0) := "0011111"; -- Hexadecimal(b)
    constant NUM_12 :  std_logic_vector(8 downto 0) := "1001110"; -- Hexadecimal(C)
   



end package pkg_chinchimoni;

package body pkg_chinchimoni is
end package body;