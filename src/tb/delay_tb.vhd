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

entity delay_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of delay_tb is

  signal clk, srst, sink_ready, source_ready, give, take, valid_in, valid_out : std_logic;
  signal sample_in, sample_out : signed(15 downto 0);

  constant N : integer := 3;
  constant INITIAL_VALUE : signed(sample_in'range) := to_signed(1234, sample_in'length);

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

  dut : entity work.delay
    generic map( N => N,
                 INITIAL_VALUE => INITIAL_VALUE,
                 TPD => TPD )
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
    valid_in     <= '0';
    sink_ready   <= '0';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert valid_out = valid_in;
    assert sample_out = INITIAL_VALUE;  --< invalid, but present anyways
--  assert give = don't care;
--  assert take = don't care;
    tstcnt <= tstcnt +1;

    --<< drive
    valid_in     <= '1';
    sink_ready   <= '1';
    source_ready <= '1';
    -- wait until rising_edge( clk );
    -- -->> verify
    -- wait until falling_edge( clk );
    -- TODO
    -- tstcnt <= tstcnt +1;

    wait for 20*tclk;
    report "DONE"; std.env.stop;
  end process;

  smpgen : process(clk)
    variable smpcnt : integer := 0;
  begin
    sample_in <= to_signed(smpcnt, sample_in'length);
    if rising_edge(clk) then
      smpcnt := smpcnt +1;
    end if;
  end process;

end architecture;