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
      .RenodeToCosimCount(2),
      .CosimToRenodeCount(2)
  ) renode (
      .runtime(runtime),
      .clk(clk),
      .renode_inputs('0),
      .renode_outputs()
  );

  renode_axi_if #(.DataWidth(AXIDataWidth)) axi0 (clk);
  renode_axi_manager #(.RenodeToCosimIndex(0)) renode_axi_manager0 (
      .runtime(runtime),
      .bus(axi0)
  );

  renode_axi_if #(.DataWidth(AXIDataWidth)) axi1 (clk);
  renode_axi_manager #(.RenodeToCosimIndex(1)) renode_axi_manager1 (
      .runtime(runtime),
      .bus(axi1)
  );

  renode_ahb_if #(
    .AddressWidth(32),
    .DataWidth(32)
  ) ahb0 (
    clk
  );
  renode_ahb_subordinate #(.CosimToRenodeIndex(0)) renode_ahb_subordinate0 (
    .runtime(runtime),
    .bus(ahb0)
  );

  renode_ahb_if #(
    .AddressWidth(32),
    .DataWidth(32)
  ) ahb1 (
    clk
  );
  renode_ahb_subordinate #(.CosimToRenodeIndex(1)) renode_ahb_subordinate1 (
    .runtime(runtime),
    .bus(ahb1)
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

  axi_ram #(
      .DATA_WIDTH(AXIDataWidth)
  ) ram_1 (
      .clk(clk),
      .rst(~axi0.areset_n),
      .s_axi_awid(axi0.awid),
      .s_axi_awaddr(axi0.awaddr[19:0]),
      .s_axi_awlen(axi0.awlen),
      .s_axi_awsize(axi0.awsize),
      .s_axi_awburst(axi0.awburst),
      .s_axi_awlock(axi0.awlock),
      .s_axi_awcache(axi0.awcache),
      .s_axi_awprot(axi0.awprot),
      .s_axi_awvalid(axi0.awvalid),
      .s_axi_awready(axi0.awready),
      .s_axi_wdata(axi0.wdata),
      .s_axi_wstrb(axi0.wstrb),
      .s_axi_wlast(axi0.wlast),
      .s_axi_wvalid(axi0.wvalid),
      .s_axi_wready(axi0.wready),
      .s_axi_bid(axi0.bid),
      .s_axi_bresp(axi0.bresp),
      .s_axi_bvalid(axi0.bvalid),
      .s_axi_bready(axi0.bready),
      .s_axi_arid(axi0.arid),
      .s_axi_araddr(axi0.araddr),
      .s_axi_arlen(axi0.arlen),
      .s_axi_arsize(axi0.arsize),
      .s_axi_arburst(axi0.arburst),
      .s_axi_arlock(axi0.arlock),
      .s_axi_arcache(axi0.arcache),
      .s_axi_arprot(axi0.arprot),
      .s_axi_arvalid(axi0.arvalid),
      .s_axi_arready(axi0.arready),
      .s_axi_rid(axi0.rid),
      .s_axi_rdata(axi0.rdata),
      .s_axi_rresp(axi0.rresp),
      .s_axi_rlast(axi0.rlast),
      .s_axi_rvalid(axi0.rvalid),
      .s_axi_rready(axi0.rready)
  );

  axi_ram #(
      .DATA_WIDTH(AXIDataWidth)
  ) ram_2 (
      .clk(clk),
      .rst(~axi1.areset_n),
      .s_axi_awid(axi1.awid),
      .s_axi_awaddr(axi1.awaddr[19:0]),
      .s_axi_awlen(axi1.awlen),
      .s_axi_awsize(axi1.awsize),
      .s_axi_awburst(axi1.awburst),
      .s_axi_awlock(axi1.awlock),
      .s_axi_awcache(axi1.awcache),
      .s_axi_awprot(axi1.awprot),
      .s_axi_awvalid(axi1.awvalid),
      .s_axi_awready(axi1.awready),
      .s_axi_wdata(axi1.wdata),
      .s_axi_wstrb(axi1.wstrb),
      .s_axi_wlast(axi1.wlast),
      .s_axi_wvalid(axi1.wvalid),
      .s_axi_wready(axi1.wready),
      .s_axi_bid(axi1.bid),
      .s_axi_bresp(axi1.bresp),
      .s_axi_bvalid(axi1.bvalid),
      .s_axi_bready(axi1.bready),
      .s_axi_arid(axi1.arid),
      .s_axi_araddr(axi1.araddr),
      .s_axi_arlen(axi1.arlen),
      .s_axi_arsize(axi1.arsize),
      .s_axi_arburst(axi1.arburst),
      .s_axi_arlock(axi1.arlock),
      .s_axi_arcache(axi1.arcache),
      .s_axi_arprot(axi1.arprot),
      .s_axi_arvalid(axi1.arvalid),
      .s_axi_arready(axi1.arready),
      .s_axi_rid(axi1.rid),
      .s_axi_rdata(axi1.rdata),
      .s_axi_rresp(axi1.rresp),
      .s_axi_rlast(axi1.rlast),
      .s_axi_rvalid(axi1.rvalid),
      .s_axi_rready(axi1.rready)
  );

  assign ahb0.hsel   = 1;
  assign ahb0.hready = ahb0.hreadyout;
  ahb_manager_synth ahb_manager_synth0 (
    .HCLK(clk),
    .HRESETn(ahb0.hresetn),
    .HREADY(ahb0.hready),
    .HWRITE(ahb0.hwrite),
    .HADDR(ahb0.haddr),
    .HWDATA(ahb0.hwdata),
    .HSIZE(ahb0.hsize),
    .HTRANS(ahb0.htrans)
  );

  assign ahb1.hsel   = 1;
  assign ahb1.hready = ahb1.hreadyout;
  ahb_manager_synth ahb_manager_synth1 (
    .HCLK(clk),
    .HRESETn(ahb1.hresetn),
    .HREADY(ahb1.hready),
    .HWRITE(ahb1.hwrite),
    .HADDR(ahb1.haddr),
    .HWDATA(ahb1.hwdata),
    .HSIZE(ahb1.hsize),
    .HTRANS(ahb1.htrans)
  );
endmodule
