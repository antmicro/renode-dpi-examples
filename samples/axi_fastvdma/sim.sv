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
  bit message_received;

  renode #(.AXISubordinateTransactionIdWidth(4)) renode (clk);

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

  DMATop dut (
      .clock(clk),
      .reset(~renode.axi_manager.areset_n),
      .io_control_aw_awaddr(renode.axi_manager.awaddr),
      .io_control_aw_awprot(renode.axi_manager.awprot),
      .io_control_aw_awvalid(renode.axi_manager.awvalid),
      .io_control_aw_awready(renode.axi_manager.awready),
      .io_control_w_wdata(renode.axi_manager.wdata),
      .io_control_w_wstrb(renode.axi_manager.wstrb),
      .io_control_w_wvalid(renode.axi_manager.wvalid),
      .io_control_w_wready(renode.axi_manager.wready),
      .io_control_b_bresp(renode.axi_manager.bresp),
      .io_control_b_bvalid(renode.axi_manager.bvalid),
      .io_control_b_bready(renode.axi_manager.bready),
      .io_control_ar_araddr(renode.axi_manager.araddr),
      .io_control_ar_arprot(renode.axi_manager.arprot),
      .io_control_ar_arvalid(renode.axi_manager.arvalid),
      .io_control_ar_arready(renode.axi_manager.arready),
      .io_control_r_rdata(renode.axi_manager.rdata),
      .io_control_r_rresp(renode.axi_manager.rresp),
      .io_control_r_rvalid(renode.axi_manager.rvalid),
      .io_control_r_rready(renode.axi_manager.rready),

      .io_read_ar_arid(renode.axi_subordinate.arid),
      .io_read_ar_araddr(renode.axi_subordinate.araddr),
      .io_read_ar_arlen(renode.axi_subordinate.arlen),
      .io_read_ar_arsize(renode.axi_subordinate.arsize),
      .io_read_ar_arburst(renode.axi_subordinate.arburst),
      .io_read_ar_arlock(renode.axi_subordinate.arlock),
      .io_read_ar_arcache(renode.axi_subordinate.arcache),
      .io_read_ar_arprot(renode.axi_subordinate.arprot),
      .io_read_ar_arvalid(renode.axi_subordinate.arvalid),
      .io_read_ar_arready(renode.axi_subordinate.arready),
      .io_read_r_rid(renode.axi_subordinate.rid),
      .io_read_r_rdata(renode.axi_subordinate.rdata),
      .io_read_r_rresp(renode.axi_subordinate.rresp),
      .io_read_r_rlast(renode.axi_subordinate.rlast),
      .io_read_r_rvalid(renode.axi_subordinate.rvalid),
      .io_read_r_rready(renode.axi_subordinate.rready),
      .io_write_aw_awid(renode.axi_subordinate.awid),
      .io_write_aw_awaddr(renode.axi_subordinate.awaddr),
      .io_write_aw_awlen(renode.axi_subordinate.awlen),
      .io_write_aw_awsize(renode.axi_subordinate.awsize),
      .io_write_aw_awburst(renode.axi_subordinate.awburst),
      .io_write_aw_awlock(renode.axi_subordinate.awlock),
      .io_write_aw_awcache(renode.axi_subordinate.awcache),
      .io_write_aw_awprot(renode.axi_subordinate.awprot),
      .io_write_aw_awvalid(renode.axi_subordinate.awvalid),
      .io_write_aw_awready(renode.axi_subordinate.awready),
      .io_write_w_wdata(renode.axi_subordinate.wdata),
      .io_write_w_wstrb(renode.axi_subordinate.wstrb),
      .io_write_w_wlast(renode.axi_subordinate.wlast),
      .io_write_w_wvalid(renode.axi_subordinate.wvalid),
      .io_write_w_wready(renode.axi_subordinate.wready),
      .io_write_b_bid(renode.axi_subordinate.bid),
      .io_write_b_bresp(renode.axi_subordinate.bresp),
      .io_write_b_bvalid(renode.axi_subordinate.bvalid),
      .io_write_b_bready(renode.axi_subordinate.bready),

      .io_irq_readerDone(renode.gpio.outputs[1]),
      .io_irq_writerDone(renode.gpio.outputs[0]),

      // The rest of signals are intentionally unused.
      .io_read_ar_arqos(),
      .io_write_aw_awqos(),
      .io_read_aw_awid(),
      .io_read_aw_awaddr(),
      .io_read_aw_awlen(),
      .io_read_aw_awsize(),
      .io_read_aw_awburst(),
      .io_read_aw_awlock(),
      .io_read_aw_awcache(),
      .io_read_aw_awprot(),
      .io_read_aw_awqos(),
      .io_read_aw_awvalid(),
      .io_read_aw_awready(),
      .io_read_w_wdata(),
      .io_read_w_wstrb(),
      .io_read_w_wlast(),
      .io_read_w_wvalid(),
      .io_read_w_wready(),
      .io_read_b_bid(),
      .io_read_b_bresp(),
      .io_read_b_bvalid(),
      .io_read_b_bready(),
      .io_write_ar_arid(),
      .io_write_ar_araddr(),
      .io_write_ar_arlen(),
      .io_write_ar_arsize(),
      .io_write_ar_arburst(),
      .io_write_ar_arlock(),
      .io_write_ar_arcache(),
      .io_write_ar_arprot(),
      .io_write_ar_arqos(),
      .io_write_ar_arvalid(),
      .io_write_ar_arready(),
      .io_write_r_rid(),
      .io_write_r_rdata(),
      .io_write_r_rresp(),
      .io_write_r_rlast(),
      .io_write_r_rvalid(),
      .io_write_r_rready(),
      .io_sync_readerSync(),
      .io_sync_writerSync()
  );
endmodule
