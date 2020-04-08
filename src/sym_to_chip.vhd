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
 -- mealy outputs
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
with symbol_in select                                               --  sym    chip(0 to 31)
  chip <= b"1101_1001_1100_0011_0101_0010_0010_1110" when b"0000",  --<   0    0xD9C3522E
          b"1110_1101_1001_1100_0011_0101_0010_0010" when b"0001",  --<   1    0xED9C3522 (ror  0)
          b"0010_1110_1101_1001_1100_0011_0101_0010" when b"0010",  --<   2    0x2ED9C352 (ror  1)
          b"0010_0010_1110_1101_1001_1100_0011_0101" when b"0011",  --<   3    0x22ED9C35 (ror  2)
          b"0101_0010_0010_1110_1101_1001_1100_0011" when b"0100",  --<   4    0x522ED9C3 (ror  3)
          b"0011_0101_0010_0010_1110_1101_1001_1100" when b"0101",  --<   5    0x3522ED9C (ror  4)
          b"1100_0011_0101_0010_0010_1110_1101_1001" when b"0110",  --<   6    0xC3522ED9 (ror  5)
          b"1001_1100_0011_0101_0010_0010_1110_1101" when b"0111",  --<   7    0x93C522ED (ror  6)
          b"1000_1100_1001_0110_0000_0111_0111_1011" when b"1000",  --<   8    0x8C96077B
          b"1011_1000_1100_1001_0110_0000_0111_0111" when b"1001",  --<   9    0xB8C96077 (ror  8)
          b"0111_1011_1000_1100_1001_0110_0000_0111" when b"1010",  --<  10    0x7B8C9607 (ror  9)
          b"0111_0111_1011_1000_1100_1001_0110_0000" when b"1011",  --<  11    0x77B8C960 (ror 10)
          b"0000_0111_0111_1011_1000_1100_1001_0110" when b"1100",  --<  12    0x077B8C96 (ror 11)
          b"0110_0000_0111_0111_1011_1000_1100_1001" when b"1101",  --<  13    0x6077B8C9 (ror 12)
          b"1001_0110_0000_0111_0111_1011_1000_1100" when b"1110",  --<  14    0x96077B8C (ror 13)
          b"1100_1001_0110_0000_0111_0111_1011_1000" when others;   --<  15    0xC96077B8 (ror 14)

  -- drive
  sink_valid_out <= source_valid_in after TPD;
  advance <= sink_ready_in and source_ready_in;
  sink_give_out <= advance after TPD;
  source_take_out <= advance after TPD;
  chip_out <= chip after TPD;

end architecture;