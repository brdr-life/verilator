// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  typedef struct {
    logic [7:0] vec;
    logic flag;
  } st_t;
  st_t s;
  int i;
  logic a, b;
  logic [3:0] c, d;
  assign a = s.vec[2];
  assign b = s.vec[i];
  assign c = s.vec[5:2];
  assign d = s.vec[3:0];  // Same range as forced, supported

  initial begin
    force s.vec[3:0] = 4'hf;
    $finish;
  end
endmodule
