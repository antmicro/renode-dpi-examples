//
//  Copyright 2024 Antmicro
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

`timescale 1ns / 1ps

import renode_pkg::renode_runtime;

module sim;
  parameter int unsigned AXIDataWidth = 64;
  parameter int ClockPeriod = 100;

  logic clk = 1;

  logic [4:0] interrupts;
  logic trigger;

  renode_runtime runtime = new();
  renode #(
      .RenodeInputsCount(5),
      .RenodeOutputsCount(1),
      .RenodeToCosimCount(1)
  ) renode (
      .runtime(runtime),
      .clk(clk),
      .renode_inputs(interrupts),
      .renode_outputs(trigger)
  );

  renode_axi_if #(.DataWidth(AXIDataWidth)) axi (clk);
  renode_axi_manager renode_axi_manager (
      .runtime(runtime),
      .bus(axi)
  );

  initial begin
    runtime.connect_plus_args();
    renode.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    renode.receive_and_handle_message();
    if (!runtime.connection.is_connected()) $finish;
  end

  always #(ClockPeriod / 2) clk = ~clk;

  localparam int unsigned AXIAddrWidth = 32;
  localparam int unsigned AXITransactionIdWidth = 8;
  localparam int unsigned AXIStrobeWidth = AXIDataWidth / 8;

  wire [AXITransactionIdWidth-1:0] m1_axi_awid, m2_axi_awid;
  wire [AXIAddrWidth-1:0] m1_axi_awaddr, m2_axi_awaddr;
  wire [7:0] m1_axi_awlen, m2_axi_awlen;
  wire [2:0] m1_axi_awsize, m2_axi_awsize;
  wire [1:0] m1_axi_awburst, m2_axi_awburst;
  wire m1_axi_awlock, m2_axi_awlock;
  wire [3:0] m1_axi_awcache, m2_axi_awcache;
  wire [2:0] m1_axi_awprot, m2_axi_awprot;
  wire m1_axi_awvalid, m2_axi_awvalid;
  wire m1_axi_awready, m2_axi_awready;
  wire [AXIDataWidth-1:0] m1_axi_wdata, m2_axi_wdata;
  wire [AXIStrobeWidth-1:0] m1_axi_wstrb, m2_axi_wstrb;
  wire m1_axi_wlast, m2_axi_wlast;
  wire m1_axi_wvalid, m2_axi_wvalid;
  wire m1_axi_wready, m2_axi_wready;
  wire [AXITransactionIdWidth-1:0] m1_axi_bid, m2_axi_bid;
  wire [1:0] m1_axi_bresp, m2_axi_bresp;
  wire m1_axi_bvalid, m2_axi_bvalid;
  wire m1_axi_bready, m2_axi_bready;
  wire [AXITransactionIdWidth-1:0] m1_axi_arid, m2_axi_arid;
  wire [AXIAddrWidth-1:0] m1_axi_araddr, m2_axi_araddr;
  wire [7:0] m1_axi_arlen, m2_axi_arlen;
  wire [2:0] m1_axi_arsize, m2_axi_arsize;
  wire [1:0] m1_axi_arburst, m2_axi_arburst;
  wire m1_axi_arlock, m2_axi_arlock;
  wire [3:0] m1_axi_arcache, m2_axi_arcache;
  wire [2:0] m1_axi_arprot, m2_axi_arprot;
  wire m1_axi_arvalid, m2_axi_arvalid;
  wire m1_axi_arready, m2_axi_arready;
  wire [AXITransactionIdWidth-1:0] m1_axi_rid, m2_axi_rid;
  wire [AXIDataWidth-1:0] m1_axi_rdata, m2_axi_rdata;
  wire [1:0] m1_axi_rresp, m2_axi_rresp;
  wire m1_axi_rlast, m2_axi_rlast;
  wire m1_axi_rvalid, m2_axi_rvalid;
  wire m1_axi_rready, m2_axi_rready;

  axi_interconnect #(
      .S_COUNT(1),
      .M_COUNT(2),
      .M_REGIONS(1),
      .M_BASE_ADDR({32'h100000, 32'h300000}),
      .M_ADDR_WIDTH(32'd20),
      .DATA_WIDTH(AXIDataWidth)
  ) axi_interconnect (
      .clk(clk),
      .rst(~axi.areset_n),

      .s_axi_awid(axi.awid),
      .s_axi_awaddr(axi.awaddr),
      .s_axi_awlen(axi.awlen),
      .s_axi_awsize(axi.awsize),
      .s_axi_awburst(axi.awburst),
      .s_axi_awlock(axi.awlock),
      .s_axi_awcache(axi.awcache),
      .s_axi_awprot(axi.awprot),
      .s_axi_awqos(),
      .s_axi_awuser(),
      .s_axi_awvalid(axi.awvalid),
      .s_axi_awready(axi.awready),
      .s_axi_wdata(axi.wdata),
      .s_axi_wstrb(axi.wstrb),
      .s_axi_wlast(axi.wlast),
      .s_axi_wuser(),
      .s_axi_wvalid(axi.wvalid),
      .s_axi_wready(axi.wready),
      .s_axi_bid(axi.bid),
      .s_axi_bresp(axi.bresp),
      .s_axi_buser(),
      .s_axi_bvalid(axi.bvalid),
      .s_axi_bready(axi.bready),
      .s_axi_arid(axi.arid),
      .s_axi_araddr(axi.araddr),
      .s_axi_arlen(axi.arlen),
      .s_axi_arsize(axi.arsize),
      .s_axi_arburst(axi.arburst),
      .s_axi_arlock(axi.arlock),
      .s_axi_arcache(axi.arcache),
      .s_axi_arprot(axi.arprot),
      .s_axi_arqos(),
      .s_axi_aruser(),
      .s_axi_arvalid(axi.arvalid),
      .s_axi_arready(axi.arready),
      .s_axi_rid(axi.rid),
      .s_axi_rdata(axi.rdata),
      .s_axi_rresp(axi.rresp),
      .s_axi_rlast(axi.rlast),
      .s_axi_ruser(),
      .s_axi_rvalid(axi.rvalid),
      .s_axi_rready(axi.rready),

      .m_axi_awid({m1_axi_awid, m2_axi_awid}),
      .m_axi_awaddr({m1_axi_awaddr, m2_axi_awaddr}),
      .m_axi_awlen({m1_axi_awlen, m2_axi_awlen}),
      .m_axi_awsize({m1_axi_awsize, m2_axi_awsize}),
      .m_axi_awburst({m1_axi_awburst, m2_axi_awburst}),
      .m_axi_awlock({m1_axi_awlock, m2_axi_awlock}),
      .m_axi_awcache({m1_axi_awcache, m2_axi_awcache}),
      .m_axi_awprot({m1_axi_awprot, m2_axi_awprot}),
      .m_axi_awqos(),
      .m_axi_awregion(),
      .m_axi_awuser(),
      .m_axi_awvalid({m1_axi_awvalid, m2_axi_awvalid}),
      .m_axi_awready({m1_axi_awready, m2_axi_awready}),
      .m_axi_wdata({m1_axi_wdata, m2_axi_wdata}),
      .m_axi_wstrb({m1_axi_wstrb, m2_axi_wstrb}),
      .m_axi_wlast({m1_axi_wlast, m2_axi_wlast}),
      .m_axi_wuser(),
      .m_axi_wvalid({m1_axi_wvalid, m2_axi_wvalid}),
      .m_axi_wready({m1_axi_wready, m2_axi_wready}),
      .m_axi_bid({m1_axi_bid, m2_axi_bid}),
      .m_axi_bresp({m1_axi_bresp, m2_axi_bresp}),
      .m_axi_buser(),
      .m_axi_bvalid({m1_axi_bvalid, m2_axi_bvalid}),
      .m_axi_bready({m1_axi_bready, m2_axi_bready}),
      .m_axi_arid({m1_axi_arid, m2_axi_arid}),
      .m_axi_araddr({m1_axi_araddr, m2_axi_araddr}),
      .m_axi_arlen({m1_axi_arlen, m2_axi_arlen}),
      .m_axi_arsize({m1_axi_arsize, m2_axi_arsize}),
      .m_axi_arburst({m1_axi_arburst, m2_axi_arburst}),
      .m_axi_arlock({m1_axi_arlock, m2_axi_arlock}),
      .m_axi_arcache({m1_axi_arcache, m2_axi_arcache}),
      .m_axi_arprot({m1_axi_arprot, m2_axi_arprot}),
      .m_axi_arqos(),
      .m_axi_arregion(),
      .m_axi_aruser(),
      .m_axi_arvalid({m1_axi_arvalid, m2_axi_arvalid}),
      .m_axi_arready({m1_axi_arready, m2_axi_arready}),
      .m_axi_rid({m1_axi_rid, m2_axi_rid}),
      .m_axi_rdata({m1_axi_rdata, m2_axi_rdata}),
      .m_axi_rresp({m1_axi_rresp, m2_axi_rresp}),
      .m_axi_rlast({m1_axi_rlast, m2_axi_rlast}),
      .m_axi_ruser(),
      .m_axi_rvalid({m1_axi_rvalid, m2_axi_rvalid}),
      .m_axi_rready({m1_axi_rready, m2_axi_rready})

  );

  axi_ram #(
      .DATA_WIDTH(AXIDataWidth)
  ) ram_1 (
      .clk(clk),
      .rst(~axi.areset_n),
      .s_axi_awid(m1_axi_awid),
      .s_axi_awaddr(m1_axi_awaddr[19:0]),
      .s_axi_awlen(m1_axi_awlen),
      .s_axi_awsize(m1_axi_awsize),
      .s_axi_awburst(m1_axi_awburst),
      .s_axi_awlock(m1_axi_awlock),
      .s_axi_awcache(m1_axi_awcache),
      .s_axi_awprot(m1_axi_awprot),
      .s_axi_awvalid(m1_axi_awvalid),
      .s_axi_awready(m1_axi_awready),
      .s_axi_wdata(m1_axi_wdata),
      .s_axi_wstrb(m1_axi_wstrb),
      .s_axi_wlast(m1_axi_wlast),
      .s_axi_wvalid(m1_axi_wvalid),
      .s_axi_wready(m1_axi_wready),
      .s_axi_bid(m1_axi_bid),
      .s_axi_bresp(m1_axi_bresp),
      .s_axi_bvalid(m1_axi_bvalid),
      .s_axi_bready(m1_axi_bready),
      .s_axi_arid(m1_axi_arid),
      .s_axi_araddr(m1_axi_araddr[19:0]),
      .s_axi_arlen(m1_axi_arlen),
      .s_axi_arsize(m1_axi_arsize),
      .s_axi_arburst(m1_axi_arburst),
      .s_axi_arlock(m1_axi_arlock),
      .s_axi_arcache(m1_axi_arcache),
      .s_axi_arprot(m1_axi_arprot),
      .s_axi_arvalid(m1_axi_arvalid),
      .s_axi_arready(m1_axi_arready),
      .s_axi_rid(m1_axi_rid),
      .s_axi_rdata(m1_axi_rdata),
      .s_axi_rresp(m1_axi_rresp),
      .s_axi_rlast(m1_axi_rlast),
      .s_axi_rvalid(m1_axi_rvalid),
      .s_axi_rready(m1_axi_rready)
  );

  axi_ram #(
      .DATA_WIDTH(AXIDataWidth)
  ) ram_2 (
      .clk(clk),
      .rst(~axi.areset_n),
      .s_axi_awid(m2_axi_awid),
      .s_axi_awaddr(m2_axi_awaddr[19:0]),
      .s_axi_awlen(m2_axi_awlen),
      .s_axi_awsize(m2_axi_awsize),
      .s_axi_awburst(m2_axi_awburst),
      .s_axi_awlock(m2_axi_awlock),
      .s_axi_awcache(m2_axi_awcache),
      .s_axi_awprot(m2_axi_awprot),
      .s_axi_awvalid(m2_axi_awvalid),
      .s_axi_awready(m2_axi_awready),
      .s_axi_wdata(m2_axi_wdata),
      .s_axi_wstrb(m2_axi_wstrb),
      .s_axi_wlast(m2_axi_wlast),
      .s_axi_wvalid(m2_axi_wvalid),
      .s_axi_wready(m2_axi_wready),
      .s_axi_bid(m2_axi_bid),
      .s_axi_bresp(m2_axi_bresp),
      .s_axi_bvalid(m2_axi_bvalid),
      .s_axi_bready(m2_axi_bready),
      .s_axi_arid(m2_axi_arid),
      .s_axi_araddr(m2_axi_araddr[19:0]),
      .s_axi_arlen(m2_axi_arlen),
      .s_axi_arsize(m2_axi_arsize),
      .s_axi_arburst(m2_axi_arburst),
      .s_axi_arlock(m2_axi_arlock),
      .s_axi_arcache(m2_axi_arcache),
      .s_axi_arprot(m2_axi_arprot),
      .s_axi_arvalid(m2_axi_arvalid),
      .s_axi_arready(m2_axi_arready),
      .s_axi_rid(m2_axi_rid),
      .s_axi_rdata(m2_axi_rdata),
      .s_axi_rresp(m2_axi_rresp),
      .s_axi_rlast(m2_axi_rlast),
      .s_axi_rvalid(m2_axi_rvalid),
      .s_axi_rready(m2_axi_rready)
  );

  gpio_tester gpio_tester (
        .clk(clk),
        .reset(axi.areset_n),
        .trigger(trigger),
        .out(interrupts)
  );
endmodule
