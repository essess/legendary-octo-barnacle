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
 -- See section 12.2.4, table 12-1. 32b chips are split into 8b
 -- chunks on the output.
 --
 -- NOTE:
 -- The standard decides to use LSB->MSB bit ordering which is why (a to b)
 -- std_logic_vector's are used here. It will 'read' naturally (as depicted
 -- in the standard) but is valued differently.
 --
 -- mealy outputs - see sm_tables.xlsx/.pdf for more information
---

entity sym_to_chip is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in std_logic;                   --< symbol is valid      \
        sink_ready_in : in std_logic;                   --< symbol is available   |__ sink input
        sink_take_out : out std_logic;                  --< take symbol           |
        symbol_in     : in std_logic_vector(0 to 3);    --< symbol               /

        source_valid_out : out std_logic;               --< chip chunk is valid  \
        source_ready_in  : in  std_logic;               --< sink ready to accept  |__ source output
        source_give_out  : out std_logic;               --< give chip chunk       |
        chip_chunk_out   : out std_logic_vector(0 to 7) --< chip chunk           /
      );
end entity;

architecture dfault of sym_to_chip is

  signal chip : std_logic_vector(0 to 31);  --< follow 802.15.4 STD nomenclature
  signal chip_chunk : std_logic_vector(chip_chunk_out'range);
  signal valid, take, give : std_logic;

  constant VAL_LOW : integer := 0;
  constant VAL_HIGH : integer := 3;
  signal selection : integer range VAL_LOW to VAL_HIGH;

begin

  selector_inst : entity work.selector
    generic map ( VAL_LOW  => VAL_LOW,
                  VAL_HIGH => VAL_HIGH )
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              sink_valid_in => sink_valid_in,
              sink_ready_in => sink_ready_in,
              sink_take_out => take,
              source_ready_in => source_ready_in,
              source_give_out => give,
              value_out       => selection );

  -- section 12.2.4, table 12-1 : -----------------------------------------------------------------
  with symbol_in select                                               --  sym        chip
    chip <= b"1101_1001_1100_0011_0101_0010_0010_1110" when b"0000",  --<   0   0x44C39B74 (ror  7)
            b"1110_1101_1001_1100_0011_0101_0010_0010" when b"1000",  --<   1   0x444C39B7 (ror  0)
            b"0010_1110_1101_1001_1100_0011_0101_0010" when b"0100",  --<   2   0x7444C39B (ror  1)
            b"0010_0010_1110_1101_1001_1100_0011_0101" when b"1100",  --<   3   0xB7444C39 (ror  2)
            b"0101_0010_0010_1110_1101_1001_1100_0011" when b"0010",  --<   4   0x9B7444C3 (ror  3)
            b"0011_0101_0010_0010_1110_1101_1001_1100" when b"1010",  --<   5   0x39B744AC (ror  4)
            b"1100_0011_0101_0010_0010_1110_1101_1001" when b"0110",  --<   6   0xC39B744A (ror  5)
            b"1001_1100_0011_0101_0010_0010_1110_1101" when b"1110",  --<   7   0x4C39B744 (ror  6)
            b"1000_1100_1001_0110_0000_0111_0111_1011" when b"0001",  --<   8   0xDEE06931 (ror 15)
            b"1011_1000_1100_1001_0110_0000_0111_0111" when b"1001",  --<   9   0x1DEE0693 (ror  8)
            b"0111_1011_1000_1100_1001_0110_0000_0111" when b"0101",  --<  10   0x31DEE069 (ror  9)
            b"0111_0111_1011_1000_1100_1001_0110_0000" when b"1101",  --<  11   0x931DEE06 (ror 10)
            b"0000_0111_0111_1011_1000_1100_1001_0110" when b"0011",  --<  12   0x6931DEE0 (ror 11)
            b"0110_0000_0111_0111_1011_1000_1100_1001" when b"1011",  --<  13   0x06931DEE (ror 12)
            b"1001_0110_0000_0111_0111_1011_1000_1100" when b"0111",  --<  14   0xE06931DE (ror 13)
            b"1100_1001_0110_0000_0111_0111_1011_1000" when others;   --<  15   0xEE06931D (ror 14)

  with selection select
    chip_chunk <= chip(24 to 31) when 3,
                  chip(16 to 23) when 2,
                  chip( 8 to 15) when 1,
                  chip( 0 to  7) when others;

  -- drive ------------------------------------
  source_valid_out <= sink_valid_in after TPD;
  sink_take_out    <= take after TPD;
  source_give_out  <= give after TPD;
  chip_chunk_out   <= chip_chunk after TPD;

end architecture;