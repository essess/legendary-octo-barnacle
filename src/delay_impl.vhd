library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity delay_impl is
  Generic (
    dataWidth   : integer;
    LENGTH      : integer );
  Port (
    clk         : in std_logic;
    reset       : in std_logic;
    input       : in std_logic_vector((dataWidth - 1) downto 0);
    input_vld   : in std_logic;
    output      : out std_logic_vector((dataWidth - 1) downto 0);
    output_vld  : out std_logic );
end delay_impl;

architecture Behavioral of delay_impl is

    type buffer_t is array (0 to (LENGTH - 1)) of std_logic_vector((dataWidth - 1) downto 0);
    signal databuffer : buffer_t;

begin

process(clk)   
begin
    if rising_edge(clk) then
        if (reset = '1') then
            databuffer <= (others => (others => '0'));
            output <= (others => '0');
            output_vld <= '0';
        elsif (input_vld = '1') then
            output <= databuffer(LENGTH - 1);
            output_vld <= '1';
            for i in 0 to (LENGTH - 2) loop 
                databuffer((LENGTH - 1) - i) <= databuffer((LENGTH - 2) - i);
            end loop;  
            databuffer(0) <= input;
        else
            output_vld <= '0';
        end if;
    end if;    
end process;

end Behavioral;

