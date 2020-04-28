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

library osvvm;
  context osvvm.osvvmcontext;

entity top_tb is
  generic( tclk : time := 250 ns;     --< 4Msamp/sec
           TPD  : time := 0  ns );
end entity;

architecture dfault of top_tb is

  signal clk, srst, sink_ready, i_source_ready, q_source_ready, i_give, q_give, take, valid_in, i_valid_out, q_valid_out : std_logic;
  signal byte : std_logic_vector(7 downto 0);
  signal i_sample, q_sample : signed(15 downto 0);

  signal dbgsig : std_logic := '0';
  signal tstcnt : integer := 0;

begin

  CreateReset( Reset => srst,
               ResetActive => '1',
               Clk => clk,
               Period => 1*tclk,
               tpd => tclk/2 );

  CreateClock( Clk  => clk,
               Period => tclk );

  dut : entity work.top
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              sink_valid_in => valid_in,
              sink_ready_in => sink_ready,
              sink_take_out => take,
              byte_in       => byte,
              i_source_valid_out => i_valid_out,
              i_source_ready_in  => i_source_ready,
              i_source_give_out  => i_give,
              i_sample_out       => i_sample,
              q_source_valid_out => q_valid_out,
              q_source_ready_in  => q_source_ready,
              q_source_give_out  => q_give,
              q_sample_out       => q_sample );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --<< drive
    --   initial conditions
    valid_in       <= '0';
    sink_ready     <= '0';
    i_source_ready <= '0';
    q_source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert i_valid_out = valid_in;
    assert q_valid_out = valid_in;
--  assert give = don't care;
--  assert take = don't care;
    tstcnt <= tstcnt +1;

    -- --<< drive
    byte           <= x"00";
    valid_in       <= '1';
    sink_ready     <= '1';
    i_source_ready <= '1';
    q_source_ready <= '1';
    -- wait until rising_edge( clk );
    -- -->> verify
    -- wait until falling_edge( clk );
    -- TODO(?)
    -- tstcnt <= tstcnt +1;

    wait for 384*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;