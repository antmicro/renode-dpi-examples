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

/**
  * APB3 Requester

  * Model is written in synthesizable-like style to maximize
    compatibility between different simulators

  * Theory of operation:
    apb3_transfer block is instantiated twice and respective apb3 interfaces are muxed.
    Control signals are tuned so that each block has sufficient time to access the bus.
    During each access, the transfer blocks generate write and read transfers.

    Single block:
    Generates TransfersNum Writes, followed by TransfersNum Reads.
    Transactions are singular - PSEL is deasserted after one transfer.

    Back2back block:
    Generates TransfersNum Write Transfers, followed by the same number of Read Transfers
    Each Transfer consists of Back2BackNum Writes or Reads.
    PSEL is deasserted after Back2BackNum Writes/Reads.

  * Features:
      - Read and write transfers:
      - with no wait states,
      - with wait states,
      - back to back (without idle cycles between transfers)
  */

/**
  * Memory offset and size must match values defined in .repl file!!!
  */

`timescale 1ns / 1ps

module apb3_requester_synth #(
    parameter int unsigned AddressWidth = 32,
    parameter int unsigned DataWidth = 32,
    // Applicable to both transfer types.
    parameter int unsigned TransfersNum = 8,
    parameter int unsigned TransfersDelay = 1000,
    // First transfer will be at this offset and payload.
    parameter int unsigned MemoryOffsetTransfersSingle = 'h0000_1000,
    parameter int unsigned DataOffsetTransfersSingle = 'h000A_A000,

    parameter int unsigned Back2BackNum = 3,
    parameter int unsigned MemoryOffsetTransfersB2b = 'h0000_2000,
    parameter int unsigned DataOffsetTransfersB2b = 'h0000B_B000
) (
    renode_apb3_if apb3
);

  typedef logic [AddressWidth-1:0] address_t;
  typedef logic [DataWidth-1:0] data_t;

  wire clk = apb3.pclk;

  renode_apb3_if #(
      .AddressWidth(AddressWidth),
      .DataWidth(DataWidth)
  ) apb3_single (clk);

  renode_apb3_if #(
      .AddressWidth(AddressWidth),
      .DataWidth(DataWidth)
  ) apb3_b2b (clk);

  logic start_n_single;
  logic done_single;
  logic start_n_b2b;
  logic done_b2b;

  apb3_transfer #(
      .AddressWidth(AddressWidth),
      .DataWidth(DataWidth),
      .MemoryOffset(MemoryOffsetTransfersSingle),
      .DataOffset(DataOffsetTransfersSingle),
      .TransfersNum(TransfersNum),
      .TransfersDelay(TransfersDelay),
      .Back2BackNum(1)  // Always single transfers
  ) dut_single (
      .apb3_if(apb3_single),
      .start_n(start_n_single),
      .done(done_single)
  );

  apb3_transfer #(
      .AddressWidth(AddressWidth),
      .DataWidth(DataWidth),
      .MemoryOffset(MemoryOffsetTransfersB2b),
      .DataOffset(DataOffsetTransfersB2b),
      .TransfersNum(TransfersNum),
      .TransfersDelay(TransfersDelay),
      .Back2BackNum(Back2BackNum)
  ) dut_b2b (
      .apb3_if(apb3_b2b),
      .start_n(start_n_b2b),
      .done(done_b2b)
  );

  logic mux_select;

  apb3_mux dut_mux (
      .apb3_i0(apb3_single),
      .apb3_i1(apb3_b2b),
      .apb3_o0(apb3),
      .sel(mux_select)
  );
endmodule
