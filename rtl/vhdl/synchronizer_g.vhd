-------------------------------------------------------------------------------
-- Title      : N bit synchronizer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synchronizer_g.vhd
-- Author     :   <user@DESKTOP-4QS12VJ>
-- Company    : 
-- Created    : 2018-10-11
-- Last update: 2018-10-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2018 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-10-11  1.0      user    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------

entity synchronizer_g is
  generic (N : natural);
  port (
    clk, reset : in  std_logic;
    in_async   : in  std_logic_vector (N-1 downto 0);
    out_sync   : out std_logic_vector (N-1 downto 0)
    );

end entity synchronizer_g;

-------------------------------------------------------------------------------

architecture str of synchronizer_g is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  signal meta_reg, sync_reg   : std_logic_vector (N-1 downto 0);
  signal meta_next, sync_next : std_logic_vector (N-1 downto 0);
begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
-- two r e g i s t e r s
  process (clk, reset)
  begin
    if (reset = '1') then
      meta_reg <= (others => '0');
      sync_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      meta_reg <= meta_next;
      sync_reg <= sync_next;
    end if;
  end process;

-- n e x t - s t a t e l o g i c
  meta_next <= in_async;
  sync_next <= meta_reg;
-- output
  out_sync  <= sync_reg;

end architecture str;

-------------------------------------------------------------------------------
