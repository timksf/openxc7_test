library ieee;
use ieee.std_logic_1164.all;

entity blink_top is
    port(
        clk : in std_logic;
        led : out std_logic_vector(1 downto 0);
        rgb : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of blink_top is
begin

    blink_inst : entity work.blink
    generic map(
        s => led'length
    )
    port map(
        clk => clk,
        led => led
    );

    breathing_inst : entity work.breathing
    generic map(
        channels => rgb'length
    )
    port map(
        clk => clk,
        led => rgb
    );

end architecture;