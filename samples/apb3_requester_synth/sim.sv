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

module sim;
  parameter int ClockPeriod = 100;
  parameter int ReceiverPort = 0;
  parameter int SenderPort = 0;
  parameter string Address = "";

  parameter int APB3BusAddressWidth = 32;
  parameter int APB3BusDataWidth = 32;

  logic clk = 1;
  always #(ClockPeriod / 2) clk = ~clk;

  renode #(
      .BusPeripheralsCount(1)
  ) renode (
      .clk(clk),
      .renode_inputs('0),
      .renode_outputs()
  );

  renode_apb3_if #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) apb3 (clk);

  renode_apb3_completer renode_apb3_completer (
      .bus(apb3),
      .connection(renode.bus_peripheral)
  );

  // Each transfer takes time:
  // apb3_transfer (PreTransactionUI + PostTransactionUI + (2*Back2BackNum))
  // Back2back transfers take: 2+8+2*3=16 cycles
  // There are 2x8 W/R operations, so each transfer set takes
  // time_transfer_clk = 16*2*8 = 16*16
  // Adding margins to be safe (17 * 20)
  int time_transfer = ClockPeriod * 17 * 20; //FIXME: tie to parameters

  initial begin
    if (Address != "") renode.connection.connect(ReceiverPort, SenderPort, Address);
    dut_requester_synth.mux_select = 1'b0;
    dut_requester_synth.start_n_single = '0;
    dut_requester_synth.start_n_b2b = '0;
    renode.reset();

    // The requester produces data with a known pattern.
    // They are transfered in a various ways.
    // In example with or without a clock cycle between transfers.
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
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Requester: Timeout reached while waiting for a tick response.
    renode.receive_and_handle_message();
    if (!renode.connection.is_connected()) $finish;
  end

  apb3_requester_synth #(
      .AddressWidth(APB3BusAddressWidth),
      .DataWidth(APB3BusDataWidth)
  ) dut_requester_synth (
      .apb3(apb3)
  );
endmodule
