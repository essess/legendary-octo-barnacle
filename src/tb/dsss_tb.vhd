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

entity dsss_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 0  ns );
end entity;

architecture dfault of dsss_tb is

  signal clk, srst, source_ready_in, sink_ready_in, sink_give_out, source_take_out, valid_in, valid_out : std_logic;
  signal byte_in : std_logic_vector(7 downto 0);
  signal chip_chunk : std_logic_vector(7 downto 0);

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

  dut : entity work.dsss
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
              chip_chunk_out  => chip_chunk );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    -- drive a byte (floor it) and check the chips
    -- backpressure already verified in deeper blocks

            --  7  downto 0
    byte_in <= b"0101_1000"; --\
            -- b"0001_1010"  -- \
            --  0   to    7   --  \__ symbols: 8, 5 (in that order)
    --<< drive
    --   initial conditions
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
--  assert chip_chunk = don't care;
    assert valid_out = valid_in;
--  assert sink_give_out = don't care;
--  assert source_take_out = don't care;
    tstcnt <= tstcnt +1;

    --<< drive
    valid_in <= '1';
    --   chip chunk zero of symbol 8
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"0011_0001";
    tstcnt <= tstcnt +1;

    --<< drive
    source_ready_in <= '1';
    sink_ready_in <= '1';
    --   chip chunk one of symbol 8
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"0110_1001";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk two of symbol 8
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"1110_0000";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk three (final) of symbol 8
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"1101_1110";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk zero of symbol 5
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"1010_1100";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk one of symbol 5
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"0100_0100";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk two of symbol 5
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"1011_0111";
    tstcnt <= tstcnt +1;

    --<< drive
    --   chip chunk three (final) of symbol 5
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"0011_1001";
    tstcnt <= tstcnt +1;

    --<< drive
    --   back to chip chunk zero of symbol 8
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_chunk = b"0011_0001";
    tstcnt <= tstcnt +1;

--     -- the rest already verified via oct_to_sym_tb
--     -- this was mostly a sanity check

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;