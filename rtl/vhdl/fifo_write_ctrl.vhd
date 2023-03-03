-------------------------------------------------------------------------------
-- Title      : fifo write controller
-- Project    : 
-------------------------------------------------------------------------------
-- File       : fifo_write_ctrl.vhd
-- Author     :   <user@DESKTOP-4QS12VJ>
-- Company    : 
-- Created    : 2018-10-11
-- Last update: 2018-10-12
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
entity fifo_write_ctrl is
  generic (DEPTH : natural := 4);
  port (
    clkw, resetw : in  std_logic;
    wr           : in  std_logic;
    r_ptr_in     : in    std_logic_vector(DEPTH downto 0);
    full         : out std_logic;
    w_ptr_out    : out std_logic_vector(DEPTH downto 0);
    w_addr       : out std_logic_vector(DEPTH-1 downto 0)
    );
end entity fifo_write_ctrl;
-------------------------------------------------------------------------------
architecture str of fifo_write_ctrl is
  signal w_ptr_reg, w_ptr_next : std_logic_vector(DEPTH downto 0);
  signal gray1, bin, bin1      : std_logic_vector(DEPTH downto 0);
  signal waddr_all             : std_logic_vector(DEPTH-1 downto 0);
  signal waddr_msb, raddr_msb  : std_logic;
  signal full_flag             : std_logic;
begin  -- architecture str
-- register
  process (clkw, resetw) is
  begin  -- process
    if resetw = '1' then                  -- asynchronous reset (active low)
      w_ptr_reg <= (others => '0');
    elsif clkw'event and clkw = '1' then  -- rising clock edge
      w_ptr_reg <= w_ptr_next;
    end if;
  end process;

  -- (DEPTH+1)-bit Gray counter
  bin   <= w_ptr_reg xor ('0' & bin(DEPTH downto 1));
  bin1  <= std_logic_vector(unsigned(bin)+1);
  gray1 <= bin1 xor ('0' & bin1(DEPTH downto 1));

  -- update write pointer
  w_ptr_next <= gray1 when wr = '1' and full_flag = '0' else
                w_ptr_reg;

  -- DEPTH-bit Gray counter
  waddr_msb <= w_ptr_reg(DEPTH) xor w_ptr_reg(DEPTH-1);
  waddr_all <= waddr_msb & w_ptr_reg(DEPTH-2 downto 0);

  -- check for FIFO full
  raddr_msb <= r_ptr_in(DEPTH) xor r_ptr_in(DEPTH-1);
  full_flag <=
    '1' when r_ptr_in(DEPTH) /= w_ptr_reg(DEPTH) and
    r_ptr_in(DEPTH-2 downto 0) = w_ptr_reg(DEPTH-2 downto 0) and 
    raddr_msb = waddr_msb else
    '0';
  -- output
  w_addr    <= waddr_all;
  w_ptr_out <= w_ptr_reg;
  full      <= full_flag;

end architecture str;

-------------------------------------------------------------------------------
