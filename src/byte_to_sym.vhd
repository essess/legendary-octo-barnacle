---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@gmail.com>
 -- Refer to license terms in LICENSE; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all,
    work.phy_pkg.all;

---
 -- (BYTE)s (TO) (SYM)bols
 --
 -- According to the 802.15.4 OQPSK phy section, this is simply
 -- the act of peeling off nibbles starting at the LSN (12.2.3)
---

entity byte_to_sym is
  generic( TPD : time := 0 ns );
  port( clk_in  : in std_logic;
        srst_in : in std_logic );
end entity;

architecture dfault of byte_to_sym is

begin
  assert TEST_CONSTANT = 8675309;

  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if srst_in = '1' then
        -- nothing yet
      else
        -- nothing yet
      end if;
    end if;
  end process;

end architecture;