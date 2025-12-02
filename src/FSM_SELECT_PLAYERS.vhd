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

  -- Proceso sincrono para actualizar estado
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        current_state <= S_INIT;
      else
        current_state <= next_state;
      end if;
    end if;
  end process;
  -- Logi
end architecture;
