// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

`define STRINGIFY(x) `"x`"

module t;
  typedef struct {
    logic [6:0] a;
    logic [6:0] arr[1:2];
  } st_t;

  st_t s, f;
  wire st_t ws = s;

  initial begin
    $dumpfile(`STRINGIFY(`TEST_DUMPFILE));
    $dumpvars;
    s.a = 7'h11;
    s.arr = '{7'h22, 7'h33};
    f.a = 7'h55;
    f.arr = '{7'h66, 7'h77};
    #1 force s.arr[2] = 7'h25;
    #1 force s = f;
    #1 force s.a = 7'h5a;
    #1 release s.a;
    #1 release s;
    #1 s.a = 7'h01;
    #1 $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
