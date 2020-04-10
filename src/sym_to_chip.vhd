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

---
 -- (SYM)bols (TO) (CHIP)s
 --
 -- According to the 802.15.4 OQPSK phy section, simply a lookup.
 -- See section 12.2.4, table 12-1
 --
 -- NOTE:
 -- The standard decides to use LSB->MSB bit ordering which is why (a to b)
 -- std_logic_vector's are used here. It will 'read' naturally (as depicted
 -- in the standard) but is valued differently.
 --
 -- purely combinational block
---

entity sym_to_chip is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        source_ready_in : in std_logic;                 --< symbol is available  \
        source_valid_in : in std_logic;                 --< symbol is valid       |__ SOURCE input
        source_take_out : out std_logic;                --< take symbol           |
        symbol_in       : in std_logic_vector(0 to 3);  --< symbol               /

        sink_ready_in   : in  std_logic;                --< sink ready to accept \
        sink_valid_out  : out std_logic;                --< chip is valid         |__ SINK output
        sink_give_out   : out std_logic;                --< give chip             |
        chip_out        : out std_logic_vector(0 to 31) --< chip                 /
      );
end entity;

architecture dfault of sym_to_chip is
  signal chip : std_logic_vector(chip_out'range);
  signal advance : std_logic;
begin

  -- map
with symbol_in select                                               --  sym        chip
  chip <= b"1101_1001_1100_0011_0101_0010_0010_1110" when b"0000",  --<   0   0x744AC39B (ror  7)
          b"1110_1101_1001_1100_0011_0101_0010_0010" when b"1000",  --<   1   0xB744AC39 (ror  0)
          b"0010_1110_1101_1001_1100_0011_0101_0010" when b"0100",  --<   2   0x9B744AC3 (ror  1)
          b"0010_0010_1110_1101_1001_1100_0011_0101" when b"1100",  --<   3   0x39B744AC (ror  2)
          b"0101_0010_0010_1110_1101_1001_1100_0011" when b"0010",  --<   4   0xC39B744A (ror  3)
          b"0011_0101_0010_0010_1110_1101_1001_1100" when b"1010",  --<   5   0xAC39B744 (ror  4)
          b"1100_0011_0101_0010_0010_1110_1101_1001" when b"0110",  --<   6   0x4AC39B74 (ror  5)
          b"1001_1100_0011_0101_0010_0010_1110_1101" when b"1110",  --<   7   0x44AC39B7 (ror  6)
          b"1000_1100_1001_0110_0000_0111_0111_1011" when b"0001",  --<   8   0xDEE06931 (ror 15)
          b"1011_1000_1100_1001_0110_0000_0111_0111" when b"1001",  --<   9   0x1DEE0693 (ror  8)
          b"0111_1011_1000_1100_1001_0110_0000_0111" when b"0101",  --<  10   0x31DEE069 (ror  9)
          b"0111_0111_1011_1000_1100_1001_0110_0000" when b"1101",  --<  11   0x931DEE06 (ror 10)
          b"0000_0111_0111_1011_1000_1100_1001_0110" when b"0011",  --<  12   0x6931DEE0 (ror 11)
          b"0110_0000_0111_0111_1011_1000_1100_1001" when b"1011",  --<  13   0x06931DEE (ror 12)
          b"1001_0110_0000_0111_0111_1011_1000_1100" when b"0111",  --<  14   0xE06931DE (ror 13)
          b"1100_1001_0110_0000_0111_0111_1011_1000" when others;   --<  15   0xEE06931D (ror 14)

  -- drive
  sink_valid_out  <= source_valid_in after TPD;
  source_take_out <= sink_ready_in   after TPD;
  sink_give_out   <= source_ready_in after TPD;
  chip_out        <= chip            after TPD;

end architecture;