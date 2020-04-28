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
 -- (TOP) level implementation of an 802.15.4 OQPSK modulator
---

entity top is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in std_logic;                     --<  \
        sink_ready_in : in std_logic;                     --<   |__ sink input
        sink_take_out : out std_logic;                    --<   |
        byte_in       : in std_logic_vector(7 downto 0);  --<  /

        i_source_valid_out : out std_logic;               --<  \
        i_source_ready_in  : in  std_logic;               --<   |__ I source output
        i_source_give_out  : out std_logic;               --<   |
        i_sample_out       : out signed(15 downto 0);     --<  /

        q_source_valid_out : out std_logic;               --<  \
        q_source_ready_in  : in  std_logic;               --<   |__ Q source output
        q_source_give_out  : out std_logic;               --<   |
        q_sample_out       : out signed(15 downto 0)      --<  /

      );
end entity;

architecture dfault of top is

  signal take : std_logic;

  signal dsss_source_ready_in, dsss_source_valid_out, dsss_source_give_out : std_logic;
  signal chip_chunk : std_logic_vector(7 downto 0);

  signal qpsk_i_source_ready_in, qpsk_i_source_valid_out, qpsk_i_source_give_out : std_logic;
  signal qpsk_q_source_ready_in, qpsk_q_source_valid_out, qpsk_q_source_give_out : std_logic;
  signal qpsk_i, qpsk_q : std_logic;

  signal hs_i_source_valid_out, hs_i_source_give_out : std_logic;
  signal hs_i_sample : signed(i_sample_out'range);

  signal hs_q_source_ready_in, hs_q_source_valid_out, hs_q_source_give_out : std_logic;
  signal hs_q_sample : signed(q_sample_out'range);

  signal dly_output_vld : std_logic;
  signal dly_output : std_logic_vector(15 downto 0);

begin

  --                             I--> bit_to_sample --> half_sine_shaper ---- [ f-f ] ---->   I sample
  -- dsss --> chip_to_dig_qpsk --|
  --                             Q--> bit_to_sample --> half_sine_shaper --> delay_impl -->   Q sample

  dsss_inst : entity work.dsss
    port map ( clk_in  => clk_in,
               srst_in => srst_in,
               sink_valid_in => sink_valid_in,
               sink_ready_in => sink_ready_in,
               sink_take_out => take,
               byte_in       => byte_in,
               source_valid_out => dsss_source_valid_out,
               source_ready_in  => dsss_source_ready_in,
               source_give_out  => dsss_source_give_out,
               chip_chunk_out   => chip_chunk );

  chip_to_dig_qpsk_inst : entity work.chip_to_dig_qpsk
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              sink_valid_in => dsss_source_valid_out,
              sink_ready_in => dsss_source_give_out,
              sink_take_out => dsss_source_ready_in,
              chip_in       => chip_chunk,
              I_source_valid_out => qpsk_i_source_valid_out, --< TODO: need a bit_to_sample 'shim' on output here
              I_source_ready_in  => qpsk_i_source_ready_in,
              I_source_give_out  => qpsk_i_source_give_out,
              I_out              => qpsk_i,
              Q_source_valid_out => qpsk_q_source_valid_out, --< TODO: need a bit_to_sample 'shim' on output here
              Q_source_ready_in  => qpsk_q_source_ready_in,
              Q_source_give_out  => qpsk_q_source_give_out,
              Q_out              => qpsk_q );

  i_half_sine_shaper_inst : entity work.half_sine_shaper
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              sink_valid_in => qpsk_i_source_valid_out,
              sink_ready_in => qpsk_i_source_give_out,
              sink_take_out => qpsk_i_source_ready_in,
              sample_in     => qpsk_i,                       --< TODO: need a sample_to_bit 'shim' on input here
              source_valid_out => hs_i_source_valid_out,
              source_ready_in  => i_source_ready_in,
              source_give_out  => hs_i_source_give_out,
              sample_out       => hs_i_sample );

  q_half_sine_shaper_inst : entity work.half_sine_shaper
    port map( clk_in  => clk_in,
              srst_in => srst_in,
              sink_valid_in => qpsk_q_source_valid_out,
              sink_ready_in => qpsk_q_source_give_out,
              sink_take_out => qpsk_q_source_ready_in,
              sample_in     => qpsk_q,                       --< TODO: need a sample_to_bit 'shim' on input here
              source_valid_out => hs_q_source_valid_out,     --< hack
              source_ready_in  => q_source_ready_in,         --< hack
              source_give_out  => hs_q_source_give_out,      --< hack
              sample_out       => hs_q_sample );

  delay_impl_inst : entity work.delay_impl
    generic map( dataWidth => 16,
                 LENGTH => 2 )
    port map( clk   => clk_in,
              reset => srst_in,
              input => STD_LOGIC_VECTOR(hs_q_sample),
              input_vld => hs_q_source_valid_out,
              output => dly_output,
              output_vld => dly_output_vld );

  -- drive --------------------------
  sink_take_out <= take after TPD;

  i_source_give_out <= hs_i_source_give_out after TPD when rising_edge(clk_in);   --< insert a f-f to match the one in delay_impl
  i_source_valid_out <= hs_i_source_valid_out after TPD when rising_edge(clk_in); --< insert a f-f to match the one in delay_impl
  i_sample_out <= hs_i_sample after TPD when rising_edge(clk_in);                 --< insert a f-f to match the one in delay_impl

  q_source_give_out <= hs_q_source_give_out after TPD;
  q_source_valid_out <= dly_output_vld after TPD;
  q_sample_out <= SIGNED(dly_output) after TPD;

end architecture;