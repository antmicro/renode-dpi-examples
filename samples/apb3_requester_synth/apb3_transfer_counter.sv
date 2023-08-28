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
  * Simple generic APB3 Requester (Behavioral model)
  * Features:
      - Write transfer with no wait states
      - Read transfer with no wait states
  */

/**
  * Memory offset and size must match values defined in .repl file
  */

`timescale 1ns / 1ps

module apb3_transfer_counter #(
    parameter int unsigned TransfersNum = 8,  // Will create 8 writes followed by 8 reads
    parameter int unsigned PreTransactionUI = 2,
    parameter int unsigned PostTransactionUI = 8,
    parameter int unsigned TransfersDelay = 1000,
    parameter int unsigned Back2BackNum = 2
) (
    input logic clk,
    input logic resetn,
    output logic start_transaction,
    output logic write_mode,
    output logic done,
    output int unsigned count_writes,
    output int unsigned count_reads
);

  localparam int TransactionMinUI = 2;
  localparam int TransactionLengthUI = Back2BackNum * TransactionMinUI;
  localparam int SpacedTransactionLengthUI = PreTransactionUI + TransactionLengthUI + PostTransactionUI;


  // UI Counter, which generates control signals for generation
  // of transactions
  int unsigned counter_ui;
  always_ff @(posedge clk or negedge resetn) begin
    if (resetn == '0) begin
      counter_ui <= '0;  // To prevent
    end else begin
      if (counter_ui == SpacedTransactionLengthUI) begin
        counter_ui <= '0;
      end else begin
        counter_ui <= counter_ui + 1'b1;
      end
    end
  end

  assign start_transaction = (counter_ui == PreTransactionUI) && resetn;

  // Count TransfersNum writes
  logic end_stream;

  always_ff @(posedge clk or negedge resetn) begin
    if (resetn == '0) begin
      count_writes <= '0;
    end else begin
      // Writes
      if (count_writes == (TransfersNum + 1)) begin
        count_writes <= count_writes;
      end else if (start_transaction) begin
        count_writes <= count_writes + 1'b1;
      end
    end
  end

  // Toggle to read mode
  assign write_mode = ~(count_writes == (TransfersNum + 1));

  // Count TransfersNum reads
  always_ff @(posedge clk or negedge resetn) begin
    if (resetn == '0) begin
      count_reads <= '0;
    end else begin
      // Reads
      if (write_mode == '1) begin
        count_reads <= '0;
      end else if (count_reads == (TransfersNum-1)) begin
        count_reads <= count_reads;
      end else if (start_transaction) begin
        count_reads <= count_reads + 1'b1;
      end
    end
  end

  // Signal that transfers elapsed
  assign done = (count_writes == (TransfersNum + 1)) && (count_reads == (TransfersNum-1));
endmodule
