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
 -- (CHIP) (TO) (DIG)ital (QPSK) modulator out :
 --   { for each selected "bit-pair" of chip_in : LSB => I, MSB => Q }
 --
 --                   +Q
 --                    |
 --                 01 | 11
 --               -----+----- +I
 --                 00 | 10
 --                    |
 --
 -- NOTE:
 -- This block is intended to interface to things which assume the
 -- long standing bit order of msb downto lsb used outside of the
 -- 802.15.4 standard.
 --
 -- mealy outputs - ALL PORTS ON THE SAME clk/srst DOMAIN
---

entity chip_to_dig_qpsk is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in std_logic;                     --<                        \
        sink_ready_in : in std_logic;                     --< source ready to emit    |__ sink input
        sink_take_out : out std_logic;                    --<                         |
        chip_in       : in std_logic_vector(7 downto 0);  --                         /

        I_source_valid_out : out std_logic;               --<                        \
        I_source_ready_in  : in  std_logic;               --< sink ready to accept    |__ source output
        I_source_give_out  : out std_logic;               --<                         |
        I_out              : out std_logic;               --< digital I channel      /

        Q_source_valid_out : out std_logic;               --<                        \
        Q_source_ready_in  : in  std_logic;               --< sink ready to accept    |__ source output
        Q_source_give_out  : out std_logic;               --<                         |
        Q_out              : out std_logic                --< digital Q channel      /
      );
end entity;

architecture dfault of chip_to_dig_qpsk is

  signal i, q, valid, source_ready, take, give, source_give, agree : std_logic;

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
              source_ready_in => source_ready,
              source_give_out => source_give,
              value_out       => selection );

  -- Consider the case where the I path may be ready, but the Q path
  -- is not. By design, the selector instance above will still assert
  -- give on source !ready (assuming sink is ready). On the next clock,
  -- Q will expect the last sample to be held and I will expect the
  -- sample to be advanced.
  --
  -- So, pass through source_give state when i_source AND q_source behaviors
  -- are in agreement. Otherwise NEVER give. Source side ports are ready
  -- only when both i/q sources are in agreement.
  agree <= I_source_ready_in xnor Q_source_ready_in;
  give <= source_give when agree else '0';
  source_ready <= I_source_ready_in and Q_source_ready_in;

  -- drive --------------------------
  sink_take_out <= take after TPD;

  I_source_valid_out <= sink_valid_in after TPD;
  I_source_give_out  <= give after TPD;
  I_out              <= chip_in((selection*2)+0) after TPD; --< TODO: doublecheck synthesis!

  Q_source_valid_out <= sink_valid_in after TPD;
  Q_source_give_out  <= give after TPD;
  Q_out              <= chip_in((selection*2)+1) after TPD; --< TODO: doublecheck synthesis!

end architecture;