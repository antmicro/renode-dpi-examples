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

module apb3_transfer #(
    parameter int unsigned AddressWidth = 20,
    parameter int unsigned DataWidth = 32,
    parameter int unsigned MemoryOffset = 20'h0_1000,  // Must be same size as AddressWidth
    parameter int unsigned DataOffset = 32'hDEAD_BA00,  // Must be same size as DataWidth
    parameter int unsigned TransfersNum = 8,  // Will create 8 writes followed by 8 reads
    parameter int unsigned PreTransactionUI = 2,
    parameter int unsigned PostTransactionUI = 8,
    parameter int unsigned TransfersDelay = 1000,
    parameter int unsigned Back2BackNum = 1
) (
    renode_apb3_if apb3_if,
    input logic start_n,
    output logic done
);

  typedef logic [AddressWidth-1:0] address_t;
  typedef logic [DataWidth-1:0] data_t;

  // Clk, reset
  bit clk;
  assign clk = apb3_if.pclk;
  bit resetn;
  assign resetn = (apb3_if.presetn && start_n);

  // Renaming the bus is a style preference
  address_t paddr;
  logic     pselx;
  logic     penable;
  logic     pwrite;
  data_t    pwdata;
  logic     pready;
  data_t    prdata;
  logic     pslverr;

  assign apb3_if.paddr = paddr;
  assign apb3_if.pselx = pselx;
  assign apb3_if.penable = penable;
  assign apb3_if.pwrite = pwrite;
  assign apb3_if.pwdata = pwdata;

  assign pready = apb3_if.pready;
  assign prdata = apb3_if.prdata;
  assign pslverr = apb3_if.pslverr;

  // Internal state
  typedef enum {
    S_IDLE,
    S_UI_0,
    S_UI_1
  } state_t;
  state_t state = S_IDLE;

  // Control counters
  logic start_transaction;
  logic write_mode;
  int unsigned count_writes;
  int unsigned count_reads;

  apb3_transfer_counter #(
      .TransfersNum(TransfersNum),
      .PreTransactionUI(PreTransactionUI),
      .PostTransactionUI(PostTransactionUI),
      .TransfersDelay(TransfersDelay),
      .Back2BackNum(Back2BackNum)
  ) x_transfer_counter (
      .clk(clk),
      .resetn(resetn),
      .start_transaction(start_transaction),
      .write_mode(write_mode),
      .done(done),
      .count_writes(count_writes),
      .count_reads(count_reads)
  );

  //
  // Waveform generation
  //

  int unsigned b2b_counter;
  logic [7:0] count_b2bs;
  wire address_t write_address = address_t'(MemoryOffset + 256 * count_b2bs + 4 * (count_writes - 1));
  wire address_t read_address = address_t'(MemoryOffset + 256 * count_b2bs + 4 * count_reads);
  wire data_t write_data = data_t'(DataOffset + 256 * count_b2bs + 4 * (count_writes - 1));
  wire data_t read_data = data_t'(DataOffset + 256 * count_b2bs + 4 * count_reads);

  state_t next_state;
  always_comb begin : proc_next_state
    if (pready) begin
      if (b2b_counter == 0) next_state = S_IDLE;
      else next_state = S_UI_0;
    end else next_state = S_UI_1;
  end

  always_ff @(posedge clk or negedge resetn) begin
    if (resetn == '0) begin
      state <= S_IDLE;
      count_b2bs <= '0;
    end else begin
      case (state)
        S_IDLE: begin
          if (done == 1'b1) begin
            state <= S_IDLE;
          end else begin
            if (start_transaction == 1'b1) begin
              state <= S_UI_0;
            end else begin
              state <= S_IDLE;
            end
          end
          b2b_counter <= Back2BackNum;
          count_b2bs  <= '0;
        end
        S_UI_0: begin
          state <= S_UI_1;
          b2b_counter <= b2b_counter - 1;
        end
        S_UI_1: begin
          state <= next_state;
          if (pready) begin
            if (write_mode == '0) begin
              assert (prdata == read_data);
            end
          end
          if (pready) begin
            count_b2bs <= count_b2bs + 1'b1;
          end
        end
        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

  always_comb begin : proc_fsm_outputs
    case (state)
      S_IDLE: begin
        paddr   = '0;
        pselx   = '0;
        penable = '0;
        pwrite  = '0;
        pwdata  = '0;
      end
      S_UI_0: begin
        paddr   = write_mode ? write_address : read_address;
        pselx   = 1'b1;
        penable = 1'b0;
        pwrite  = write_mode;
        pwdata  = write_mode ? write_data : '0;
      end
      S_UI_1: begin
        paddr   = write_mode ? write_address : read_address;
        pselx   = 1'b1;
        penable = 1'b1;
        pwrite  = write_mode;
        pwdata  = write_mode ? write_data : '0;
      end
      default: begin
        paddr   = '0;
        pselx   = '0;
        penable = '0;
        pwrite  = '0;
        pwdata  = '0;
      end
    endcase
  end
endmodule
