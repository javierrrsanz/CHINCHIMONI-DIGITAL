library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity debouncer_tb is
--  Port ( );
end debouncer_tb;

architecture Behavioral of debouncer_tb is
-- Component Declaration for the Unit Under Test (UUT)
    COMPONENT debouncer
    PORT(
         clk : IN  std_logic;
		 reset	: in std_logic;	
         boton : IN  std_logic;
         filtrado : OUT  std_logic
        );
    END COMPONENT;
    
   --Inputs
   signal clk : std_logic := '0';
   signal boton : std_logic := '0';

 	--Outputs
   signal filtrado : std_logic;
	signal reset : std_logic;

   -- Clock period definitions
   constant clk_period : time := 8 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: debouncer PORT MAP (
          clk => clk,
		  reset => reset,
          boton => boton,
          filtrado => filtrado
   );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		reset <= '1';
		boton <= '0';
		wait for 1 ms;
		reset <= '0';
		wait for 10 ms;
	 
		-- Rebotes por ruido
		boton <= '1';
		wait for 1 ms;
		boton <= '0';
		wait for 2 ms;
		boton <= '1';
		wait for 3 ms;
		boton <= '0';
		wait for 10 ms;
	 
		-- Pulsación correcta
		boton <= '1';
		wait for 25 ms;
		boton <= '0';
		wait for 10 ms;
		boton <= '1';
		wait for 25 ms;
    
		-- Rebotes al dejar de pulsar el botón
		boton <= '0';
		wait for 1 ms;
		boton <= '1';
		wait for 5 ms;
		boton <= '0';
		wait for 1 ms;
		boton <= '1';
		wait for 2 ms;
		boton <= '0';
		wait for 2 ms;

      wait;
		
   end process;


end Behavioral;



