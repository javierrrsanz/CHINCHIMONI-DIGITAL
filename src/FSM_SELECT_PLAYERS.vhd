library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity FSM_SELECT_PLAYERS is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Control
        start       : in  std_logic;
        done        : out std_logic;
        
        -- Hardware
        confirm     : in  std_logic; -- Botón (pulso)
        switches    : in  std_logic_vector(3 downto 0);
        
        -- Timer
        timer_start : out std_logic;
        timeout_5s  : in  std_logic;
        
        -- Salidas
        we_players_out  : out std_logic;
        players_out     : out std_logic_vector(2 downto 0);
        disp_code       : out std_logic_vector(19 downto 0)
    );
end FSM_SELECT_PLAYERS;

architecture Behavioral of FSM_SELECT_PLAYERS is

    type state_type is (
      S_INIT,
      S_WAIT_CONFIRM,
      S_CHECK,
      S_ERROR,
      S_SHOW_OK,
      S_DONE
    );
    signal state : state_type;

    -- Valor de switches
    signal num_jugadores : unsigned(4 downto 0);
    signal players_reg   : std_logic_vector(4 downto 0);

begin
    -- Switches a unsigned para trabajar comodo
    num_jugadores <= '0' & unsigned(switches); --relleno con 0s a la izquierda

    FSM_PROC : process(clk,reset)
  begin
      if reset = '1' then
        state <= S_INIT;
        players_reg   <= (others => '0');

      elsif clk 'event and clk='1' then
        case state is
  
          when S_INIT =>
            if start = '1' then
              state <= S_WAIT_CONFIRM;
            else
              state <= S_INIT;
            end if;
          
          when S_WAIT_CONFIRM => 
            if confirm = '1' then
              state <= S_CHECK;
            else    
              state <= S_WAIT_CONFIRM;
            end if;

          when S_CHECK => 
            if (num_jugadores >= MIN_PLAYERS and num_jugadores <= MAX_PLAYERS) then
              state  <= S_SHOW_OK;
              players_reg <= std_logic_vector(num_jugadores(4 downto 0));
            else
              state  <= S_ERROR;
            end if;

          when S_ERROR =>
            if timeout_5s = '1' then
              state <= S_WAIT_CONFIRM;
            end if;
          
            when S_SHOW_OK =>
            if timeout_5s = '1' then
              state <= S_DONE;
            end if;
            
            when S_DONE =>
              state <= S_INIT;
            end case;
      end if;
  end process;

  -- Logica combinacional salidas
  we_players_out <= '1' when state = S_DONE else '0';

  players_out <= players_reg(2 downto 0); -- En algun momento habria que volver a poner a 0

  timer_start <= '1' when state = S_CHECK else '0';

  done <= '1' when state = S_DONE else '0';

  with state select
    disp_code <=  CHAR_J & CHAR_U & CHAR_G & std_logic_vector(num_jugadores) when S_WAIT_CONFIRM, -- Aqui muestra switches
                  CHAR_J & CHAR_U & CHAR_G & players_reg when S_SHOW_OK, -- Aqui muestra registro
                  CHAR_J & CHAR_U & CHAR_G & CHAR_BLANK when S_ERROR,
                  CHAR_BLANK & CHAR_BLANK & CHAR_BLANK & CHAR_BLANK when others;

end Behavioral;