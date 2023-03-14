-------------------------------------------------------------------------------
-- Title      : simplified uart receiver
-- Project    :
-------------------------------------------------------------------------------
-- File       : uart_receiver.vhd
-- Author     :   <user@DESKTOP-4QS12VJ>
-- Company    :
-- Created    : 2018-10-11
-- Last update: 2023-03-15
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
-- in case, where clk :  1Mhz, baud:   1200 ( 1000000/(16*  1200) = 52)
-- in case, where clk : 40Mhz, baud: 115200 (40000000/(16*115200) = 22)
entity uart_receiver is
  generic (DVSR : natural := 22);
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    rx           : in  std_logic;
    ready        : out std_logic;
    rcvDataValid : out std_logic;
    pout         : out std_logic_vector(7 downto 0)
    );
end entity uart_receiver;
-------------------------------------------------------------------------------
architecture str of uart_receiver is
  type state_t is (IDLE, START, DATA, STOPs);
  signal regState, nState      : state_t;
  --signal clk16_reg, clk16_next : unsigned(5 downto 0);
  signal clk16_reg, clk16_next : unsigned(7 downto 0);
  signal sReg, sNext           : unsigned(3 downto 0);
  signal nReg, nNext           : unsigned(2 downto 0);
  signal bReg, bNext           : std_logic_vector(7 downto 0);  -- rx buf register
  signal sPulse                : std_logic;
begin  -- architecture str

  -- purpose: free running mod-52 counter, independent of FSMD
  mod_52_counter : process (clk, reset) is
  begin  -- process mod_52_counter
    if reset = '1' then                 -- asynchronous reset (active low)
      clk16_reg <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      clk16_reg <= clk16_next;
    end if;
  end process mod_52_counter;

  -- next-state / output logic
  clk16_next <= (others => '0') when clk16_reg = (DVSR-1) else
                clk16_reg + 1;
  sPulse <= '1' when clk16_reg = 0 else '0';
--  sPulse <= '1';

  -- purpose: FSMD state & DATA registers
  fsmd_state_data : process (clk, reset) is
  begin  -- process fsmd_state_data
    if reset = '1' then                 -- asynchronous reset (active low)
      regState <= IDLE;
      sReg     <= (others => '0');
      nReg     <= (others => '0');
      bReg     <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      regState <= nState;
      sReg     <= sNext;
      nReg     <= nNext;
      bReg     <= bNext;
    end if;
  end process fsmd_state_data;

  -- purpose: next-state & DATA path functional units/routing
  --next_state_logic : process (all)
  next_state_logic : process (bReg, nReg, regState, rx, sPulse, sReg)
  begin  -- process next_state_logic
    nState       <= regState;
    sNext        <= sReg;
    nNext        <= nReg;
    bNext        <= bReg;
    ready        <= '1';
    rcvDataValid <= '0';
    case regState is
      when IDLE =>
        if rx = '0' then
          nState <= START;
        end if;
        ready <= '0';
      when START =>
        if sPulse = '1' then
          if sReg = 7 then
            nState <= DATA;
            sNext  <= (others => '0');
          else
            sNext <= sReg + 1;
          end if;
        end if;
      when DATA =>
        if sPulse = '1' then
          if sReg = 15 then
            sNext <= (others => '0');
            bNext <= rx & bReg(bReg'high downto 1);
            if nReg = 7 then
              nState <= STOPs;
              nNext  <= (others => '0');
            else
              nNext <= nReg + 1;
            end if;
          else
            sNext <= sReg + 1;
          end if;
        end if;
      when STOPs =>
        if sPulse = '1' then
          if sReg = 15 then
            nState       <= IDLE;
            sNext        <= (others => '0');
            rcvDataValid <= '1';
          else
            sNext <= sReg + 1;
          end if;
        end if;
    end case;
  end process next_state_logic;
  pout <= bReg;

end architecture str;

-------------------------------------------------------------------------------
