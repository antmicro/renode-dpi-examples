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
  logic message_received;

  renode #(.AXIManagerAddressWidth(20)) renode (clk);

  initial begin
    if (Address != "") renode.connection.connect(ReceiverPort, SenderPort, Address);
    renode.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    renode.receive_and_handle_message(message_received);
    if(!message_received) $finish;
  end

  always #(ClockPeriod / 2) clk = ~clk;

  axi_ram dut (
      .clk(clk),
      .rst(~renode.axi_manager.areset_n),
      .s_axi_awid(renode.axi_manager.awid),
      .s_axi_awaddr(renode.axi_manager.awaddr),
      .s_axi_awlen(renode.axi_manager.awlen),
      .s_axi_awsize(renode.axi_manager.awsize),
      .s_axi_awburst(renode.axi_manager.awburst),
      .s_axi_awlock(renode.axi_manager.awlock),
      .s_axi_awcache(renode.axi_manager.awcache),
      .s_axi_awprot(renode.axi_manager.awprot),
      .s_axi_awvalid(renode.axi_manager.awvalid),
      .s_axi_awready(renode.axi_manager.awready),
      .s_axi_wdata(renode.axi_manager.wdata),
      .s_axi_wstrb(renode.axi_manager.wstrb),
      .s_axi_wlast(renode.axi_manager.wlast),
      .s_axi_wvalid(renode.axi_manager.wvalid),
      .s_axi_wready(renode.axi_manager.wready),
      .s_axi_bid(renode.axi_manager.bid),
      .s_axi_bresp(renode.axi_manager.bresp),
      .s_axi_bvalid(renode.axi_manager.bvalid),
      .s_axi_bready(renode.axi_manager.bready),
      .s_axi_arid(renode.axi_manager.arid),
      .s_axi_araddr(renode.axi_manager.araddr),
      .s_axi_arlen(renode.axi_manager.arlen),
      .s_axi_arsize(renode.axi_manager.arsize),
      .s_axi_arburst(renode.axi_manager.arburst),
      .s_axi_arlock(renode.axi_manager.arlock),
      .s_axi_arcache(renode.axi_manager.arcache),
      .s_axi_arprot(renode.axi_manager.arprot),
      .s_axi_arvalid(renode.axi_manager.arvalid),
      .s_axi_arready(renode.axi_manager.arready),
      .s_axi_rid(renode.axi_manager.rid),
      .s_axi_rdata(renode.axi_manager.rdata),
      .s_axi_rresp(renode.axi_manager.rresp),
      .s_axi_rlast(renode.axi_manager.rlast),
      .s_axi_rvalid(renode.axi_manager.rvalid),
      .s_axi_rready(renode.axi_manager.rready)
  );
endmodule
