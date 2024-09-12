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
  wire  interrupt;

  renode #(
      .BusControllersCount(1),
      .BusPeripheralsCount(1)
  ) renode (
      .clk(clk),
      .renode_inputs(interrupt),
      .renode_outputs()
  );

  renode_ahb_if #(
      .AddressWidth(32),
      .DataWidth(32)
  ) ahb_control (
      clk
  );
  renode_ahb_manager renode_ahb_manager (
      .bus(ahb_control),
      .connection(renode.bus_controller)
  );

  renode_ahb_if #(
      .AddressWidth(32),
      .DataWidth(32)
  ) ahb_data (
      clk
  );
  renode_ahb_subordinate renode_ahb_subordinate (
      .bus(ahb_data),
      .connection(renode.bus_peripheral)
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

  wire control_hresp_nc;
  // Only one Subordinate doesn't require an Interconnect.
  assign ahb_control.hsel = 1;
  assign ahb_control.hready = ahb_control.hreadyout;

  assign ahb_data.hsel = 1;
  assign ahb_data.hready = ahb_data.hreadyout;

  dma_ahb_simple dut (
      .HCLK(clk),
      .HRESETn(ahb_control.hresetn & ahb_data.hresetn),
      .S_HSEL(ahb_control.hsel),
      .S_HADDR(ahb_control.haddr),
      .S_HTRANS(ahb_control.htrans),
      .S_HWRITE(ahb_control.hwrite),
      .S_HSIZE(ahb_control.hsize),
      .S_HBURST(ahb_control.hburst),
      .S_HWDATA(ahb_control.hwdata),
      .S_HRDATA(ahb_control.hrdata),
      .S_HRESP({control_hresp_nc, ahb_control.hresp}),
      .S_HREADYin(ahb_control.hready),
      .S_HREADYout(ahb_control.hreadyout),

      .M_HBUSREQ(),
      .M_HGRANT(1),
      .M_HADDR(ahb_data.haddr),
      .M_HTRANS(ahb_data.htrans),
      .M_HWRITE(ahb_data.hwrite),
      .M_HSIZE(ahb_data.hsize),
      .M_HBURST(ahb_data.hburst),
      .M_HPROT(),
      .M_HWDATA(ahb_data.hwdata),
      .M_HRDATA(ahb_data.hrdata),
      .M_HRESP({1'b0, ahb_data.hresp}),
      .M_HREADY(ahb_data.hready),

      .IRQ(interrupt)
  );
endmodule
