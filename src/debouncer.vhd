library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;




entity debouncer is
 Port (
    clk : in std_logic;
    reset : in std_logic;
    boton : in std_logic;
    filtrado : out std_logic);
 end debouncer;

architecture Behavioral of debouncer is
    
    signal Q1,Q2,Q3,nQ3,flanco: std_logic;
    
    constant cont_max: integer := 2500000;
    signal cuenta: integer range 0 to 2500000;
    signal E,T:std_logic;
    
    
    type State_t is (S_Nada, S_Boton );
    signal STATE : State_t;
    
begin
P1:process(clk,reset)
begin
    if (reset='1')then
        Q1<='0';
        Q2<='0';
        Q3<='0';
    elsif (clk' event and clk='1')then
        Q1<=boton;
        Q2<=Q1;
        Q3<=Q2;
    end if;
end process;

nQ3<=not Q3;
flanco<= nQ3 and Q2;

Temp:process(clk,reset)
begin
    if(reset='1') then
        cuenta<=0;
        T<='0';
    elsif (clk' event and clk='1')then
        if (E='1')then
            if(cuenta<cont_max)then
                cuenta<=cuenta+1;
                T<='0';
            else
                cuenta<=0;
                T<='1';
            end if;
        end if;
    end if;
 end process;
            
            
FSM:process(clk,reset)
 begin
 if (reset = '1') then
    STATE <= S_Nada;
 elsif (clk'event and clk = '1') then
    case STATE is
        when S_Nada =>
            if(flanco='1' and T='0') then
                STATE <= S_Boton;
            elsif(flanco='0' and T='0') then
                STATE <= S_Nada;
            end if;
        when S_Boton =>
                if(Q2='1' and T='1') then
                     STATE <= S_Nada;
                elsif(Q2='0' and T='1') then
                    STATE <= S_Nada;
                elsif(T='0')then
                    STATE<=S_Boton;
                end if;    
    end case;
end if;
end process;       
      
E<= '1' when(STATE=S_Boton)else '0';
filtrado<= '1' when(STATE=S_Boton and Q2='1' and T='1')else'0';


    
        

end Behavioral;