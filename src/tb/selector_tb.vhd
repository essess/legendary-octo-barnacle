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

entity selector_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of selector_tb is

  signal clk, srst, source_ready, sink_ready, give, take, valid : std_logic;

  signal dbgsig : std_logic := '0';
  signal tstcnt : integer := 0;

  constant VAL_LOW  : integer := 0;
  constant VAL_HIGH : integer := 1;
  signal value : integer range VAL_LOW to VAL_HIGH;

begin

  CreateReset( Reset => srst,
               ResetActive => '1',
               Clk => clk,
               Period => 1*tclk,
               tpd => tclk/2 );

  CreateClock( Clk  => clk,
               Period => tclk );

  dut : entity work.selector
    generic map( VAL_LOW  => VAL_LOW,
                 VAL_HIGH => VAL_HIGH,
                 TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,

              source_valid_in => valid,
              source_ready_in => source_ready,
              source_take_out => take,

              sink_ready_in  => sink_ready,
              sink_give_out  => give,
              value_out      => value );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    -- verify backpressure works as expected

    --<< drive
    --   initial conditions
    valid        <= '0';
    source_ready <= '0';
    sink_ready   <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_LOW;             --< invalid, but present (and should be initial value)
--  assert give = don't care;
--  assert take = don't care;
    tstcnt <= tstcnt +1;

    --<< drive
    valid        <= '1';
    source_ready <= '0';
    sink_ready   <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_LOW;             --< NOW VALID (and should be initial value)
    assert give = '1';                  --< sink isn't ready, but should still try to give anyways
    assert take = '0';                  --< take not needed on initial value (this is a combinational path)
    tstcnt <= tstcnt +1;

    --<< drive
    valid        <= '1';
    source_ready <= '1';
    sink_ready   <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_LOW;             --< still initial value (unable to advance -- sink still !ready)
    assert give = '1';                  --<
    assert take = '0';                  --< take not needed on initial value (this is a combinational path)
    tstcnt <= tstcnt +1;

    --<< drive
    valid        <= '1';
    source_ready <= '1';
    sink_ready   <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_HIGH;            --< advance
    assert give = '1';                  --<
    assert take = '1';                  --< need to take because this is final value in sequence
    tstcnt <= tstcnt +1;

    --<< drive
    valid        <= '1';
    source_ready <= '0';
    sink_ready   <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_HIGH;            --< hold on last value, because source isn't ready to advance
    assert give = '0';                  --< because source not ready to advance yet SEE selector.vhd NOTE!
    assert take = '1';                  --< still try to take regardless
    tstcnt <= tstcnt +1;

    --<< drive
    valid        <= '1';
    source_ready <= '1';
    sink_ready   <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert value = VAL_LOW;             --< rolled over correctly?
    assert give = '1';                  --<
    assert take = '0';                  --<
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;