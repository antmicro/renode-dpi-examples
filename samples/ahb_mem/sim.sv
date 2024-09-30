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
  parameter int ClockPeriod = 100;

  logic clk = 1;

  renode_runtime runtime = new();
  renode #(
      .BusControllersCount(1)
  ) renode (
      .runtime(runtime),
      .clk(clk),
      .renode_inputs('0),
      .renode_outputs()
  );

  renode_ahb_if #(
      .AddressWidth(32),
      .DataWidth(32)
  ) ahb (
      clk
  );
  renode_ahb_manager renode_ahb_manager (
      .runtime(runtime),
      .bus(ahb)
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

  logic [1:0] hresp;
  // Only one Subordinate doesn't require an Interconnect.
  assign ahb.hsel   = 1;
  assign ahb.hready = ahb.hreadyout;
  assign ahb.hresp = hresp[0];

  mem_ahb dut (
      .HCLK(clk),
      .HRESETn(ahb.hresetn),
      .HSEL(ahb.hsel),
      .HADDR(ahb.haddr),
      .HTRANS(ahb.htrans),
      .HWRITE(ahb.hwrite),
      .HSIZE(ahb.hsize),
      .HBURST(ahb.hburst),
      .HWDATA(ahb.hwdata),
      .HRDATA(ahb.hrdata),
      .HRESP(hresp),
      .HREADYin(ahb.hready),
      .HREADYout(ahb.hreadyout)
  );
endmodule
