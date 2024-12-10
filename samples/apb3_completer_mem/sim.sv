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
  parameter int ClockPeriod = 100;

  parameter int unsigned APB3BusAddressWidth = 20;
  parameter int unsigned APB3BusDataWidth = 32;

  logic clk = 1;

  renode_runtime runtime = new();
  renode #(
      .RenodeToCosimCount(1)
  ) renode (
      .runtime(runtime),
      .clk(clk),
      .renode_inputs('0),
      .renode_outputs()
  );

  renode_apb3_if #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) apb3 (clk);

  renode_apb3_requester renode_apb3_requester (
      .runtime(runtime),
      .bus(apb3)
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

  // APB3 Completer
  apb3_completer_mem #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) dut (
      .clk(clk),
      .rst_n(apb3.presetn),
      .paddr(apb3.paddr),
      .pwrite(apb3.pwrite),
      .psel(apb3.pselx),
      .penable(apb3.penable),
      .pwdata(apb3.pwdata),
      .prdata(apb3.prdata),
      .pready(apb3.pready)
  );
  // Base Completer needn't provide PSLVERR.
  assign apb3.pslverr = 1'b0;

endmodule
