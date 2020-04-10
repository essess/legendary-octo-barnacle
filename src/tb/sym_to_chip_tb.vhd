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

  signal clk, srst, source_ready_in, sink_ready_in, sink_give_out, source_take_out, valid_in, valid_out : std_logic;
  signal symbol_in : std_logic_vector(0 to 3);
  signal chip_out : std_logic_vector(0 to 31);

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
              source_take_out => source_take_out,
              symbol_in       => symbol_in,

              sink_ready_in   => sink_ready_in,
              sink_valid_out  => valid_out,
              sink_give_out   => sink_give_out,
              chip_out        => chip_out );

  test : process
  begin

    WaitForLevel( srst, '0' );
    wait until falling_edge( clk );

    --<< drive
    --   initial conditions
    symbol_in <= b"0000";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";
    assert valid_out = valid_in;
    assert sink_give_out = source_ready_in;
    assert source_take_out = sink_ready_in;
    tstcnt <= tstcnt +1;

    -- since this is a purely combinational block (and control signals
    -- are passed through) just check that sym<->chips are correct

    --<< drive
    --   symbol 1
    symbol_in <= b"1000";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11101101100111000011010100100010";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 2
    symbol_in <= b"0100";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00101110110110011100001101010010";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 3
    symbol_in <= b"1100";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00100010111011011001110000110101";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 4
    symbol_in <= b"0010";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01010010001011101101100111000011";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 5
    symbol_in <= b"1010";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00110101001000101110110110011100";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 6
    symbol_in <= b"0110";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11000011010100100010111011011001";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 7
    symbol_in <= b"1110";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10011100001101010010001011101101";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 8
    symbol_in <= b"0001";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10001100100101100000011101111011";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 9
    symbol_in <= b"1001";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10111000110010010110000001110111";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 10
    symbol_in <= b"0101";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01111011100011001001011000000111";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 11
    symbol_in <= b"1101";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01110111101110001100100101100000";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 12
    symbol_in <= b"0011";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00000111011110111000110010010110";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 13
    symbol_in <= b"1011";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01100000011101111011100011001001";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 14
    symbol_in <= b"0111";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10010110000001110111101110001100";  --< VALID
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 15
    symbol_in <= b"1111";
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11001001011000000111011110111000";  --< VALID
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;