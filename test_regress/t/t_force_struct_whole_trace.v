// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

`define STRINGIFY(x) `"x`"

module t;
  typedef struct {
    logic [7:0] a;
    logic [7:0] arr[2];
  } st_t;

  st_t s, f;
  wire st_t ws = s;

  initial begin
    $dumpfile(`STRINGIFY(`TEST_DUMPFILE));
    $dumpvars;
    s.a = 8'h11;
    s.arr = '{8'h22, 8'h33};
    f.a = 8'h55;
    f.arr = '{8'h66, 8'h77};
    #1 force s.arr[1] = 8'ha5;
    #1 force s = f;
    #1 force s.a = 8'h5a;
    #1 release s.a;
    #1 release s;
    #1 s.a = 8'h01;
    #1 $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
