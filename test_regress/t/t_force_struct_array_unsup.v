// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  typedef struct {
    logic [7:0] x;
    logic [7:0] y;
  } st_t;
  st_t big[32768][32768];

  initial begin
    force big[0][0].y = 8'h40;
    $finish;
  end
endmodule
