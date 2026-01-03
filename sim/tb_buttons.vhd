library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity buttons_tb is
end buttons_tb;

architecture Behavioral of buttons_tb is

    -- Componente con TUS nombres de puertos
    component buttons
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            in_continuar  : in  std_logic;
            in_confirmar  : in  std_logic;
            in_reinicio   : in  std_logic;
            out_continuar : out std_logic;
            out_confirmar : out std_logic;
            out_reinicio  : out std_logic
        );
    end component;

    -- Señales para conectar la UUT
    signal clk           : std_logic;
    signal reset         : std_logic;
    signal in_continuar  : std_logic;
    signal in_confirmar  : std_logic;
    signal in_reinicio   : std_logic;
    signal out_continuar : std_logic;
    signal out_confirmar : std_logic;
    signal out_reinicio :  std_logic;

    constant clk_period : time := 8 ns; -- 125 MHz

begin

    -- Instancia de la unidad bajo prueba (UUT)
    uut: buttons port map (
        clk           => clk,
        reset         => reset,
        in_continuar  => in_continuar,
        in_confirmar  => in_confirmar,
        in_reinicio   => in_reinicio,
        out_continuar => out_continuar,
        out_confirmar => out_confirmar,
        out_reinicio  => out_reinicio
    );

    -- Proceso del reloj
    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Proceso de estímulos
    stim_proc: process
    begin		
      -- hold reset state for 100 ns.
		reset <= '1';
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 100 ns;
		reset <= '0';
		wait for 1 ms;
	 
		-- Rebotes por ruido
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 100 us;
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 20 us;
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 10 us;
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 2 ms;
	 
		-- Pulsación correcta
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 100 us;
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 20 us;
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 2 ms;
    
		-- Rebotes al dejar de pulsar el botón
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 10 us;
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 10 us;
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 10 us;
		in_continuar <= '1';
		in_reinicio <= '1';
		in_confirmar <= '1';
		wait for 10 us;
		in_continuar <= '0';
		in_reinicio <= '0';
		in_confirmar <= '0';
		wait for 2 ms;

      wait;
		