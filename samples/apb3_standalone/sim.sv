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
  parameter int unsigned ClockPeriod = 100;
  parameter int unsigned APB3BusAddressWidth = 20;
  parameter int unsigned APB3BusDataWidth = 32;

  typedef logic [APB3BusAddressWidth-1:0] address_t;
  typedef logic [APB3BusDataWidth-1:0] data_t;

  logic clk = 1;
  always #(ClockPeriod / 2) clk = ~clk;

  renode_apb3_if #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) apb3 (
    clk
  );

  apb3_requester_synth #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) dut_requester_synth (
      .apb3(apb3)
  );

  apb3_completer_mem #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) dut_completer (
      .clk(apb3.pclk),
      .rst_n(apb3.presetn),
      .paddr(apb3.paddr),
      .pwrite(apb3.pwrite),
      .psel(apb3.pselx),
      .penable(apb3.penable),
      .pwdata(apb3.pwdata),
      .prdata(apb3.prdata),
      .pready(apb3.pready)
  );
  // Base Completer needn't provide PSLVERR
  assign apb3.pslverr = 1'b0;

  // Each transfer takes time:
  // apb3_transfer (PreTransactionUI + PostTransactionUI + (2*Back2BackNum))
  // Back2back transfers take: 2+8+2*3=16 cycles
  // There are 2x8 W/R operations, so each transfer set takes
  // time_transfer_clk = 16*2*8 = 16*16
  // Adding margins to be safe (17 * 20)
  int time_transfer = ClockPeriod * 17 * 20; //FIXME: tie to parameters

  initial begin
    dut_requester_synth.mux_select = 1'b0;
    dut_requester_synth.start_n_single = '0;
    dut_requester_synth.start_n_b2b = '0;
    apb3.presetn = 0;
    repeat(2) @(posedge clk);
    apb3.presetn = 1;

    // Transfers
    #(10*ClockPeriod) begin
      dut_requester_synth.start_n_single = '1;
    end
    #(time_transfer) begin
      dut_requester_synth.mux_select = 1'b1;
      dut_requester_synth.start_n_single = '0;
      dut_requester_synth.start_n_b2b = '1;
    end
    #(time_transfer) begin
      dut_requester_synth.start_n_b2b  = '0;
    end
    $finish;
  end
endmodule
