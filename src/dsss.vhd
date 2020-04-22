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
 -- (D)irect (S)equence (S)pread (S)pectrum chip generator
 --
 -- NOTE:
 -- This block is intended to interface to things which assume the
 -- long standing bit order of msb downto lsb used outside of the
 -- 802.15.4 standard.
 --
 -- mealy outputs
---

entity dsss is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in std_logic;                       --< byte is valid        \
        sink_ready_in : in std_logic;                       --< byte is available     |__ sink input
        sink_take_out : out std_logic;                      --< take byte             |
        byte_in       : in std_logic_vector(7 downto 0);    --< byte                 /

        source_valid_out : out std_logic;                   --< chip chunk is valid  \
        source_ready_in  : in  std_logic;                   --< sink ready to accept  |__ source output
        source_give_out  : out std_logic;                   --< give chip chunk       |
        chip_chunk_out   : out std_logic_vector(7 downto 0) --< chip chunk           /
      );
end entity;

architecture dfault of dsss is

  signal octet : std_logic_vector(byte_in'reverse_range);             --< look below to see why
  signal symbol : std_logic_vector(0 to 3);
  signal chip_chunk : std_logic_vector(chip_chunk_out'reverse_range); --< look below to see why
  signal valid, give, take : std_logic;

begin

  -- why bother reversing?,
  --
  --              'byte'                        'octet'
  --            7 downto 0                     0   to   7
  --            msb -> lsb                     lsb -> msb
  --  (0x34)     00110100     => reverse =>     00101100
  --
  --  this decision was made in the hopes that it makes crossreferencing
  --  the standard easier when trying to troubleshoot or understand things
  --
  octet <= ( byte_in(0), byte_in(1), byte_in(2), byte_in(3),
             byte_in(4), byte_in(5), byte_in(6), byte_in(7) );

  oct_to_sym_inst : entity work.oct_to_sym
    port map ( clk_in  => clk_in,
               srst_in => srst_in,
               sink_valid_in => sink_valid_in,
               sink_ready_in => sink_ready_in,
               sink_take_out => sink_take_out,
               octet_in      => octet,
               source_valid_out => valid,
               source_ready_in  => take,
               source_give_out  => give,
               symbol_out       => symbol );

  sym_to_chip_inst : entity work.sym_to_chip
    generic map ( TPD => TPD )
    port map ( clk_in  => clk_in,
               srst_in => srst_in,
               sink_valid_in => valid,
               sink_ready_in => give,
               sink_take_out => take,
               symbol_in     => symbol,
               source_ready_in  => source_ready_in,
               source_valid_out => source_valid_out,
               source_give_out  => source_give_out,
               chip_chunk_out   => chip_chunk );

   -- drive
   chip_chunk_out <= ( chip_chunk(7), chip_chunk(6), chip_chunk(5), chip_chunk(4),
                       chip_chunk(3), chip_chunk(2), chip_chunk(1), chip_chunk(0) );

end architecture;