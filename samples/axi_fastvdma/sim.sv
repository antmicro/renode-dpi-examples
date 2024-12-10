//
//  Copyright 2023 Antmicro
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
  parameter int unsigned AXIDataWidth = 32;
  parameter int ClockPeriod = 100;

  logic clk = 1;
  logic [1:0] interrupts;

  renode_runtime runtime = new();
  renode #(
      .RenodeToCosimCount(1),
      .CosimToRenodeCount(1),
      .RenodeInputsCount(2)
  ) renode (
      .runtime(runtime),
      .clk(clk),
      .renode_inputs(interrupts),
      .renode_outputs()
  );

  renode_axi_if axi_control (clk);
  renode_axi_manager renode_axi_manager (
      .runtime(runtime),
      .bus(axi_control)
  );

  renode_axi_if #(
      .DataWidth(AXIDataWidth),
      .TransactionIdWidth(4)
  ) axi_data (clk);
  renode_axi_subordinate renode_axi_subordinate (
      .runtime(runtime),
      .bus(axi_data)
  );

  initial begin
    runtime.connect_plus_args();
    renode.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    renode.receive_and_handle_message();
    if (!runtime.is_connected()) $finish;
  end

  always #(ClockPeriod / 2) clk = ~clk;

  DMATop dut (
      .clock(clk),
      .reset(~axi_control.areset_n),
      .io_control_aw_awaddr(axi_control.awaddr),
      .io_control_aw_awprot(axi_control.awprot),
      .io_control_aw_awvalid(axi_control.awvalid),
      .io_control_aw_awready(axi_control.awready),
      .io_control_w_wdata(axi_control.wdata),
      .io_control_w_wstrb(axi_control.wstrb),
      .io_control_w_wvalid(axi_control.wvalid),
      .io_control_w_wready(axi_control.wready),
      .io_control_b_bresp(axi_control.bresp),
      .io_control_b_bvalid(axi_control.bvalid),
      .io_control_b_bready(axi_control.bready),
      .io_control_ar_araddr(axi_control.araddr),
      .io_control_ar_arprot(axi_control.arprot),
      .io_control_ar_arvalid(axi_control.arvalid),
      .io_control_ar_arready(axi_control.arready),
      .io_control_r_rdata(axi_control.rdata),
      .io_control_r_rresp(axi_control.rresp),
      .io_control_r_rvalid(axi_control.rvalid),
      .io_control_r_rready(axi_control.rready),

      .io_read_ar_arid(axi_data.arid),
      .io_read_ar_araddr(axi_data.araddr),
      .io_read_ar_arlen(axi_data.arlen),
      .io_read_ar_arsize(axi_data.arsize),
      .io_read_ar_arburst(axi_data.arburst),
      .io_read_ar_arlock(axi_data.arlock),
      .io_read_ar_arcache(axi_data.arcache),
      .io_read_ar_arprot(axi_data.arprot),
      .io_read_ar_arvalid(axi_data.arvalid),
      .io_read_ar_arready(axi_data.arready),
      .io_read_r_rid(axi_data.rid),
      .io_read_r_rdata(axi_data.rdata),
      .io_read_r_rresp(axi_data.rresp),
      .io_read_r_rlast(axi_data.rlast),
      .io_read_r_rvalid(axi_data.rvalid),
      .io_read_r_rready(axi_data.rready),
      .io_write_aw_awid(axi_data.awid),
      .io_write_aw_awaddr(axi_data.awaddr),
      .io_write_aw_awlen(axi_data.awlen),
      .io_write_aw_awsize(axi_data.awsize),
      .io_write_aw_awburst(axi_data.awburst),
      .io_write_aw_awlock(axi_data.awlock),
      .io_write_aw_awcache(axi_data.awcache),
      .io_write_aw_awprot(axi_data.awprot),
      .io_write_aw_awvalid(axi_data.awvalid),
      .io_write_aw_awready(axi_data.awready),
      .io_write_w_wdata(axi_data.wdata),
      .io_write_w_wstrb(axi_data.wstrb),
      .io_write_w_wlast(axi_data.wlast),
      .io_write_w_wvalid(axi_data.wvalid),
      .io_write_w_wready(axi_data.wready),
      .io_write_b_bid(axi_data.bid),
      .io_write_b_bresp(axi_data.bresp),
      .io_write_b_bvalid(axi_data.bvalid),
      .io_write_b_bready(axi_data.bready),

      .io_irq_readerDone(interrupts[1]),
      .io_irq_writerDone(interrupts[0]),

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
