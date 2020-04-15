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

entity sym_to_chip_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of sym_to_chip_tb is

  signal clk, srst, source_ready_in, sink_ready_in, give, take, valid_in, valid_out : std_logic;
  signal symbol : std_logic_vector(0 to 3);
  signal chip_chunk : std_logic_vector(0 to 7);

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

  dut : entity work.sym_to_chip
    generic map( TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,

              source_ready_in => source_ready_in,
              source_valid_in => valid_in,
              source_take_out => take,
              symbol_in       => symbol,

              sink_ready_in   => sink_ready_in,
              sink_valid_out  => valid_out,
              sink_give_out   => give,
              chip_chunk_out  => chip_chunk );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --<< drive
    --   initial conditions
    symbol <= b"0000";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"11011001";  --< 0 to 7
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   advance by one chunk
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"11000011";  --< 8 to 15
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   drive valid_in inactive and verify hold
    symbol <= b"0000";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"11000011";  --< 8 to 15 (held, but invalid)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   drive sink_ready inactive and verify hold
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"11000011";  --< 8 to 15 (held and valid)
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   advance by one chunk
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"01010010";  --< 16 to 23
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   advance to last chunk
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"00101110";  --< 24 to 31
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '1';
    tstcnt <= tstcnt +1;

    -- repeat hold tests above

    --<< drive
    --   drive valid_in inactive and verify hold
    symbol <= b"0000";
    valid_in <= '0';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"00101110";  --< 24 to 31 (held, but invalid)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   drive sink_ready inactive and verify hold
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"00101110";  --< 24 to 31 (held and valid)
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   one more, but the source isn't ready
    symbol <= b"0000";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"00101110";  --< 24 to 31 (held and valid)
    assert valid_out = valid_in;
    assert give = '0';
    assert take = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   advance to first chunk of next symbol
    symbol <= b"0001";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"10001100";  --< 0 to 7
    assert valid_out = valid_in;
    assert give = '1';
    assert take = '0';
    tstcnt <= tstcnt +1;

    -- verify rest of chips if desired ...

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;