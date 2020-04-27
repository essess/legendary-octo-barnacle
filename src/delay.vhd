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
 -- (DELAY)
 -- Delay for N clocks. Hold last value as flow control dictates.
 --
 -- mealy outputs
---

entity delay is
  generic( N : integer range 1 to integer'high := 1;
           INITIAL_VALUE : signed(15 downto 0) := (others=>'0');
           TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        sink_valid_in : in  std_logic;              --   \
        sink_ready_in : in  std_logic;              --    |__ sink/input
        sink_take_out : out std_logic;              --    |
        sample_in     : in  signed(15 downto 0);    --   /

        source_valid_out : out std_logic;           --   \
        source_ready_in  : in  std_logic;           --    |__ source/output
        source_give_out  : out std_logic;           --    |
        sample_out       : out signed(15 downto 0)  --   /
      );
end entity;

architecture dfault of delay is

  signal take, give, hold : std_logic;
  signal sample : signed(sample_out'range);

begin

  take <= source_ready_in;
  give <= sink_ready_in;
  hold <= sink_valid_in and not(source_ready_in and sink_ready_in);    --<  TODO: controlled by flow control

  process(clk_in)
    type valary_t is array (0 to N) of signed(sample_in'range);
    variable values : valary_t;
  begin
    if rising_edge(clk_in) then
      if srst_in = '1' then
        for i in values'range loop
          values(i) := INITIAL_VALUE;
        end loop;
      elsif hold = '1' then
        values := values;
      else
        for i in values'low to (values'high -1) loop  --< shift
          values(i+1) := values(i);
        end loop;
        values(0) := sample_in;                       --< load new sample
      end if;
    end if;
    sample <= values(N);
  end process;

  -- drive --------------------------
  source_valid_out <= sink_valid_in after TPD;
  source_give_out <= give after TPD;
  sink_take_out <= take after TPD;
  sample_out <= sample after TPD;

end architecture;