library ieee;
use ieee.std_logic_1164.all;

entity blink is
    generic(
        s   : positive range 1 to 3 := 3;
        top : positive := 1000000 
    );
    port(
        sysclk: in std_logic;
        led: out std_logic_vector(s-1 downto 0)
    );
end entity;

architecture rtl of blink is
    signal led_q : std_logic_vector(s-1 downto 0) := "101";
begin

    process(sysclk)
        variable cnt_v : integer range 0 to top := 0;
    begin
        if(rising_edge(sysclk)) then
            if(cnt_v = top) then
                cnt_v := 0;
                led_q <= not led_q;
            else
                cnt_v := cnt_v + 1;
            end if;
        end if;
    end process;

    led <= led_q;

end architecture;