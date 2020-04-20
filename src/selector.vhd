---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@gmail.com>
 -- Refer to license terms in LICENSE; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;
--  work.phy_pkg.all;

---
 -- (SELECTOR) - like a commutator or up counter- 'commutates' as
 -- long as flow control allows it.
 --
 -- Wrapup a simple up counter that abides by backpressure rules
 -- (while also controlling give/take/valid) and as such, makes a
 -- good automated selector signal for other blocks. Mealy outputs
 -- allow easy integration with other combinational items, like
 -- muxes.
 --
 -- see sm_tables.xlsx/.pdf for more information
 --
---

entity selector is
  generic( VAL_LOW  : integer range 0 to integer'high := 0;
           VAL_HIGH : integer range 1 to integer'high := integer'high;
           TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        source_valid_in : in std_logic;       --< ready/take/give qualifier
        source_ready_in : in std_logic;
        source_take_out : out std_logic;

        sink_ready_in   : in  std_logic;
        sink_give_out   : out std_logic;
        value_out   : out positive range VAL_LOW to VAL_HIGH
      );
end entity;

architecture dfault of selector is

  signal take, give : std_logic;
  signal value, next_value : integer range VAL_LOW to VAL_HIGH;

begin

  -- value state ----
  -------(value)  --< out
  process(clk_in) --< in
  begin
    if rising_edge(clk_in) then
      value <= VAL_LOW when srst_in = '1' else next_value;
    end if;
  end process;

  -- value combinational --------------------------------------------
  -------(give, take, next_value)                                 --< out
  process(source_valid_in, source_ready_in, sink_ready_in, value) --< in
    variable inputs : std_logic_vector(2 downto 0);
    variable last : std_logic;
  begin --< literal translation of selector table in sm_tables.xlsx/.pdf :
    if source_valid_in = '1' then
      last   := '1' when (value = VAL_HIGH) else '0';
      inputs := (source_ready_in, sink_ready_in, last);
      case inputs is
        when "110" | "010" =>           --< next
          take <= '0';
          give <= '1';
          next_value <= value +1;
        when "100" | "000" | "101"  =>  --< hold
          take <= '0';
          give <= '1';
          next_value <= value;
        when "001" =>                   --< hold
          take <= '1';
          give <= '0';
          next_value <= value;
        when "011" =>                   --< hold
          take <= '1';
          give <= '0';
          next_value <= value;
        when others => -- "111"         --< next
          take <= '1';
          give <= '1';
          next_value <= 0;
      end case;
    else
      take <= '0';
      give <= '0';
      next_value <= value;
    end if;
  end process;

  -- drive ------------------------------------
  source_take_out <= take  after TPD;
  sink_give_out   <= give  after TPD;
  value_out       <= value after TPD;

end architecture;