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
 -- (HALF) (SINE) (SHAPER)
 --
 -- For every input sample, create a series of samples. In this
 -- case, we create 4 samples out for every sample in. See
 -- section 12.2.6 of the 802.15.4 standard for the values used.
---

entity half_sine_shaper is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in  std_logic;              --  \
        sink_ready_in : in  std_logic;              --   |__ sink/input
        sink_take_out : out std_logic;              --   |
        sample_in     : in  std_logic;              --  /

        source_valid_out : out std_logic;           --  \
        source_ready_in  : in  std_logic;           --   |__ source/output
        source_give_out  : out std_logic;           --   |
        sample_out       : out signed(15 downto 0)  --  /
      );
end entity;

architecture dfault of half_sine_shaper is

  signal give, take : std_logic;

  constant VAL_LOW : integer := 0;
  constant VAL_HIGH : integer := 3;
  signal selection : integer range VAL_LOW to VAL_HIGH;

  type smpary_t is array (VAL_LOW to VAL_HIGH) of signed(sample_out'range);
  constant pos : smpary_t := ( to_signed(0, sample_out'length),       --<  0.00000000
                               to_signed(+23170, sample_out'length),  --< +0.70709229 (+1/sqrt(2) Q1.15)
                               to_signed(+32767, sample_out'length),  --< +0.99996948 (+MAX Q1.15)
                               to_signed(+23170, sample_out'length) );--< +0.70709229 (+1/sqrt(2) Q1.15)
  constant neg : smpary_t := ( to_signed(0, sample_out'length),       --<  0.00000000
                               to_signed(-23170, sample_out'length),  --< -0.70709229 (-1/sqrt(2) Q1.15)
                               to_signed(-32767, sample_out'length),  --< -0.99996948 (-MAX Q1.15)
                               to_signed(-23170, sample_out'length) );--< -0.70709229 (-1/sqrt(2) Q1.15)

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

  -- drive ------------------------------------
  source_valid_out <= sink_valid_in after TPD;
  source_give_out  <= give after TPD;
  sink_take_out    <= take after TPD;
  sample_out       <= pos(selection) after TPD when sample_in = '1' else
                      neg(selection) after TPD;

end architecture;