library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.numeric_std.all;

entity FSM_SELECT_PLAYERS is

  port (clk        : in  std_logic;
        reset      : in  std_logic;
        confirm    : in  std_logic;
        switches   : in  std_logic_vector(3 downto 0);
        timeout_5s : in  std_logic;
        INIT_FASE  : in  std_logic;

        disp_code  : out std_logic_vector(7 downto 0);
        players    : out std_logic_vector(1 downto 0);
        FIN_FASE   : out std_logic;
        start_5s   : out std_logic);

end entity;

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
