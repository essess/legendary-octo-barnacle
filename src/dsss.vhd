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
 -- (D)irect (S)equence (S)pread (S)pectrum
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

        source_ready_in : in std_logic;                     --< byte is available    \
        source_valid_in : in std_logic;                     --< byte is valid         |__ SOURCE input
        source_take_out : out std_logic;                    --< take byte             |
        byte_in         : in std_logic_vector(7 downto 0);  --< byte                 /

        sink_ready_in   : in  std_logic;                    --< sink ready to accept \
        sink_valid_out  : out std_logic;                    --< chip is valid         |__ SINK output
        sink_give_out   : out std_logic;                    --< give chip             |
        chip_out        : out std_logic_vector(31 downto 0) --< chip                 /
      );
end entity;

architecture dfault of dsss is

  signal octet : std_logic_vector(byte_in'reverse_range);   --< look below to see why
  signal symbol : std_logic_vector(0 to 3);
  signal chip : std_logic_vector(chip_out'reverse_range);   --< look below to see why
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

               source_ready_in => source_ready_in,
               source_valid_in => source_valid_in,
               source_take_out => source_take_out,
               octet_in        => octet,

               sink_valid_out => valid,
               sink_ready_in  => take,
               sink_give_out  => give,
               symbol_out     => symbol );

  sym_to_chip_inst : entity work.sym_to_chip
    generic map ( TPD => TPD )
    port map ( clk_in  => clk_in,
               srst_in => srst_in,

               source_valid_in => valid,
               source_ready_in => give,
               source_take_out => take,
               symbol_in       => symbol,

               sink_ready_in  => sink_ready_in,
               sink_valid_out => sink_valid_out,
               sink_give_out  => sink_give_out,
               chip_out       => chip );

   -- drive
   chip_out <= ( chip(31), chip(30), chip(29), chip(28),
                 chip(27), chip(26), chip(25), chip(24),
                 chip(23), chip(22), chip(21), chip(20),
                 chip(19), chip(18), chip(17), chip(16),
                 chip(15), chip(14), chip(13), chip(12),
                 chip(11), chip(10), chip( 9), chip( 8),
                 chip( 7), chip( 6), chip( 5), chip( 4),
                 chip( 3), chip( 2), chip( 1), chip( 0) );

end architecture;