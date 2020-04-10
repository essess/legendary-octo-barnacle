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

    --[ brute force through manual vectors ]--

    --<< drive
    --   initial conditions
    symbol_in <= b"0000";
    valid_in <= '0';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";  --< (not considered valid - but present)
    assert valid_out = valid_in;
--  assert sink_give_out = don't care;
--  assert source_take_out = don't care;
    tstcnt <= tstcnt +1;

    --<< drive symbol 0 checking the give/take conditions
    --   symbol 0, valid, source !rdy, sink !rdy
    symbol_in <= b"0000";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '0';
    assert sink_give_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 0, valid, source !rdy, sink rdy
    symbol_in <= b"0000";
    valid_in <= '1';
    source_ready_in <= '0';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '0';
    assert sink_give_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 0, valid, source rdy, sink !rdy
    symbol_in <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '0';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '0';
    assert sink_give_out = '0';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 0, valid, source rdy, sink rdy
    symbol_in <= b"0000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11011001110000110101001000101110";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    -- NEXT give/take verified on sym 0, just verify the remaining chips

    --<< drive
    --   symbol 1, valid, source rdy, sink rdy
    symbol_in <= b"1000";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11101101100111000011010100100010";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 2, valid, source rdy, sink rdy
    symbol_in <= b"0100";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00101110110110011100001101010010";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 3, valid, source rdy, sink rdy
    symbol_in <= b"1100";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00100010111011011001110000110101";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 4, valid, source rdy, sink rdy
    symbol_in <= b"0010";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01010010001011101101100111000011";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 5, valid, source rdy, sink rdy
    symbol_in <= b"1010";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00110101001000101110110110011100";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 6, valid, source rdy, sink rdy
    symbol_in <= b"0110";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11000011010100100010111011011001";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 7, valid, source rdy, sink rdy
    symbol_in <= b"1110";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10011100001101010010001011101101";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 8, valid, source rdy, sink rdy
    symbol_in <= b"0001";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10001100100101100000011101111011";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 9, valid, source rdy, sink rdy
    symbol_in <= b"1001";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10111000110010010110000001110111";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 10, valid, source rdy, sink rdy
    symbol_in <= b"0101";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01111011100011001001011000000111";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 11, valid, source rdy, sink rdy
    symbol_in <= b"1101";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01110111101110001100100101100000";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 12, valid, source rdy, sink rdy
    symbol_in <= b"0011";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"00000111011110111000110010010110";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 13, valid, source rdy, sink rdy
    symbol_in <= b"1011";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"01100000011101111011100011001001";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 14, valid, source rdy, sink rdy
    symbol_in <= b"0111";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"10010110000001110111101110001100";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    --<< drive
    --   symbol 15, valid, source rdy, sink rdy
    symbol_in <= b"1111";
    valid_in <= '1';
    source_ready_in <= '1';
    sink_ready_in <= '1';
    wait until rising_edge( clk );
    -->> verify
    wait until falling_edge( clk );
    assert chip_out = b"11001001011000000111011110111000";  --< VALID
    assert valid_out = valid_in;
    assert source_take_out = '1';
    assert sink_give_out = '1';
    tstcnt <= tstcnt +1;

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

end architecture;