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
  * Memory model with the APB3 Completer Interface.
  * Features:
  *   - Write/Read transfers with no wait states
  *   - Write/Read transfers with no idle cycles (back to back transfers)
  *   - Write/Read transfers with wait states
  *
  * OutputLatency can be adjusted to validate transfers with wait states.
  * If set to 0, PREADY will be asserted in 2nd clock cycle.
  * If set to N>0, PREADY will be asserted in (N+2)th clock cycle.
  */

`timescale 1ns / 1ps

module apb3_completer_mem #(
    parameter int unsigned AddressWidth = 8,
    parameter int unsigned DataWidth = 32,
    parameter int unsigned OutputLatency = 2
) (
    input                           clk,
    input                           rst_n,
    input        [AddressWidth-1:0] paddr,
    input                           pwrite,
    input                           psel,
    input                           penable,
    input        [   DataWidth-1:0] pwdata,
    output logic [   DataWidth-1:0] prdata,
    output logic                    pready
);
  logic [DataWidth-1:0] prdata_int;

  // Memory
  localparam int MemoryDepth = 2 ** AddressWidth;
  logic [DataWidth-1:0] mem[MemoryDepth];

  // Internal state
  logic [1:0] peripheral_state;
  logic [1:0] peripheral_state_next;
  const logic [1:0] STATE_IDLE = 0;
  const logic [1:0] STATE_ACCESS = 1;

  // Next state logic
  always_comb begin : proc_fsm_next_state
    case (peripheral_state)
      STATE_IDLE: begin
        if (psel && !penable) begin
          peripheral_state_next = STATE_ACCESS;
        end
      end
      STATE_ACCESS: begin
        peripheral_state_next = STATE_IDLE;
      end
      default: begin
        peripheral_state_next = STATE_IDLE;
      end
    endcase
  end

  // FSM logic
  always_ff @(posedge clk or negedge rst_n) begin : proc_fsm
    if (rst_n == 1'b0) begin
      peripheral_state <= '0;
    end else begin
      peripheral_state <= peripheral_state_next;

      // Write Enable logic: write data to memory
      if (psel && penable && pwrite) begin
          mem[paddr] <= pwdata;
      end

      // Read Enable logic: read data from memory
      if (psel && !penable && !pwrite) begin
        prdata_int <= mem[paddr];
      end else begin
        prdata_int <= '0;
      end
    end
  end

  //
  // Generate artificial delay to the {PRDATA,PREADY} signals
  // Useful to validate wait states, by default is set to 2 cycles.
  //
  genvar i;
  generate
    if (OutputLatency == 0) begin : gen_latency_0
      assign prdata = prdata_int;
      assign pready = (peripheral_state == STATE_ACCESS);
    end else begin : gen_latency_gt_0
      logic [DataWidth-1:0] prdata_reg[OutputLatency];
      logic pready_reg[OutputLatency];
      for (i = 0; i < OutputLatency; i++) begin : gen_output_registers
        if (i == 0) begin
          always_ff @(posedge clk or negedge rst_n) begin : proc_first_reg
            prdata_reg[i] <= prdata_int;
            pready_reg[i] <= (peripheral_state == STATE_ACCESS);
          end
        end else begin
          always_ff @(posedge clk or negedge rst_n) begin : proc_latency_ith
            prdata_reg[i] <= prdata_reg[i-1];
            pready_reg[i] <= pready_reg[i-1];
          end
        end
      end
      assign prdata = prdata_reg[OutputLatency-1];
      assign pready = pready_reg[OutputLatency-1];
    end
  endgenerate
endmodule
