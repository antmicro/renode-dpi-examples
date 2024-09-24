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
`timescale 1ns/1ns

module ahb_manager_synth
(
  input logic HCLK,
  input logic HRESETn,
  input logic HREADY,
  output logic [31:0] HADDR,
  output logic [31:0] HWDATA,
  output logic [2:0] HSIZE,
  output logic [1:0] HTRANS,
  output logic HWRITE
);
  typedef enum logic [2:0] {
    Single = 3'b000,
    Incrementing = 3'b001,
    Wrapping4 = 3'b010,
    Incrementing4 = 3'b011,
    Wrapping8 = 3'b100,
    Incrementing8 = 3'b101,
    Wrapping16 = 3'b110,
    Incrementing16 = 3'b111
  } burst_e;

  typedef enum logic {
    Read  = 1'b0,
    Write = 1'b1
  } transfer_direction_e;

  typedef enum logic [1:0] {
    Idle = 2'b00,
    Busy = 2'b01,
    NonSequential = 2'b10,
    Sequential = 2'b11
  } transfer_type_e;

  typedef enum logic [2:0] {
    Byte8Bit = 3'b000,
    HalfWord16Bit = 3'b001,
    Word32Bit = 3'b010,
    DoubleWord64Bit = 3'b011
  } transfer_size_e;

  typedef enum logic [2:0] {
      ByteRequest = 3'b001,
      WordRequest = 3'b010,
      DoubleWordRequest = 3'b011,
      Stop = 3'b100
  } state_t;

  state_t state;

  always @(posedge HCLK or negedge HRESETn) begin
    if (HRESETn == 0) begin
      state <= ByteRequest;
      HTRANS <= Idle;
      HADDR <= 32'b0;
      HWDATA <= 32'b0;
      HSIZE <= 2'b0;
      HWRITE <= 1'b0;
      repeat(4) @(posedge HCLK);
    end else begin
      case (state)
        ByteRequest: begin
          HTRANS <= Idle;
          if (HREADY) begin
            HSIZE <= Byte8Bit;
            HADDR <= 32'h1000;
            HWDATA <= 32'h12;
            HWRITE <= Write;
            HTRANS <= NonSequential;
            @(posedge HCLK);
            state <= WordRequest;
          end
        end
        WordRequest: begin
          HTRANS <= Idle;
          if (HREADY) begin
            HSIZE <= HalfWord16Bit;
            HADDR <= 32'h1004;
            HWDATA <= 32'h3456;
            HWRITE <= Write;
            HTRANS <= NonSequential;
            @(posedge HCLK);
            state <= DoubleWordRequest;
          end
        end
        DoubleWordRequest: begin
          HTRANS <= Idle;
          if (HREADY) begin
            HSIZE <= Word32Bit;
            HADDR <= 32'h1008;
            HWDATA <= 32'h789abcde;
            HWRITE <= Write;
            HTRANS <= NonSequential;
            @(posedge HCLK);
            state <= Stop;
          end
        end
        Stop: begin
          HTRANS <= Idle;
        end
      endcase
    end
  end
endmodule;
