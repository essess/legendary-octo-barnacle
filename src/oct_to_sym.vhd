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
 -- (OCT)ets (TO) (SYM)bols
 --
 -- According to the 802.15.4 OQPSK phy section, this is simply the act
 -- of peeling off nibbles starting at the LSB (12.2.3)
 --
 -- There is a catch though,
 -- The standard decides to use LSB->MSB bit ordering which is why (a to b)
 -- std_logic_vector's are used here. It will 'read' naturally (as depicted
 -- in the standard) but is valued differently. Anything that wraps this
 -- will probably want to pay attention to reversing the bits since it's
 -- likely that a byte input will actually be (7 downto 0) in form. This is
 -- also why the term octet is used here (to mirror the standard better).
 --
 -- see sm_tables.xlsx/.pdf for more information
---

entity oct_to_sym is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        source_valid_in : in std_logic;                 --< octet is valid        \
        source_ready_in : in std_logic;                 --< octet is available     |__ SOURCE input
        source_take_out : out std_logic;                --< take octet             |
        octet_in        : in std_logic_vector(0 to 7);  --< octet                 /

        sink_valid_out  : out std_logic;                --< symbol is valid       \
        sink_ready_in   : in  std_logic;                --< sink ready to accept   |__ SINK output
        sink_give_out   : out std_logic;                --< give symbol            |
        symbol_out      : out std_logic_vector(0 to 3)  --< symbol                /
      );
end entity;

architecture dfault of oct_to_sym is

  signal valid, take, give : std_logic;

  constant VAL_LOW  : integer := 0;
  constant VAL_HIGH : integer := 1;
  signal selection : integer range VAL_LOW to VAL_HIGH;

begin

  selector_inst : entity work.selector
    generic map ( VAL_LOW  => VAL_LOW,
                  VAL_HIGH => VAL_HIGH )
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              source_valid_in => source_valid_in,
              source_ready_in => source_ready_in,
              source_take_out => take,
              sink_ready_in  => sink_ready_in,
              sink_give_out  => give,
              value_out      => selection );

  -- drive ------------------------------------
  sink_valid_out  <= source_valid_in after TPD;
  source_take_out <= take after TPD;
  sink_give_out   <= give after TPD;
  symbol_out      <= octet_in(0 to 3) after TPD when selection = VAL_LOW else
                     octet_in(4 to 7) after TPD;

end architecture;