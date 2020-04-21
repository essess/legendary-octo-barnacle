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

entity chip_to_dig_qpsk_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of chip_to_dig_qpsk_tb is

  signal clk, srst, take, valid_in, source_ready : std_logic;
  signal i, i_give, i_sink_ready, i_valid_out : std_logic;
  signal q, q_give, q_sink_ready, q_valid_out : std_logic;
  signal chip : std_logic_vector(7 downto 0);

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

  dut : entity work.chip_to_dig_qpsk
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,

              source_ready_in => source_ready,
              source_valid_in => valid_in,
              source_take_out => take,
              chip_in         => chip,

              I_sink_ready_in  => i_sink_ready,
              I_sink_valid_out => i_valid_out,
              I_sink_give_out  => i_give,
              I_out            => i,

              Q_sink_ready_in  => q_sink_ready,
              Q_sink_valid_out => q_valid_out,
              Q_sink_give_out  => q_give,
              Q_out            => q );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --<< drive
    --   initial conditions
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '0';
    source_ready <= '1';
    i_sink_ready <= '1';
    q_sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    -- assert i = don't care;
    -- assert q = don't care;
    assert i_valid_out = valid_in;
    assert q_valid_out = valid_in;
    -- assert give = don't care;
    -- assert take = don't care;
    tstcnt <= tstcnt +1;

    --<< drive
    --   iq sample zero
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '0';
    q_sink_ready <= '0';    --< don't advance output just yet
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert take = '0';
    assert i_valid_out = valid_in;
    assert i = '1';
    assert i_give = '1';
    assert q_valid_out = valid_in;
    assert q = '1';
    assert q_give = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   iq sample one
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '1';
    q_sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert take = '0';
    assert i_valid_out = valid_in;
    assert i = '0';
    assert i_give = '1';
    assert q_valid_out = valid_in;
    assert q = '1';
    assert q_give = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   iq sample two
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '1';
    q_sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert take = '0';
    assert i_valid_out = valid_in;
    assert i = '1';
    assert i_give = '1';
    assert q_valid_out = valid_in;
    assert q = '0';
    assert q_give = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   iq sample three/final
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '1';
    q_sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert take = '1';
    assert i_valid_out = valid_in;
    assert i = '0';
    assert i_give = '1';
    assert q_valid_out = valid_in;
    assert q = '0';
    assert q_give = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   iq sample one - repeat?
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '1';
    q_sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert take = '0';
    assert i_valid_out = valid_in;
    assert i = '1';
    assert i_give = '1';
    assert q_valid_out = valid_in;
    assert q = '1';
    assert q_give = '1';
    tstcnt <= tstcnt +1;

    -- verify i/q_sink_ready_in and i/q_give_out operations
    -- the sample zero hold above hints to this special case that
    -- doesn't strictly adhere to default selector operation.

    --<< drive
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '0';              --< anytime ready_in is in disagreement ...
    q_sink_ready <= '1';              --  then give is driven low. Consider the case
    wait until rising_edge( clk );    --  where I is rdy, and Q isn't but give is still
    -->> verify                       --  asserted for both paths. I expects the sample
    wait until falling_edge( clk );   --  to advance on the next clock whereas Q expects
    assert take = '0';                --  it to hold the current value
    assert i_valid_out = valid_in;
    assert i_give = '0';
    assert q_valid_out = valid_in;
    assert q_give = '0';
    assert i = '1';                   --< last value held? (!)
    assert q = '1';                   --< last value held? (!)
    tstcnt <= tstcnt +1;

    --<< drive
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '1';              --< anytime ready_in is in disagreement ...
    q_sink_ready <= '0';              --  then give is driven low. Consider the case
    wait until rising_edge( clk );    --  where I is rdy, and Q isn't but give is still
    -->> verify                       --  asserted for both paths. I expects the sample
    wait until falling_edge( clk );   --  to advance on the next clock whereas Q expects
    assert take = '0';                --  it to hold the current value
    assert i_valid_out = valid_in;
    assert i_give = '0';
    assert q_valid_out = valid_in;
    assert q_give = '0';
    assert i = '1';                   --< last value held? (!)
    assert q = '1';                   --< last value held? (!)
    tstcnt <= tstcnt +1;

    --<< drive
    chip <= b"00_01_10_11"; -- msb -> lsb !!
    valid_in     <= '1';
    source_ready <= '1';
    i_sink_ready <= '0';              --< anytime ready_in is in disagreement ...
    q_sink_ready <= '0';              --  then give is driven low. Consider the case
    wait until rising_edge( clk );    --  where I is rdy, and Q isn't but give is still
    -->> verify                       --  asserted for both paths. I expects the sample
    wait until falling_edge( clk );   --  to advance on the next clock whereas Q expects
    assert take = '0';                --  it to hold the current value
    assert i_valid_out = valid_in;
    assert i_give = '1';              --< special case where both readys are in agreement!
    assert q_valid_out = valid_in;
    assert q_give = '1';              --< special case where both readys are in agreement!
    assert i = '1';                   --< last value held? (!)
    assert q = '1';                   --< last value held? (!)
    tstcnt <= tstcnt +1;


    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;