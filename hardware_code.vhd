--FSM
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity fsm is    
   Port (
   
        i_rst   : in std_logic;
        i_clk   : in std_logic;
        i_start : in std_logic;
        
        --alto una volta finita la lettura della sequenza
        i_stop : in std_logic;
        
        --segnale alto, quando il valore letto in memoria è zero
        i_value_is_zero: in std_logic;
        
        --segnale per inizializzare le componenti
        init: out std_logic;
        
        --segnali per i contatori
        en_count_k: out std_logic;
        en_count_addr:  out std_logic;
        on_count_k: out std_logic;
        on_count_addr: out std_logic;
        
        --segnali per i registri
        load_reg_val: out std_logic;
        load_reg_cre: out std_logic;
        
        --mutex 
        sel_mux: out std_logic;
        
        --segnali per lettura e scrittura in memoria
        o_mem_en: out std_logic;
        o_mem_we: out std_logic;
        
        --segnale fine elaborazione
        o_done: out std_logic
        );
end fsm;

architecture Behavioral of fsm is
    type S is (s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10);
    signal current_state: S;
begin
    status: process(i_clk,i_rst,current_state)
        begin
        if i_rst='1' then
            current_state<=s0;
        elsif  i_clk = '1' and i_clk'event  then
            case current_state is 
                when s0 =>
                  if i_start='1' then
                    current_state<=s1;
                  end if;
                when s1 =>                --setup counter
                    current_state<=s2;
                when s2 =>                --inizio lettura
                    current_state<=s3;
                when s3 =>                --stato attesa lettura
                    current_state<=s4;
                when s4 =>                --setup registri  e attivazione counter_k
                    if i_value_is_zero='1' then   
                       current_state<=s5;
                    else
                       current_state<=s7; --se il valore letto è diverso da zero, si procede con la scrittura della credibilità
                    end if;   
                when s5 =>                --inizio scrittura del valore
                    current_state<=s6;
                when s6 =>                --stato attesa scrittura
                    current_state<=s7;   
                when s7 =>                --inizio scrittura credibilità
                    current_state<=s8;
                when s8 =>                --stato attesa scrittura 
                    if i_stop='1' then    --controllo se la sequenza è finiti
                      current_state<=s9;
                    else 
                      current_state<=s10;
                    end if;
                when s10 =>              --attivazione dell'incrementatore per il calcolo dell'indirizzo successivo
                    current_state<=s2;
                when s9 =>               --stato di fine elaborazione
                     if i_start='0' then
                        current_state<=s0;
                     end if;
             end case;            
        end if;          
        end process;
    output : process(current_state)
    begin
        
        en_count_k<='0';
        en_count_addr<='0';
        
        on_count_k<='0';
        on_count_addr<='0';
        
        load_reg_val<='0';
        load_reg_cre<='0';
        
        sel_mux<='0';
       
        
        o_mem_en<='0';
        o_mem_we<='0';
        
        o_done<='0';
        
        init<='0';
        
        case current_state is
            when s0 =>
                init<='1';
            when s1 =>  
                en_count_k<='1';
                en_count_addr<='1';   
            when s2=> 
                o_mem_en<='1';
            when s3=>
                o_mem_en<='1';
            when s4=>
                on_count_k<='1';
                load_reg_val<='1';
                load_reg_cre<='1';
            when s5 =>
                o_mem_en<='1';
                o_mem_we<='1';       
            when s6=>
                o_mem_en<='1';
                o_mem_we<='1';
            when s7 =>
                o_mem_en<='1';
                o_mem_we<='1';
                sel_mux<='1';      
            when s8 =>
                o_mem_en<='1';
                o_mem_we<='1';
                sel_mux<='1';
            when s10 =>
                on_count_addr<='1';
            when s9 =>
                o_done<='1';
                
                
        end case;    

    
    end process;


end Behavioral;

--COUNTER ADDRESS,componente che calcola l'indirizzo base

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_address is
    Port (i_add: in std_logic_vector(15 downto 0);
          i_clk: in std_logic; 
          i_rst: in std_logic;
          en_counter: in std_logic;
          on_counter: in std_logic;
          init:in std_logic;
          addr: out std_logic_vector(15 downto 0)
          );
end counter_address;

architecture Behavioral of counter_address is
   signal current_address: std_logic_vector(15 downto 0);
begin
   process(i_clk,i_rst,en_counter,on_counter,init)
   begin
   if i_rst='1' or init='1' then
     current_address <= (others => '0');
     elsif i_clk='1' and i_clk'event then
        if  en_counter='1' then
            current_address<=i_add;
        elsif on_counter='1' then
            current_address<=std_logic_vector(unsigned(current_address) + 2);
        end if;
   end if;
   
   end process;
   
   addr<=current_address;
   
end Behavioral;

--SELETTORE, che in base ai valori in ingresso decide le cifre successive per il valore e credibilità 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity selector is
    Port (
        i_clk: in std_logic;
        i_rst: in std_logic;
        i_value_reg: in std_logic_vector(7 downto 0);
        i_credibility_reg: in std_logic_vector(7 downto 0);
        i_mem_data: in std_logic_vector(7 downto 0);
        init: in std_logic;
        o_value_is_zero: out std_logic;
        o_value_register: out std_logic_vector(7 downto 0);
        o_credibility_register: out std_logic_vector(7 downto 0)
    );
end selector;

architecture Behavioral of selector is

signal value: std_logic_vector(7 downto 0);
signal cre: std_logic_vector(7 downto 0);

begin
    process(i_clk,init,i_rst)
    begin
    if i_rst='1' or init='1' then
    value<= (others => '0');
    cre<= (others => '0');
    o_value_is_zero<='0';
    elsif(i_clk='1'and i_clk'event ) then
        if i_mem_data="00000000" then
            value <= i_value_reg;
            if i_credibility_reg = "00000000" then 
                    cre <= (others => '0');
                    else
                        cre<= std_logic_vector(unsigned(i_credibility_reg) - 1); 
                end if;
            o_value_is_zero<='1'; 
        else 
            o_value_is_zero<='0';
            cre<= "00011111";
            value<= i_mem_data;   
        end if;
    end if;
    end process;
    o_value_register<=value;
    o_credibility_register<=cre;
end Behavioral;

--COUNTER K(stop)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_k is
  Port (i_clk: in std_logic;
        i_rst: in std_logic;
        en_count_k: in std_logic;
        on_count_K: in std_logic; 
        i_k: in std_logic_vector(9 downto 0 );
        init: in std_logic;
        o_stop: out std_logic
        --current_count : out std_logic_vector(9 downto 0)
        );
end counter_k;

architecture Behavioral of counter_k is
signal current_state: std_logic_vector (9 downto 0);  
signal k_minus_one: std_logic_vector (9 downto 0); 
begin
    process(i_clk, i_rst,en_count_k,on_count_K,init)
       begin
       if i_rst ='1' or init='1' then
            current_state<=(others => '0');
            o_stop<='0';
            k_minus_one<=(others => '0');
       elsif i_clk='1' and i_clk'event then
            if en_count_k='1' then
                current_state<=(others => '0');
                k_minus_one<=std_logic_vector(unsigned(i_k) - 1);
                o_stop<='0';
            elsif on_count_k='1' then
                if k_minus_one = current_state then
                   o_stop<='1';
                else
                   current_state<=std_logic_vector(unsigned(current_state) + 1);
                end if;
            end if;
       end if;
       end process;

end Behavioral;

--8 BIT REGISTER VAL, registro per il valore
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity reg_8_val is
    Port (
    i_val: in std_logic_vector(7 downto 0);
    i_load: in std_logic;   
    i_rst: in std_logic; 
    i_clk: in std_logic;  
    init: in std_logic;
    o_reg_val: out std_logic_vector(7 downto 0)
     );
end reg_8_val;

architecture Behavioral of reg_8_val is
signal reg_value: std_logic_vector(7 downto 0);
begin
    process(i_rst, i_clk, i_load,init)
    begin
        if i_rst='1' or init='1' then
           reg_value<=(others => '0');
        elsif i_clk='1' and i_clk'event and i_load='1' then
           reg_value<= i_val;
        end if;
    end process;
    
o_reg_val<=reg_value;

end Behavioral;

--8 BIT REGISTRER CRE, registro per la credibilità
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reg_8_cre is
    Port (
    i_val: in std_logic_vector(7 downto 0);
    i_load: in std_logic;   
    i_rst: in std_logic; 
    i_clk: in std_logic;  
    init: in std_logic;
    o_reg_val: out std_logic_vector(7 downto 0)
     );
end reg_8_cre;

architecture Behavioral of reg_8_cre is
signal reg_value: std_logic_vector(7 downto 0);
begin
    process(i_rst, i_clk, i_load,init)
    begin
        if i_rst='1' or init='1' then
           reg_value<=(others => '0');
        elsif i_clk='1' and i_clk'event and i_load='1' then
           reg_value<= i_val;
        end if;
    end process;
    
o_reg_val<=reg_value;

end Behavioral;

--ADDER (+8), sommattore per il calcolo dell'indirizzo della credibilità
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder is
  Port (val_addr : in std_logic_vector(15 downto 0);
        cre_addr : out std_logic_vector(15 downto 0) );
end adder;

architecture Behavioral of adder is
begin
    cre_addr<= std_logic_vector(unsigned(val_addr) + 1);
end Behavioral;

--selettore per il dato in uscita verso la memoria

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity mux_data is
    Port( 
    sel: in std_logic;
    a: in std_logic_vector(7 downto 0);      
    b: in std_logic_vector(7 downto 0);
    c: out std_logic_vector(7 downto 0) 
    );
end mux_data;

architecture Behavioral of mux_data is

begin

  with sel select
    c <= a when '0',
               b when '1',
    (others => '-') when others;

end Behavioral;

--selettore per l'indirizzo di lettura/scrittura

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity mux_addr is
    Port( 
    sel: in std_logic;
    a: in std_logic_vector(15 downto 0);      
    b: in std_logic_vector(15 downto 0);
    c: out std_logic_vector(15 downto 0) 
    );
end mux_addr;

architecture Behavioral of mux_addr is

begin

  
  with sel select
    c <= a when '0',
               b when '1',
    (others => '-') when others;

end Behavioral;


--TOP MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity project_reti_logiche is
    Port (
        i_clk: in std_logic;
        i_rst: in std_logic;
        i_start: in std_logic;
        i_k: in std_logic_vector(9 downto 0);
        i_add: in std_logic_vector(15 downto 0);

        o_done: out std_logic;

        o_mem_addr: out std_logic_vector(15 downto 0);
        i_mem_data: in std_logic_vector(7 downto 0);
        o_mem_data: out std_logic_vector(7 downto 0);
        o_mem_we: out std_logic;
        o_mem_en: out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
--componenti :
    component fsm is 
        Port(
        i_rst   : in std_logic;
        i_clk   : in std_logic;
        i_start : in std_logic;
        i_stop : in std_logic;
        
        i_value_is_zero: in std_logic;
        
        init: out std_logic;
        
        en_count_k: out std_logic;
        en_count_addr:  out std_logic;
        on_count_k: out std_logic;
        on_count_addr: out std_logic;
        
        load_reg_val: out std_logic;
        load_reg_cre: out std_logic;

        sel_mux: out std_logic;

        o_mem_en: out std_logic;
        o_mem_we: out std_logic;
        
        o_done: out std_logic
        );
        end component;
        
        component counter_address is
        Port (
          i_add: in std_logic_vector(15 downto 0);
          i_clk: in std_logic; 
          i_rst: in std_logic;
          en_counter: in std_logic;
          on_counter: in std_logic;
          init: in std_logic;
          addr: out std_logic_vector(15 downto 0)
          );
        end component;
        
        component selector is
        Port (
        i_clk: in std_logic;
        i_rst: in std_logic;
        i_value_reg: in std_logic_vector(7 downto 0);
        i_credibility_reg: in std_logic_vector(7 downto 0);
        i_mem_data: in std_logic_vector(7 downto 0);
        init: in std_logic;
        o_value_is_zero: out std_logic;
        o_value_register: out std_logic_vector(7 downto 0);
        o_credibility_register: out std_logic_vector(7 downto 0)
        );
        end component;
        
        component counter_k is
        Port (
        i_clk: in std_logic;
        i_rst: in std_logic;
        en_count_k: in std_logic;
        on_count_K: in std_logic; 
        i_k: in std_logic_vector(9 downto 0 );
        init: in std_logic;
        o_stop: out std_logic
        );
        end component;
        
        component reg_8_val is
        Port (
        i_val: in std_logic_vector(7 downto 0);
        i_load: in std_logic;   
        i_rst: in std_logic; 
        i_clk: in std_logic;  
        init: in std_logic;
        o_reg_val: out std_logic_vector(7 downto 0)
        );
        end component;
        
        component reg_8_cre is
        Port (
        i_val: in std_logic_vector(7 downto 0);
        i_load: in std_logic;   
        i_rst: in std_logic; 
        i_clk: in std_logic;  
        init: in std_logic;
        o_reg_val: out std_logic_vector(7 downto 0)
        );
        end component;
        
        component adder is
        Port (
        val_addr : in std_logic_vector(15 downto 0);
        cre_addr : out std_logic_vector(15 downto 0) );
        end component;
        
        component mux_data is
        Port( 
        sel: in std_logic;
        a: in std_logic_vector(7 downto 0);      
        b: in std_logic_vector(7 downto 0);
        c: out std_logic_vector(7 downto 0) 
        );
        end component;
        
        component mux_addr is
        Port( 
        sel: in std_logic;
        a: in std_logic_vector(15 downto 0);      
        b: in std_logic_vector(15 downto 0);
        c: out std_logic_vector(15 downto 0) 
        );
        end component;

    signal en_count_k: std_logic;
    signal en_count_addr: std_logic;
    
    signal on_addr: std_logic;
    signal on_k: std_logic;
    
    signal load_reg_value: std_logic;
    signal load_reg_credibility: std_logic;
    
    signal sel_mux: std_logic;
    
    signal end_count: std_logic;
    
    
    signal value_is_zero: std_logic;
    
    signal value_push: std_logic_vector(7 downto 0);--in entrata da reg
    signal value_pop: std_logic_vector(7 downto 0);--in uscita da reg
    signal credibility_push: std_logic_vector(7 downto 0);
    signal credibility_pop: std_logic_vector(7 downto 0);

    signal value_address: std_logic_vector(15 downto 0);--in uscita da address counter
    signal credibility_address: std_logic_vector(15 downto 0);--in uscita dall'adder
    
    signal init:  std_logic;
    
    

--port mapping per ogni componente:
    
begin
    s_sel :  selector  port map (i_clk => i_clk,
        i_rst => i_rst,
        i_value_reg => value_pop,
        i_credibility_reg => credibility_pop,
        i_mem_data => i_mem_data,
        init=>init,
        o_value_register => value_push,
        o_credibility_register => credibility_push,
        o_value_is_zero=>value_is_zero);
    s_adder : adder port map(
        val_addr => value_address,
        cre_addr => credibility_address
    );
    s_counter_address : counter_address port map (
          i_add=>i_add,
          i_clk=> i_clk, 
          i_rst=> i_rst,
          en_counter => en_count_addr,
          on_counter => on_addr, 
          init=>init,         
          addr => value_address 
     );
     s_counter_k : counter_k port map (
          i_clk=>i_clk,
          i_rst=>i_rst,
          en_count_k=>en_count_k,
          on_count_K=>on_k, 
          i_k=>i_k,
          init=>init,
          o_stop=>end_count
     );
     s_fsm : fsm port map (
          i_clk=>i_clk,
          i_rst=>i_rst,
          i_start => i_start,
          i_stop =>end_count, 
          
          i_value_is_zero=> value_is_zero,
          
          init=>init,
          
          en_count_k=>en_count_k,
          en_count_addr=> en_count_addr,
          on_count_k=>on_k, 
          on_count_addr => on_addr,
        

          load_reg_val=>load_reg_value,
          load_reg_cre=> load_reg_credibility,

          sel_mux=>sel_mux,
        
          o_mem_en=>o_mem_en,
          o_mem_we=>o_mem_we,
          o_done=>o_done
     );
     s_mux_addr : mux_addr port map (
          sel=>sel_mux,
          a=>value_address,
          b=>credibility_address,
          c=>o_mem_addr     
          );
     s_mux_data : mux_data port map (
          sel=>sel_mux,
          a=>value_pop,
          b=>credibility_pop,
          c=>o_mem_data     
          );
     s_reg_8_cre : reg_8_cre port map(
          i_val=>credibility_push,
          i_load=>load_reg_credibility,
          i_rst=>i_rst,
          i_clk=> i_clk,
          init=>init,
          o_reg_val=>credibility_pop
     );
     s_reg_8_val : reg_8_val port map(
          i_val=>value_push,
          i_load=>load_reg_value,
          i_rst=>i_rst,
          i_clk=> i_clk,
          init=>init,
          o_reg_val=>value_pop
     );
     

end Behavioral;
