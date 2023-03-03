-------------------------------------------------------------------------------
-- Title      : uart transmitter
-- Project    :
-------------------------------------------------------------------------------
-- File       : uart_transmitter.vhd
-- Author     :   <user@DESKTOP-4QS12VJ>
-- Company    :
-- Created    : 2018-10-11
-- Last update: 2023-03-02
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
entity uart_transmitter is
  generic (DVSR      : natural := 4;
           WORD_SIZE : natural := 8);
  port (
    clk          : in  std_logic;       -- 16Mhz
    nRST         : in  std_logic;
    serialOut    : out std_logic;
    dataBus      : in  std_logic_vector(WORD_SIZE-1 downto 0);
    byteReady    : in  std_logic;       -- used by host to signal ready
    ldXmtDataReg : in  std_logic;       -- used by host to load data reg
    tByte        : in  std_logic;       -- used by host to signal the start of transmission
    txDone       : out std_logic
    );
end entity uart_transmitter;
-------------------------------------------------------------------------------
architecture str of uart_transmitter is

  constant SZ_BIT_CNT : natural := 3;   -- size of the bit counter

  type state_t is (IDLE, WAITING, WAITING1, SENDING);
  signal regState, nState      : state_t;  -- state reg and next state signal;
  signal xmtDataReg            : std_logic_vector(WORD_SIZE-1 downto 0);  -- tx data reg
  signal xmtShiftReg           : std_logic_vector(WORD_SIZE downto 0);  -- tx data reg
  signal ldXmtShiftReg         : std_logic;  -- flag to load the xmtshiftreg
  --signal bitCount         : integer range 0 to 2**(SZ_BIT_CNT+1)-1;  -- counts the bits that are transmitted;
  signal bitCount              : integer := 0;  -- counts the bits that are transmitted;
  signal clear                 : std_logic;  -- clears the bitCount after last bit is sent
  signal shift                 : std_logic;  -- causes shift of data in xmtShiftreg
  signal start                 : std_logic;  -- signals start of transmission
  signal sPulse                : std_logic;  -- signals start of transmission
  signal clk16_reg, clk16_next : unsigned(5 downto 0);

begin  -- architecture str

  serialOut <= xmtShiftReg(0);

  -- purpose: free running mod-52 counter, independent of FSMD
  mod_52_counter : process (clk, nRST) is
  begin  -- process mod_52_counter
    if nRST = '0' then                  -- asynchronous reset (active low)
      clk16_reg <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      clk16_reg <= clk16_next;
    end if;
  end process mod_52_counter;

-- next-state / output logic
  clk16_next <= (others => '0') when clk16_reg = (DVSR-1) else
                clk16_reg + 1;
  sPulse <= '1' when clk16_reg = 0 else '0';

  -- purpose: output and next state logic
  -- type   : combinational
  --output_and_next_state : process (all) is
  output_and_next_state : process (bitCount, byteReady, regState, sPulse, tByte) is
  begin  -- process output_and_next_state
    -- default values
    nState        <= regState;
    ldXmtShiftReg <= '0';
    clear         <= '0';
    shift         <= '0';
    start         <= '0';
    txDone        <= '0';
    case regState is
      when IDLE =>
        if byteReady = '1' then
          ldXmtShiftReg <= '1';
          nState        <= WAITING;
        end if;
      when WAITING =>
        if tByte = '1' then
          nState <= WAITING1;
        end if;
      when WAITING1 =>
        if sPulse = '1' then            -- once in 16 clock cycles
          start  <= '1';
          nState <= SENDING;
        end if;
      when SENDING =>
        if sPulse = '1' then            -- once in 16 clock cycles
          if bitCount /= WORD_SIZE+1 then
            shift <= '1';
          else
            clear  <= '1';
            nState <= IDLE;
            txDone <= '1';
          end if;
        end if;
    end case;
  end process output_and_next_state;

  -- purpose: state transition logic
  state_transitions : process (clk, nRST) is
  begin  -- process state_transitions
    if nRST = '0' then                  -- asynchronous reset (active low)
      regState <= IDLE;
    elsif clk'event and clk = '1' then  -- rising clock edge
      regState <= nState;
    end if;
  end process state_transitions;

  -- purpose: register transfers
  register_transfers : process (clk, nRST) is
  begin  -- process register_transfers
    if nRST = '0' then                  -- asynchronous reset (active low)
      xmtDataReg  <= (others => '0');
      xmtShiftReg <= (others => '1');
      bitCount    <= 0;
    elsif clk'event and clk = '1' then  -- rising clock edge

      if ldXmtDataReg = '1' then
        xmtDataReg <= dataBus;
      end if;

      if ldXmtShiftReg = '1' then
        xmtShiftReg <= xmtDataReg & '1';
      end if;
      if start = '1' then
        xmtShiftReg(0) <= '0';
      end if;

      if clear = '1' then
        bitCount <= 0;
      elsif shift = '1' then
        bitCount <= bitCount + 1;
      end if;
      if shift = '1' then
        xmtShiftReg <= '1' & xmtShiftReg(WORD_SIZE downto 1);
      end if;
    end if;
  end process register_transfers;


end architecture str;

-------------------------------------------------------------------------------
