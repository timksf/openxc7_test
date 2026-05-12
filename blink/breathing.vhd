library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity breathing is
    generic(
        channels   : positive range 1 to 3 := 3;
        pwm_bits   : positive := 8;
        step_ticks : positive := 96000
    );
    port(
        clk : in std_logic;
        led : out std_logic_vector(channels-1 downto 0)
    );
end entity;

architecture rtl of breathing is
    constant max_brightness_c : unsigned(pwm_bits-1 downto 0) := (others => '1');

    signal pwm_counter_q : unsigned(pwm_bits-1 downto 0) := (others => '0');
    signal brightness_q  : unsigned(pwm_bits-1 downto 0) := (others => '0');
    signal ramp_up_q     : std_logic := '1';
begin

    process(clk)
        variable step_counter_v : integer range 0 to step_ticks - 1 := 0;
    begin
        if(rising_edge(clk)) then
            pwm_counter_q <= pwm_counter_q + 1;

            if(step_counter_v = step_ticks - 1) then
                step_counter_v := 0;

                if(ramp_up_q = '1') then
                    if(brightness_q = max_brightness_c) then
                        ramp_up_q <= '0';
                        brightness_q <= brightness_q - 1;
                    else
                        brightness_q <= brightness_q + 1;
                    end if;
                else
                    if(brightness_q = 0) then
                        ramp_up_q <= '1';
                        brightness_q <= brightness_q + 1;
                    else
                        brightness_q <= brightness_q - 1;
                    end if;
                end if;
            else
                step_counter_v := step_counter_v + 1;
            end if;
        end if;
    end process;

    led <= (others => '1') when pwm_counter_q < brightness_q else (others => '0');

end architecture;