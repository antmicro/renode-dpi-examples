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

module apb3_mux (
    renode_apb3_if apb3_i0,
    renode_apb3_if apb3_i1,
    renode_apb3_if apb3_o0,
    input logic sel
);

  always_comb begin : proc_mux_buses
    case (sel)
      1'b0: begin
        apb3_o0.paddr   = apb3_i0.paddr;
        apb3_o0.pselx   = apb3_i0.pselx;
        apb3_o0.penable = apb3_i0.penable;
        apb3_o0.pwrite  = apb3_i0.pwrite;
        apb3_o0.pwdata  = apb3_i0.pwdata;
      end
      1'b1: begin
        apb3_o0.paddr   = apb3_i1.paddr;
        apb3_o0.pselx   = apb3_i1.pselx;
        apb3_o0.penable = apb3_i1.penable;
        apb3_o0.pwrite  = apb3_i1.pwrite;
        apb3_o0.pwdata  = apb3_i1.pwdata;
      end
      default: begin
        apb3_o0.paddr   = '0;
        apb3_o0.pselx   = '0;
        apb3_o0.penable = '0;
        apb3_o0.pwrite  = '0;
        apb3_o0.pwdata  = '0;
      end
    endcase
  end

  assign apb3_i0.prdata  = apb3_o0.prdata;
  assign apb3_i0.pready  = apb3_o0.pready;
  assign apb3_i0.pslverr = apb3_o0.pslverr;

  assign apb3_i1.prdata  = apb3_o0.prdata;
  assign apb3_i1.pready  = apb3_o0.pready;
  assign apb3_i1.pslverr = apb3_o0.pslverr;

  assign apb3_i0.presetn = apb3_o0.presetn;
  assign apb3_i1.presetn = apb3_o0.presetn;
endmodule
