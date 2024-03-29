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

module sim;
  parameter int ClockPeriod = 100;
  parameter int ReceiverPort = 0;
  parameter int SenderPort = 0;
  parameter string Address = "";

  logic clk = 1;

  renode #(
      .BusControllersCount(1)
  ) renode (
      .clk(clk),
      .interrupts('0)
  );

  renode_ahb_if #(
      .AddressWidth(32),
      .DataWidth(32)
  ) ahb (
      clk
  );
  renode_ahb_manager renode_ahb_manager (
      .bus(ahb),
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

  wire hresp_nc;
  // Only one Subordinate doesn't require an Interconnect.
  assign ahb.hsel   = 1;
  assign ahb.hready = ahb.hreadyout;

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
      .HRESP({hresp_nc, ahb.hresp}),
      .HREADYin(ahb.hready),
      .HREADYout(ahb.hreadyout)
  );
endmodule
