//
// Copyright (c) 2010-2023 Antmicro
//
// This file is licensed under the MIT License.
// Full license text is available in 'licenses/MIT.txt'.
//

`timescale 1ns / 1ps

module sim;
  parameter int ClockPeriod = 100;
  parameter int ReceiverPort = 0;
  parameter int SenderPort = 0;
  parameter string Address = "";

  logic clk = 1;

  renode renode (
      .clk(clk),
      .interrupts('0)
  );

  renode_axi_if #(.AddressWidth(20)) axi (clk);
  renode_axi_manager renode_axi_manager (
      .bus(axi),
      .connection(renode.bus_controller)
  );

  initial begin
    if (Address != "") renode.connection.connect(ReceiverPort, SenderPort, Address);
    renode.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    renode.receive_and_handle_message();
    if (!renode.connection.is_connected()) $finish;
  end

  always #(ClockPeriod / 2) clk = ~clk;

  axi_ram dut (
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
      .s_axi_awvalid(axi.awvalid),
      .s_axi_awready(axi.awready),
      .s_axi_wdata(axi.wdata),
      .s_axi_wstrb(axi.wstrb),
      .s_axi_wlast(axi.wlast),
      .s_axi_wvalid(axi.wvalid),
      .s_axi_wready(axi.wready),
      .s_axi_bid(axi.bid),
      .s_axi_bresp(axi.bresp),
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
      .s_axi_arvalid(axi.arvalid),
      .s_axi_arready(axi.arready),
      .s_axi_rid(axi.rid),
      .s_axi_rdata(axi.rdata),
      .s_axi_rresp(axi.rresp),
      .s_axi_rlast(axi.rlast),
      .s_axi_rvalid(axi.rvalid),
      .s_axi_rready(axi.rready)
  );
endmodule
