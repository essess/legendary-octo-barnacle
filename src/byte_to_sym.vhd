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
 -- (BYTE)s (TO) (SYM)bols
 --
 -- According to the 802.15.4 OQPSK phy section, this is simply the act
 -- of peeling off nibbles starting at the LSN (12.2.3)
 --
 -- mealy outputs - see byte_to_sym_state_machine.pdf
---

entity byte_to_sym is
  generic( TPD : time := 0 ns );
  port(
        clk_in  : in std_logic;
        srst_in : in std_logic;

        source_ready_in : in std_logic;                     --< byte is available     \
        source_valid_in : in std_logic;                     --< byte is valid          |__ SOURCE input
        source_take_out : out std_logic;                    --< take byte              |
        byte_in         : in std_logic_vector(7 downto 0);  --< byte                  /

        sink_ready_in   : in  std_logic;                    --< sink ready to accept  \
        sink_valid_out  : out std_logic;                    --< symbol is valid        |__ SINK output
        sink_give_out   : out std_logic;                    --< give symbol            |
        symbol_out      : out std_logic_vector(3 downto 0)  --< symbol                /
      );
end entity;

architecture dfault of byte_to_sym is

  type state_t is ( upper,    --< drive upper nibble of input byte as output symbol
                    lower );  --< drive lower nibble of input byte as output symbol
  signal state, nxt : state_t;
  signal take, give : std_logic;

begin

  -- state
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      state <= nxt;
      if srst_in = '1' then
        state <= lower;
      end if;
    end if;
  end process;

  -- combinational
  process(state, source_ready_in, sink_ready_in, source_valid_in)
    variable inputs : std_logic_vector(2 downto 0);
  begin
    inputs := (source_valid_in, sink_ready_in, source_ready_in);
    case inputs is
      when "110" =>
         case state is
          when upper =>   --< hold on upper until source ready
            nxt <= upper;
            give <= '0';
            take <= '0';
          when lower =>   --< ok to advance on lower nibble
            nxt <= upper;
            give <= '1';
            take <= '0';
        end case;

      when "111" =>       --< advance
        case state is
          when upper =>
            nxt <= lower;
            give <= '1';
            take <= '1';
          when lower =>
            nxt <= upper;
            give <= '1';
            take <= '0';  --< don't advance the source!
        end case;

      when others =>      --< ready inputs are invalid
        nxt <= state;     --  (or sink not ready)
        give <= '0';
        take <= '0';
    end case;

  end process;

  -- drive signals
  source_take_out <= take after TPD;
  sink_give_out <= give after TPD;
  sink_valid_out <= source_valid_in after TPD;
  with state select
    symbol_out <= byte_in(7 downto 4) after TPD when upper,
                  byte_in(3 downto 0) after TPD when lower;

end architecture;