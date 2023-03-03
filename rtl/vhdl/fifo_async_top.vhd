-------------------------------------------------------------------------------
-- Title      : async_fifo with memory block
-- Project    :
-------------------------------------------------------------------------------
-- File       : fifo_async_top.vhd
-- Author     :   <user@DESKTOP-4QS12VJ>
-- Company    :
-- Created    : 2018-10-11
-- Last update: 2023-03-01
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
entity fifo_async_top is
  generic (DEPTH : natural := 4;
           WIDTH : natural := 8);
  port (
    clkw    : in  std_logic;
    resetw  : in  std_logic;
    wr      : in  std_logic;
    full    : out std_logic;
    fifoIn  : in  std_logic_vector(WIDTH-1 downto 0);
    clkr    : in  std_logic;
    resetr  : in  std_logic;
    rd      : in  std_logic;
    empty   : out std_logic;
    fifoOut : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity fifo_async_top;
-------------------------------------------------------------------------------
architecture str of fifo_async_top is

  type mem_t is array(0 to 2**DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal mem : mem_t;                   -- memory model
  --signal mem : mem_t := (others => (others => '0'));  -- memory model
  -----------------------------------------------------------------------------
  component fifo_async_ctrl is
    generic (DEPTH : natural);
    port (
      clkw   : in  std_logic;
      resetw : in  std_logic;
      wr     : in  std_logic;
      full   : out std_logic;
      w_addr : out std_logic_vector(DEPTH-1 downto 0);
      clkr   : in  std_logic;
      resetr : in  std_logic;
      rd     : in  std_logic;
      empty  : out std_logic;
      r_addr : out std_logic_vector(DEPTH-1 downto 0));
  end component fifo_async_ctrl;

  signal w_addr : std_logic_vector(DEPTH-1 downto 0);
  signal r_addr : std_logic_vector(DEPTH-1 downto 0);

begin  -- architecture str

-- purpose: fifo write, push operation
  writeFifo_p : process (clkw, resetw) is
  begin  -- process writeFifo_p
    if resetw = '1' then                  -- asynchronous reset (active low)
    --  mem <= (others => (others => '0'));
    elsif clkw'event and clkw = '1' then  -- rising clock edge
      if wr = '1' then
        mem(to_integer(unsigned(w_addr))) <= fifoIn;
      end if;
    end if;
  end process writeFifo_p;

  -- purpose: read fifo, pop operation
  readFifo_p : process (clkr, resetr) is
  begin  -- process readFifo_p
    if resetr = '1' then                  -- asynchronous reset (active low)
      fifoOut <= (others => '0');
    elsif clkr'event and clkr = '1' then  -- rising clock edge
      if rd = '1' then
        fifoOut <= mem(to_integer(unsigned(r_addr)));
      end if;
    end if;
  end process readFifo_p;

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  fifo_async_ctrl_1 : entity work.fifo_async_ctrl
    generic map (DEPTH => DEPTH)
    port map (
      clkw   => clkw,
      resetw => resetw,
      wr     => wr,
      full   => full,
      w_addr => w_addr,
      clkr   => clkr,
      resetr => resetr,
      rd     => rd,
      empty  => empty,
      r_addr => r_addr);
end architecture str;

-------------------------------------------------------------------------------
