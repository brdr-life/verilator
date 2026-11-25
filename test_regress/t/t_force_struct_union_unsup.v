// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  typedef union {
    logic [30:0] a;
    logic [30:0] b;
  } u_t;
  typedef struct {
    u_t u;
    logic [3:0] k;
  } s_t;

  // A part-select of a union member forced or released beside a forced overlaid member
  initial begin
    s_t s;
    s_t s2;
    force s.u.b = 31'h7fff_fff0;
    force s.u.a[3:0] = 4'h5;
    force s2.u.a = 31'h7fff_fff5;
    release s2.u.b[3:0];
    $finish;
  end
endmodule
