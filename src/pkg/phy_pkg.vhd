---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@gmail.com>
 -- Refer to license terms in LICENSE; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

package phy_pkg is
  -- nothing yet
  constant TEST_CONSTANT : integer := 8675309;

  component byte_to_sym is
    generic( TPD : time := 0 ns );
    port( clk_in  : in std_logic;
          srst_in : in std_logic );
  end component;

end package;

package body phy_pkg is
  -- nothing yet
end package body;