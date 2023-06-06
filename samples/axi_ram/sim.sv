`timescale 1ns / 1ps

`include "renode_axi.sv"

module sim;
  parameter int ClockPeriod = 10;
  parameter int ReceiverPort = 0;
  parameter int SenderPort = 0;
  parameter string Address = "";

  logic clk = 0;

  axi_if bus (clk);

  static renode::connection connection = new();
  static renode::message_t  message;

  initial begin
    if (Address != "") connection.connect(ReceiverPort, SenderPort, Address);
    bus.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    if (!connection.receive(message)) $finish;
    bus.handle_request(connection, message);
  end

  always #(ClockPeriod / 2) clk = ~clk;

  axi_ram dut (
      .clk(clk),
      .rst(~bus.areset_n),
      .s_axi_awid(bus.awid),
      .s_axi_awaddr(bus.awaddr),
      .s_axi_awlen(bus.awlen),
      .s_axi_awsize(bus.awsize),
      .s_axi_awburst(bus.awburst),
      .s_axi_awlock(bus.awlock),
      .s_axi_awcache(bus.awcache),
      .s_axi_awprot(bus.awprot),
      .s_axi_awvalid(bus.awvalid),
      .s_axi_awready(bus.awready),
      .s_axi_wdata(bus.wdata),
      .s_axi_wstrb(bus.wstrb),
      .s_axi_wlast(bus.wlast),
      .s_axi_wvalid(bus.wvalid),
      .s_axi_wready(bus.wready),
      .s_axi_bid(bus.bid),
      .s_axi_bresp(bus.bresp),
      .s_axi_bvalid(bus.bvalid),
      .s_axi_bready(bus.bready),
      .s_axi_arid(bus.arid),
      .s_axi_araddr(bus.araddr),
      .s_axi_arlen(bus.arlen),
      .s_axi_arsize(bus.arsize),
      .s_axi_arburst(bus.arburst),
      .s_axi_arlock(bus.arlock),
      .s_axi_arcache(bus.arcache),
      .s_axi_arprot(bus.arprot),
      .s_axi_arvalid(bus.arvalid),
      .s_axi_arready(bus.arready),
      .s_axi_rid(bus.rid),
      .s_axi_rdata(bus.rdata),
      .s_axi_rresp(bus.rresp),
      .s_axi_rlast(bus.rlast),
      .s_axi_rvalid(bus.rvalid),
      .s_axi_rready(bus.rready)
  );
endmodule
