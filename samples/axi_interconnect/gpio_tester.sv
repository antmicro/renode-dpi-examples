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

module gpio_tester
(
  input logic clk,
  input logic reset,
  input logic trigger,
  output logic [4:0] out
);
  logic handled = 0;
  always @(posedge clk) begin
      if(reset == 0)
          out <= 5'b10000;
      else if(trigger == 1 && handled == 0) begin
          out <= {out[3:0], out[4]};
          handled <= 1;
      end else if(trigger == 0)
          handled <= 0;
  end
endmodule
