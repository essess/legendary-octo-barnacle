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

entity oct_to_sym_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of oct_to_sym_tb is

  signal clk, srst, sink_ready, source_ready, give, take, valid_in, valid_out : std_logic;
  signal octet : std_logic_vector(0 to 7);
  signal symbol : std_logic_vector(0 to 3);

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

  dut : entity work.oct_to_sym
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              sink_ready_in => sink_ready,
              sink_valid_in => valid_in,
              sink_take_out => take,
              octet_in      => octet,
              source_ready_in  => source_ready,
              source_valid_out => valid_out,
              source_give_out  => give,
              symbol_out       => symbol );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --[ brute force through manual vectors ]--

    --<< drive
    --   initial conditions
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '0';
    source_ready <= '0';
    sink_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --[ start walking through state machine ]--

    --<< drive
    --   HOLD 000 (sink is invalid)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '0';
    source_ready <= '0';
    sink_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 001 (sink is invalid)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '0';
    source_ready <= '0';
    sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 010 (sink is invalid)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '0';
    source_ready <= '1';
    sink_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 011 (sink is invalid)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '0';
    source_ready <= '1';
    sink_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 100 (is valid, source !rdy, sink !rdy)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '1';
    source_ready <= '0';
    sink_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 101 (is valid, source !rdy, sink rdy)
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --[ advance to upper -> lower -> upper ]--

    --<< drive
    --   ADVANCE to upper 111
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   ADVANCE to lower 111
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   ADVANCE to upper 111
    octet <= b"1101_0101";             --< (0xAB lsb to msb // reads as 0xD5 in GTKWave)
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --[ now go through same HOLD checks while on upper ]--

    --<< drive
    --   HOLD 000 (sink is invalid)
    octet <= b"1101_0101";
    valid_in <= '0';
    sink_ready <= '0';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 001 (sink is invalid)
    octet <= b"1101_0101";
    valid_in <= '0';
    sink_ready <= '0';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 010 (sink is invalid)
    octet <= b"1101_0101";
    valid_in <= '0';
    sink_ready <= '1';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);  --< (not considered valid - but present)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 011 (sink is invalid)
    octet <= b"1101_0101";
    valid_in <= '0';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 100 (is valid, source !rdy, sink !rdy)
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '0';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   HOLD 101 (is valid, source !rdy, sink rdy)
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --[ if source is ready, but sink isn't (and we're on upper nibble) then HOLD upper ]--

    --<< drive
    --   HOLD 110 on upper because sink isn't ready to advance yet
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '0';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --[ go back to lower and do the same thing ]--

    --<< drive
    --   advance to lower
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '1';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(0 to 3);
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   repeat sink not ready, but should still advance
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '0';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   and then should stay on upper
    octet <= b"1101_0101";
    valid_in <= '1';
    sink_ready <= '0';
    source_ready <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert symbol = octet(4 to 7);
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '1';
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;