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

entity byte_to_sym_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of byte_to_sym_tb is

  signal clk, srst, source_ready_in, sink_ready_in, sink_give_out, source_take_out, valid_in, valid_out : std_logic;
  signal byte_in : std_logic_vector(7 downto 0);
  signal symbol_out : std_logic_vector(3 downto 0);

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

  dut : entity work.byte_to_sym
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,

              source_ready_in => source_ready_in,
              source_valid_in => valid_in,
              source_take_out => source_take_out,
              byte_in         => byte_in,

              sink_ready_in   => sink_ready_in,
              sink_valid_out  => valid_out,
              sink_give_out   => sink_give_out,
              symbol_out      => symbol_out );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --[ brute force through manual vectors ]--

    --<< drive
    --   initial conditions
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --[ start walking through state machine ]--

    --<< drive
    --   HOLD 000 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 001 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 010 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 011 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 100 (is valid, sink !rdy, src !rdy)
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 101 (is valid, sink !rdy, src rdy)
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --[ advance to upper -> lower -> upper ]--

    --<< drive
    --   ADVANCE to upper 111
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '1';
    assert source_take_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   ADVANCE to lower 111
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);
    assert valid_out = valid_in;
    assert sink_give_out = '1';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   ADVANCE to upper 111
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '1';
    assert source_take_out = '1';
    tstcnt <= tstcnt +1;

    --[ now go through same HOLD checks while on upper ]--

    --<< drive
    --   HOLD 000 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 001 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 010 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 011 (source is invalid)
    byte_in <= x"AB";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 100 (is valid, sink !rdy, src !rdy)
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 101 (is valid, sink !rdy, src rdy)
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --[ if sink is ready, but source isn't (and we're on upper nibble) then HOLD upper ]--

    --<< drive
    --   HOLD 110 on upper because source isn't ready to advance yet
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --[ go back to lower and do the same thing ]--

    --<< drive
    --   advance to lower
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(3 downto 0);
    assert valid_out = valid_in;
    assert sink_give_out = '1';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   repeat source not ready, but should still advance
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   and then should stay on upper
    byte_in <= x"AB";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol_out = byte_in(7 downto 4);
    assert valid_out = valid_in;
    assert sink_give_out = '0';
    assert source_take_out = '0';
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;