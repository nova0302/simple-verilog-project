-------------------------------------------------------------------------------
-- Title      : fifo read controller
-- Project    : 
-------------------------------------------------------------------------------
-- File       : fifo_read_ctrl.vhd
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
entity fifo_read_ctrl is
  generic (DEPTH : natural := 4);
  port (
    clkr, resetr : in  std_logic;
    w_ptr_in     :  in   std_logic_vector(DEPTH downto 0);
    rd           : in  std_logic;
    empty        : out std_logic;
    r_ptr_out    : out std_logic_vector(DEPTH downto 0);
    r_addr       : out std_logic_vector(DEPTH-1 downto 0)
    );

end entity fifo_read_ctrl;
-------------------------------------------------------------------------------
architecture str of fifo_read_ctrl is
  signal r_ptr_reg, r_ptr_next : std_logic_vector(DEPTH downto 0);
  signal gray1, bin, bin1      : std_logic_vector(DEPTH downto 0);
  signal raddr_all             : std_logic_vector(DEPTH-1 downto 0);
  signal raddr_msb, waddr_msb  : std_logic;
  signal empty_flag            : std_logic;

begin  -- architecture str
-- register
  process (clkr, resetr) is
  begin  -- process
    if resetr = '1' then                  -- asynchronous reset (active low)
      r_ptr_reg <= (others => '0');
    elsif clkr'event and clkr = '1' then  -- rising clock edge
      r_ptr_reg <= r_ptr_next;
    end if;
  end process;

  -- (DEPTH+1)-bit Gray counter
  bin   <= r_ptr_reg xor ('0' & bin(DEPTH downto 1));
  bin1  <= std_logic_vector(unsigned(bin)+1);
  gray1 <= bin1 xor ('0' & bin1(DEPTH downto 1));

  -- update read pointer
  r_ptr_next <= gray1 when rd = '1' and empty_flag = '0' else
                r_ptr_reg;

  -- DEPTH-bit Gray counter
  raddr_msb <= r_ptr_reg(DEPTH) xor r_ptr_reg(DEPTH-1);
  raddr_all <= raddr_msb & r_ptr_reg(DEPTH-2 downto 0);
  waddr_msb <= w_ptr_in(DEPTH) xor w_ptr_in(DEPTH-1);
  --raddr_msb <= r_ptr_in(DEPTH) xor r_ptr_in(DEPTH-1);

  -- check for FIFO empty
  empty_flag <=
    '1' when w_ptr_in(DEPTH) = r_ptr_reg(DEPTH) and
    w_ptr_in(DEPTH-2 downto 0) = r_ptr_reg(DEPTH-2 downto 0) and
    raddr_msb = waddr_msb else
    '0';
  -- output
  r_addr    <= raddr_all;
  r_ptr_out <= r_ptr_reg;
  empty     <= empty_flag;

end architecture str;

-------------------------------------------------------------------------------
