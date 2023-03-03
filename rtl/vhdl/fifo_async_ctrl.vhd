
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_async_ctrl is
  generic (DEPTH : natural);
  port (
    clkw   : in  std_logic;
    resetw : in  std_logic;
    wr     : in  std_logic;
    full   : out std_logic;
    w_addr : out std_logic_vector(DEPTH-1 downto 0):=(others => '0');
    clkr   : in  std_logic;
    resetr : in  std_logic;
    rd     : in  std_logic;
    empty  : out std_logic;
    r_addr : out std_logic_vector(DEPTH-1 downto 0)
    );
end fifo_async_ctrl;

architecture str_arch of fifo_async_ctrl is
  signal r_ptr_in  : std_logic_vector (DEPTH downto 0);
  signal r_ptr_out : std_logic_vector (DEPTH downto 0);
  signal w_ptr_in  : std_logic_vector (DEPTH downto 0);
  signal w_ptr_out : std_logic_vector (DEPTH downto 0);
  component fifo_read_ctrl
    generic (DEPTH : natural);
    port (
      clkr      : in  std_logic;
      rd        : in  std_logic;
      resetr    : in  std_logic;
      w_ptr_in  : in  std_logic_vector (DEPTH downto 0);
      empty     : out std_logic;
      r_addr    : out std_logic_vector (DEPTH -1 downto 0);
      r_ptr_out : out std_logic_vector (DEPTH downto 0)
      );
  end component;
  component fifo_write_ctrl
    generic (DEPTH : natural);
    port (
      clkw      : in  std_logic;
      r_ptr_in  : in  std_logic_vector (DEPTH downto 0);
      resetw    : in  std_logic;
      wr        : in  std_logic;
      full      : out std_logic;
      w_addr    : out std_logic_vector (DEPTH -1 downto 0);
      w_ptr_out : out std_logic_vector (DEPTH downto 0)
      );
  end component;
  component synchronizer_g
    generic (N : natural);
    port (
      clk      : in  std_logic;
      in_async : in  std_logic_vector (N - 1 downto 0);
      reset    : in  std_logic;
      out_sync : out std_logic_vector (N - 1 downto 0)
      );
  end component;
begin
  read_ctrl : fifo_read_ctrl
    generic map (DEPTH => DEPTH)
    port map (clkr      => clkr,
              resetr    => resetr,
              rd        => rd,
              w_ptr_in  => w_ptr_in,
              empty     => empty,
              r_ptr_out => r_ptr_out,
              r_addr    => r_addr);
  write_ctrl : fifo_write_ctrl
    generic map(DEPTH => DEPTH)
    port map(clkw      => clkw,
             resetw    => resetw,
             wr        => wr,
             r_ptr_in  => r_ptr_in,
             full      => full,
             w_ptr_out => w_ptr_out,
             w_addr    => w_addr);

  sync_w_ptr : synchronizer_g
    generic map (N => DEPTH + 1)
    port map(clk      => clkw,
             reset    => resetw,
             in_async => w_ptr_out,
             out_sync => w_ptr_in);

  sync_r_ptr : synchronizer_g
    generic map (N => DEPTH + 1)
    port map(clk      => clkr,
             reset    => resetr,
             in_async => r_ptr_out,
             out_sync => r_ptr_in);

end str_arch;
