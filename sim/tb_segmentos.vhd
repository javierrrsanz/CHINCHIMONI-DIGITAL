--====================================================================
--  Testbench: segmentos_tb.vhd
--  Objetivo : Banco de pruebas sincrono para segmentos.vhd (Vivado)
--             - Genera reloj a 125 MHz (periodo 8 ns)
--             - Aplica y libera reset de forma síncrona
--             - Fuerza disp_code con 4 codigos (4 digitos x 5 bits)
--             - Monitoriza selector/segments y comprueba que coinciden
--
--  NOTA:
--    Tu segmentos.vhd usa disp_code(19 downto 0) en 4 grupos de 5 bits:
--      d0 = disp_code(4 downto 0)    (derecha)
--      d1 = disp_code(9 downto 5)
--      d2 = disp_code(14 downto 10)
--      d3 = disp_code(19 downto 15) (izquierda)
--====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_chinchimoni.ALL;


entity tb_segmentos is
end entity;


architecture tb of tb_segmentos is

    --========================
    -- Parámetros del reloj
    --========================
    constant clk_period : time := 8 ns; -- 125 MHz => 8 ns

    --========================
    -- Señales del DUT (Device Under Test)
    --========================
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';

    -- 20 bits = 4 dígitos * 5 bits por dígito
    signal disp_code : std_logic_vector(19 downto 0) := (others => '1');

    signal segments  : std_logic_vector(7 downto 0);
    signal selector  : std_logic_vector(3 downto 0);

    --========================
    -- Función auxiliar: empaqueta 4 digitos (5 bits cada uno) en disp_code
    -- Como en tu segmentos.vhd:
    --   d0 -> bits  (4 downto 0)  (digito más a la derecha)
    --   d3 -> bits (19 downto 15) (digito más a la izquierda)
    --========================
    function pack4(
        d3 : std_logic_vector(4 downto 0); -- izquierda
        d2 : std_logic_vector(4 downto 0);
        d1 : std_logic_vector(4 downto 0);
        d0 : std_logic_vector(4 downto 0)  -- derecha
    ) return std_logic_vector is
        variable v : std_logic_vector(19 downto 0);
    begin
        v := d3 & d2 & d1 & d0;

        return v;

    end function;

    --========================
    -- Función auxiliar: patron esperado de segments para un codigo de 5 bits
    -- segments es activo en bajo (0 = segmento encendido)
    -- Ademas, el DUT fuerza el punto decimal apagado: segments(7) = '1'
    --========================
    function expected_segments(c : std_logic_vector(4 downto 0)) return std_logic_vector is
        variable s : std_logic_vector(7 downto 0);
    begin
        -- Por defecto: todo apagado (activo-bajo => '1')
        s := (others => '1');

        case c is
            when CHAR_0 => s := '1' & SEG_0;
            when CHAR_1 => s := '1' & SEG_1;
            when CHAR_2 => s := '1' & SEG_2;
            when CHAR_3 => s := '1' & SEG_3;
            when CHAR_4 => s := '1' & SEG_4;
            when CHAR_5 => s := '1' & SEG_5;
            when CHAR_6 => s := '1' & SEG_6;
            when CHAR_7 => s := '1' & SEG_7;
            when CHAR_8 => s := '1' & SEG_8;
            when CHAR_9 => s := '1' & SEG_9;

            when CHAR_A => s := '1' & SEG_A;
            when CHAR_b => s := '1' & SEG_b;
            when CHAR_C => s := '1' & SEG_C;
            when CHAR_F => s := '1' & SEG_F;
            when CHAR_h => s := '1' & SEG_h;
            when CHAR_J => s := '1' & SEG_J;
            when CHAR_G => s := '1' & SEG_G;
            when CHAR_P => s := '1' & SEG_P;
            when CHAR_U => s := '1' & SEG_U;
            when CHAR_E => s := '1' & SEG_E;
            when CHAR_c => s := '1' & SEG_c;
            when CHAR_n => s := '1' & SEG_n;
            when CHAR_I => s := '1' & SEG_I;

            when CHAR_BLANK => s := (others => '1');
            when others     => s := (others => '1');
        end case;

        return s;

    end function;

    --========================
    -- Funcion auxiliar: según selector, devuelve el caracter (5 bits) activo
    -- selector es "one-hot" activo en alto en tu DUT:
    --   "0001" -> digito derecha  -> disp_code(4 downto 0)
    --   "0010" ->                -> disp_code(9 downto 5)
    --   "0100" ->                -> disp_code(14 downto 10)
    --   "1000" -> digito izquierda-> disp_code(19 downto 15)
    --========================
    function char_for_selector(
        sel : std_logic_vector(3 downto 0);
        dc  : std_logic_vector(19 downto 0)
    ) return std_logic_vector is
        variable c : std_logic_vector(4 downto 0);
    begin
        c := (others => '1');

        case sel is
            when "0001" => c := dc(4 downto 0);
            when "0010" => c := dc(9 downto 5);
            when "0100" => c := dc(14 downto 10);
            when "1000" => c := dc(19 downto 15);
            when others => c := CHAR_BLANK;
        end case;

        return c;
    end function;

begin

    --========================
    -- Instancia del DUT
    --========================
    uut: entity work.segmentos
        port map (
            clk       => clk,
            reset     => reset,
            disp_code => disp_code,
            segments  => segments,
            selector  => selector
        );

    --========================
    -- Generador de reloj
    --========================
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    --========================
    -- Estimulos (TODO síncrono)
    -- - mantenemos reset algunos flancos
    -- - liberamos reset en un rising_edge
    -- - cambiamos disp_code siempre en rising_edge
    --========================
    stim_proc : process
    begin
      -- Reset sincrono: activo durante 3 ciclos
        reset <= '1';
        wait for 3*clk_period;
        reset <= '0';

        -- 1) Mostrar "JUG " (izq->der: J U G blanco)
        wait for clk_period;
        disp_code <= pack4(CHAR_J, CHAR_U, CHAR_G, CHAR_BLANK);

        -- Espera suficiente para ver varios refrescos
        -- (tick ~ 250 us y 4 digitos => ~1 ms por ciclo completo)
        for i in 0 to 300000 loop
            wait for clk_period;
        end loop;

        -- 2) Mostrar "ch 2" (c h blanco 2)
        wait for clk_period;
        disp_code <= pack4(CHAR_c, CHAR_h, CHAR_BLANK, CHAR_2);

        for i in 0 to 300000 loop
            wait for clk_period;
        end loop;

        -- 3) Mostrar "AP12" (A P 1 2)
        wait for clk_period;
        disp_code <= pack4(CHAR_A, CHAR_P, CHAR_1, CHAR_2);

        for i in 0 to 300000 loop
            wait for clk_period;
        end loop;

        -- 4) Mostrar "FIn " (F I n blanco)
        wait for clk_period;
        disp_code <= pack4(CHAR_F, CHAR_I, CHAR_n, CHAR_BLANK);

        for i in 0 to 300000 loop
            wait for clk_period;
        end loop;

        -- Fin de simulacion (parada intencionada)
        assert false report "Simulacion finalizada (parada intencionada)." severity failure;

    end process;

    --========================
    -- Comprobador/Monitor (síncrono)
    -- Idea:
    --    Cuando cambia selector, damos 1 ciclo para que se estabilice la salida
    --    Luego comparamos segments con el patron esperado para el digito activo
    --========================
    check_proc : process(clk)
        variable last_sel : std_logic_vector(3 downto 0) := (others => '0');
        variable c        : std_logic_vector(4 downto 0);
        variable exp      : std_logic_vector(7 downto 0);
    begin
         wait for clk_period;

    if reset = '1' then
        last_sel := (others => '0');
    else
        -- DP debe estar apagado
        assert segments(7) = '1'
            report "El bit DP (segments(7)) no esta forzado a '1'."
            severity error;

        -- Evitar comprobar justo cuando cambia selector
        if selector /= last_sel then
            last_sel := selector;
        else
            c   := char_for_selector(selector, disp_code);
            exp := expected_segments(c);

            assert segments = exp
                report "Error en segments. Esperado=" & to_hstring(exp) &
                       " obtenido=" & to_hstring(segments)
                severity error;
        end if;
    end if;
end process;

end architecture;
