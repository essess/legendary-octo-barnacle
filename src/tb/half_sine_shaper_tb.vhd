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

entity half_sine_shaper_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of half_sine_shaper_tb is

  signal clk, srst, sink_ready, source_ready, give, take, valid_in, valid_out : std_logic;
  signal sample_in : std_logic;
  signal sample, sample_out : signed(15 downto 0);

  signal dbgsig : std_logic := '0';
  signal tstcnt : integer := 0;

begin

  CreateReset( Reset => srst,
               ResetActive => '1',
               Clk => clk,
               Period => 1*tclk,
               tpd => tclk/2 );

  CreateClock( Clk => clk,
               Period => tclk );

  dut : entity work.half_sine_shaper
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              sink_valid_in => valid_in,
              sink_ready_in => sink_ready,
              sink_take_out => take,
              sample_in     => sample_in,
              source_valid_out => valid_out,
              source_ready_in  => source_ready,
              source_give_out  => give,
              sample_out       => sample_out );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --<< drive
    --   initial conditions
    sample_in <= '1';
    valid_in <= '0';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
--  assert sample_out = don't care;
    assert valid_out = valid_in;
--  assert source_give_out = don't care;
--  assert sink_take_out = don't care;
    tstcnt <= tstcnt +1;

    --<< drive
    --   brute force a few sine cycles (positive going to start)
    valid_in <= '1';
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= not sample_in;
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= not sample_in;
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= not sample_in;
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= not sample_in;
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= not sample_in;
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   --- run a few samples pos
    wait until falling_edge( clk );
    sample_in <= '1';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= '1';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= '1';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   --- run a few samples neg
    wait until falling_edge( clk );
    sample_in <= '0';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= '0';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= '0';
    tstcnt <= tstcnt +1;
    wait until falling_edge( take );   ---
    wait until falling_edge( clk );
    sample_in <= '0';
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

  process(clk)
  begin
    -- take samples out and 'clean them up'
    -- as the DAC would capture them
    if rising_edge(clk) then
      if srst = '1' then
        sample <= to_signed(0, sample'length);
      elsif valid_out = '1' and give = '1' then
        sample <= sample_out;
      else
        sample <= sample;
      end if;
    end if;
  end process;

end architecture;