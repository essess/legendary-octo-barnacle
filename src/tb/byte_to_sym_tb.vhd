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

library osvvm;
  context osvvm.osvvmcontext;

entity byte_to_sym_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := tclk/5 );
end entity;

architecture dfault of byte_to_sym_tb is
begin

  dut : byte_to_sym
    generic map( TPD => TPD )
    port map( clk_in  => '0',
              srst_in => '0' );

  test : process
  begin
    report "TEST_CONSTANT : " & to_string(TEST_CONSTANT);
    -- nothing yet
    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;