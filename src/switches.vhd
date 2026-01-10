library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;

entity input_mux is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- Control IA
        ai_extract_req : in  std_logic;
        ai_bet_req     : in  std_logic;
        ai_decision    : in  integer range 0 to MAX_APUESTA;
        decision_done  : in  std_logic;

        -- Entradas humanas
        switches_human : in  std_logic_vector(3 downto 0);
        confirm_human  : in  std_logic;

        -- Salidas multiplexadas
        switches_mux   : out std_logic_vector(3 downto 0);
        confirm_mux    : out std_logic
    );
end input_mux;

architecture Behavioral of input_mux is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                switches_mux <= (others => '0');
                confirm_mux  <= '0';
            else
                -- Modo IA activo
                if (ai_extract_req = '1' or ai_bet_req = '1') then
                    switches_mux <= std_logic_vector(to_unsigned(ai_decision, 4));

                    -- Confirmación SOLO cuando la IA ha terminado
                    if decision_done = '1' then
                        confirm_mux <= '1';
                    else
                        confirm_mux <= '0';
                    end if;

                -- Modo humano
                else
                    switches_mux <= switches_human;
                    confirm_mux  <= confirm_human;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
