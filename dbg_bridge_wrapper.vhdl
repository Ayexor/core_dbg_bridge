library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dbg_bridge_wrapper is
  generic (
    CLK_FREQ      : integer := 100e6;
    UART_SPEED    : integer := 1e6;
    AXI_ID        : std_logic_vector(3 downto 0) := "0000";
    GPIO_ADDRESS  : std_logic_vector(31 downto 0) := x"f0000000";
    STS_ADDRESS   : std_logic_vector(31 downto 0) := x"f0000004"
  );
  port (
    -- Inputs
    clk              : in  std_logic;
    rstn             : in  std_logic;
    uart_rxd         : in  std_logic;
    mem_awready      : in  std_logic;
    mem_wready       : in  std_logic;
    mem_bvalid       : in  std_logic;
    mem_bresp        : in  std_logic_vector(1 downto 0);
    mem_bid          : in  std_logic_vector(3 downto 0);
    mem_arready      : in  std_logic;
    mem_rvalid       : in  std_logic;
    mem_rdata        : in  std_logic_vector(31 downto 0);
    mem_rresp        : in  std_logic_vector(1 downto 0);
    mem_rid          : in  std_logic_vector(3 downto 0);
    mem_rlast        : in  std_logic;
    gpio_inputs      : in  std_logic_vector(31 downto 0);

    -- Outputs
    uart_txd         : out std_logic;
    mem_awvalid      : out std_logic;
    mem_awaddr       : out std_logic_vector(31 downto 0);
    mem_awid         : out std_logic_vector(3 downto 0);
    mem_awlen        : out std_logic_vector(7 downto 0);
    mem_awburst      : out std_logic_vector(1 downto 0);
    mem_wvalid       : out std_logic;
    mem_wdata        : out std_logic_vector(31 downto 0);
    mem_wstrb        : out std_logic_vector(3 downto 0);
    mem_wlast        : out std_logic;
    mem_bready       : out std_logic;
    mem_arvalid      : out std_logic;
    mem_araddr       : out std_logic_vector(31 downto 0);
    mem_arid         : out std_logic_vector(3 downto 0);
    mem_arlen        : out std_logic_vector(7 downto 0);
    mem_arburst      : out std_logic_vector(1 downto 0);
    mem_rready       : out std_logic;
    gpio_outputs     : out std_logic_vector(31 downto 0)
  );
end entity dbg_bridge_wrapper;

architecture rtl of dbg_bridge_wrapper is

  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_PARAMETER : string;

  ATTRIBUTE X_INTERFACE_INFO of clk: SIGNAL is "xilinx.com:signal:clock:1.0 clk CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER of clk: SIGNAL is "ASSOCIATED_BUSIF mem, ASSOCIATED_RESET rstn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0";

  ATTRIBUTE X_INTERFACE_INFO of rstn: SIGNAL is "xilinx.com:signal:reset:1.0 rstn RST";
  ATTRIBUTE X_INTERFACE_PARAMETER of rstn: SIGNAL is "POLARITY ACTIVE_LOW";


  ATTRIBUTE X_INTERFACE_INFO of uart_rxd: SIGNAL is "xilinx.com:interface:uart:1.0 UART RxD";
  ATTRIBUTE X_INTERFACE_INFO of uart_txd: SIGNAL is "xilinx.com:interface:uart:1.0 UART TxD";

  --ATTRIBUTE X_INTERFACE_INFO of gpio_outputs: SIGNAL is "xilinx.com:interface:gpio:1.0 gpio TRI_O";
  --ATTRIBUTE X_INTERFACE_INFO of gpio_inputs: SIGNAL is "xilinx.com:interface:gpio:1.0 gpio TRI_I";

  attribute X_INTERFACE_INFO of mem_awid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWID";
  attribute X_INTERFACE_INFO of mem_awaddr: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWADDR";
  attribute X_INTERFACE_INFO of mem_awlen: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWLEN";
  attribute X_INTERFACE_INFO of mem_awburst: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWBURST";
  attribute X_INTERFACE_INFO of mem_awvalid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWVALID";
  attribute X_INTERFACE_INFO of mem_awready: SIGNAL is "xilinx.com:interface:aximm:1.0 mem AWREADY";
  
  attribute X_INTERFACE_INFO of mem_wdata: SIGNAL is "xilinx.com:interface:aximm:1.0 mem WDATA";
  attribute X_INTERFACE_INFO of mem_wstrb: SIGNAL is "xilinx.com:interface:aximm:1.0 mem WSTRB";
  attribute X_INTERFACE_INFO of mem_wlast: SIGNAL is "xilinx.com:interface:aximm:1.0 mem WLAST";
  attribute X_INTERFACE_INFO of mem_wvalid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem WVALID";
  attribute X_INTERFACE_INFO of mem_wready: SIGNAL is "xilinx.com:interface:aximm:1.0 mem WREADY";
  
  attribute X_INTERFACE_INFO of mem_bid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem BID";
  attribute X_INTERFACE_INFO of mem_bresp: SIGNAL is "xilinx.com:interface:aximm:1.0 mem BRESP";
  attribute X_INTERFACE_INFO of mem_bvalid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem BVALID";
  attribute X_INTERFACE_INFO of mem_bready: SIGNAL is "xilinx.com:interface:aximm:1.0 mem BREADY";
  
  attribute X_INTERFACE_INFO of mem_arid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARID";
  attribute X_INTERFACE_INFO of mem_araddr: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARADDR";
  attribute X_INTERFACE_INFO of mem_arlen: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARLEN";
  attribute X_INTERFACE_INFO of mem_arburst: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARBURST";
  attribute X_INTERFACE_INFO of mem_arvalid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARVALID";
  attribute X_INTERFACE_INFO of mem_arready: SIGNAL is "xilinx.com:interface:aximm:1.0 mem ARREADY";
  
  attribute X_INTERFACE_INFO of mem_rid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RID";
  attribute X_INTERFACE_INFO of mem_rdata: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RDATA";
  attribute X_INTERFACE_INFO of mem_rresp: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RRESP";
  attribute X_INTERFACE_INFO of mem_rlast: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RLAST";
  attribute X_INTERFACE_INFO of mem_rvalid: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RVALID";
  attribute X_INTERFACE_INFO of mem_rready: SIGNAL is "xilinx.com:interface:aximm:1.0 mem RREADY";



  component dbg_bridge
    generic (
      CLK_FREQ      : integer;
      UART_SPEED    : integer;
      AXI_ID        : integer;
      GPIO_ADDRESS  : integer;
      STS_ADDRESS   : integer
    );
    port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      uart_rxd_i     : in  std_logic;
      mem_awready_i  : in  std_logic;
      mem_wready_i   : in  std_logic;
      mem_bvalid_i   : in  std_logic;
      mem_bresp_i    : in  std_logic_vector(1 downto 0);
      mem_bid_i      : in  std_logic_vector(3 downto 0);
      mem_arready_i  : in  std_logic;
      mem_rvalid_i   : in  std_logic;
      mem_rdata_i    : in  std_logic_vector(31 downto 0);
      mem_rresp_i    : in  std_logic_vector(1 downto 0);
      mem_rid_i      : in  std_logic_vector(3 downto 0);
      mem_rlast_i    : in  std_logic;
      gpio_inputs_i  : in  std_logic_vector(31 downto 0);
      uart_txd_o     : out std_logic;
      mem_awvalid_o  : out std_logic;
      mem_awaddr_o   : out std_logic_vector(31 downto 0);
      mem_awid_o     : out std_logic_vector(3 downto 0);
      mem_awlen_o    : out std_logic_vector(7 downto 0);
      mem_awburst_o  : out std_logic_vector(1 downto 0);
      mem_wvalid_o   : out std_logic;
      mem_wdata_o    : out std_logic_vector(31 downto 0);
      mem_wstrb_o    : out std_logic_vector(3 downto 0);
      mem_wlast_o    : out std_logic;
      mem_bready_o   : out std_logic;
      mem_arvalid_o  : out std_logic;
      mem_araddr_o   : out std_logic_vector(31 downto 0);
      mem_arid_o     : out std_logic_vector(3 downto 0);
      mem_arlen_o    : out std_logic_vector(7 downto 0);
      mem_arburst_o  : out std_logic_vector(1 downto 0);
      mem_rready_o   : out std_logic;
      gpio_outputs_o : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  u_dbg_bridge : dbg_bridge
    generic map (
      CLK_FREQ      => CLK_FREQ,
      UART_SPEED    => UART_SPEED,
      AXI_ID        => to_integer(unsigned(AXI_ID)),
      GPIO_ADDRESS  => to_integer(unsigned(GPIO_ADDRESS)),
      STS_ADDRESS   => to_integer(unsigned(STS_ADDRESS))
    )
    port map (
      clk_i          => clk,
      rst_i          => not rstn,
      uart_rxd_i     => uart_rxd,
      mem_awready_i  => mem_awready,
      mem_wready_i   => mem_wready,
      mem_bvalid_i   => mem_bvalid,
      mem_bresp_i    => mem_bresp,
      mem_bid_i      => mem_bid,
      mem_arready_i  => mem_arready,
      mem_rvalid_i   => mem_rvalid,
      mem_rdata_i    => mem_rdata,
      mem_rresp_i    => mem_rresp,
      mem_rid_i      => mem_rid,
      mem_rlast_i    => mem_rlast,
      gpio_inputs_i  => gpio_inputs,
      uart_txd_o     => uart_txd,
      mem_awvalid_o  => mem_awvalid,
      mem_awaddr_o   => mem_awaddr,
      mem_awid_o     => mem_awid,
      mem_awlen_o    => mem_awlen,
      mem_awburst_o  => mem_awburst,
      mem_wvalid_o   => mem_wvalid,
      mem_wdata_o    => mem_wdata,
      mem_wstrb_o    => mem_wstrb,
      mem_wlast_o    => mem_wlast,
      mem_bready_o   => mem_bready,
      mem_arvalid_o  => mem_arvalid,
      mem_araddr_o   => mem_araddr,
      mem_arid_o     => mem_arid,
      mem_arlen_o    => mem_arlen,
      mem_arburst_o  => mem_arburst,
      mem_rready_o   => mem_rready,
      gpio_outputs_o => gpio_outputs
    );

end architecture rtl;
