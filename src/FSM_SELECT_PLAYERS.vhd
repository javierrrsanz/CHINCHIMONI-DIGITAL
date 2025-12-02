library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- IMPORTANTE: Usamos el paquete adaptado
use work.pkg_chinchimoni.ALL;

entity FSM_SELECT_PLAYERS is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        
        -- Control (Estandarizado)
        start      : in  std_logic; -- Antes INIT_FASE
        done       : out std_logic; -- Antes FIN_FASE
        
        -- Hardware
        confirm    : in  std_logic; -- Botón limpio (tick)
        switches   : in  std_logic_vector(3 downto 0);
        
        -- Timer
        timer_start: out std_logic;
        timeout_5s : in  std_logic;
        
        -- Salidas
        players_out: out std_logic_vector(2 downto 0); -- A Datapath
        disp_code  : out std_logic_vector(15 downto 0) -- A Display Manager (16 bits)
    );
end FSM_SELECT_PLAYERS;

architecture Behavioral of FSM_SELECT_PLAYERS is
<<<<<<< HEAD
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
  signal sw_value : unsigned(3 downto 0);

begin

  -- Switches a unsigned para trabajar comodo
  sw_value <= unsigned(switches);

  FSM_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S_INIT;
  
      else
        case state is
  
          when S_INIT =>
            if INIT_FASE = '1' then
              state <= S_WAIT_CONFIRM;
            else
              state <= S_INIT;
            end if;
          
          when S_WAIT_CONFIRM => 
            -- Falta asignar disp_code
            if confirm = '1' then
              state <= S_CHECK;
            else    
              state <= S_WAIT_CONFIRM;
            end if;

          when S_CHECK => 
            if (sw_value = 2) or (sw_value = 3) or (sw_value = 4) then
              state <= S_SHOW_OK;
            else
              state <= S_ERROR;
            end if;

          when S_ERROR =>
            -- disp_code  <= "ERR_CODE";
            if timeout_5s = '1' then
              state <= S_WAIT_CONFIRM;
            end if;
          
            when S_SHOW_OK =>
            -- disp_code  <= " ";
            if timeout_5s = '1' then
              state <= S_DONE;
            end if;
            
            when S_DONE =>
              FIN_FASE <= '1';
              state <= S_INIT;
              --disp_code <= "OK";
        -- quedarse aquí o pasar a otro módulo
              
  
        end case;
  
      end if;
    end if;
  end process;
  
  -- Logi
  
end architecture;
