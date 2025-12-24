library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity segmentos is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        disp_code : in  std_logic_vector(15 downto 0);

        segments : out std_logic_vector(7 downto 0);
        selector : out std_logic_vector(3 downto 0)
    );
end segmentos;


architecture Behavioral of segmentos is

    ----------------------------------------------------------------
    -- Refresco: 4 kHz multiplexado → ~1 kHz por display
    ----------------------------------------------------------------
    constant TICK_MAX : integer := 31250 - 1;  -- 125 MHz / 4000

    signal tick_cnt     : integer range 0 to TICK_MAX := 0;
    signal tick_refresh : std_logic := '0';

    signal digit_sel    : unsigned(1 downto 0) := (others => '0');
    signal current_char : std_logic_vector(3 downto 0);

    -- Patrón de segmentos ACTIVO-BAJO
    signal seg_pat : std_logic_vector(6 downto 0);



    begin

    ----------------------------------------------------------------
    -- 1) Generación de tick de refresco, para evitar que parpadee
    ----------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            tick_cnt     <= 0;
            tick_refresh <= '0';
        elsif rising_edge(clk) then
            if tick_cnt = TICK_MAX then
                tick_cnt     <= 0;
                tick_refresh <= '1';
            else
                tick_cnt     <= tick_cnt + 1;
                tick_refresh <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- 2) Contador de display activo
    ----------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            digit_sel <= (others => '0');
        elsif rising_edge(clk) then
            if tick_refresh = '1' then
                digit_sel <= digit_sel + 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- 3) Selector y nibble activo
    ----------------------------------------------------------------
    process(digit_sel, disp_code)
    begin
        case digit_sel is
            when "00" =>
                selector     <= "0001";
                current_char <= disp_code(3 downto 0);

            when "01" =>
                selector     <= "0010";
                current_char <= disp_code(7 downto 4);

            when "10" =>
                selector     <= "0100";
                current_char <= disp_code(11 downto 8);

            when others =>
                selector     <= "1000";
                current_char <= disp_code(15 downto 12);
        end case;
    end process;

     ----------------------------------------------------------------
    -- 4) Decoder nibble → segmentos
    ----------------------------------------------------------------
    process(current_char)
    begin
        case current_char is
            when "0000" => seg_pat <= NUM_0;
            when "0001" => seg_pat <= NUM_1;
            when "0010" => seg_pat <= NUM_2;
            when "0011" => seg_pat <= NUM_3;
            when "0100" => seg_pat <= NUM_4;
            when "0101" => seg_pat <= NUM_5;
            when "0110" => seg_pat <= NUM_6;
            when "0111" => seg_pat <= NUM_7;
            when "1000" => seg_pat <= NUM_8;
            when "1001" => seg_pat <= NUM_9;
            when "1010" => seg_pat <= NUM_10;
            when "1011" => seg_pat <= NUM_11;
            when "1100" => seg_pat <= NUM_12;
            when others => seg_pat <= BLANK;
        end case;
    end process;

    ----------------------------------------------------------------
    -- 5) Salida final
    ----------------------------------------------------------------
    segments <= '1' & seg_pat;  -- dp apagado (dp=punto decimal, no lo usamos y por tanto lo fijamos a 1)

end Behavioral;