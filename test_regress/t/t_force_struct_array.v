// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got='h%x exp='h%x\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0)
// verilog_format: on

module t;
  typedef struct {
    logic [3:0] m[2];
    logic [7:0] k;
  } st_t;
  st_t src[2];
  wire st_t sa[2];  // Only whole elements forced
  assign sa = src;
  st_t sb[3];  // Only members of elements forced
  int i;

  initial begin
    for (int n = 0; n < 2; ++n) src[n] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    for (int n = 0; n < 3; ++n) sb[n] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    #1;
    force sa[0] = '{m: '{4'h1, 4'h2}, k: 8'h3};
    force sa[1] = '{m: '{4'h4, 4'h5}, k: 8'h6};
    force sb[1].k = 8'h63;
    force sb[2].m[1] = 4'h9;
    force sb[0].k[7:4] = 4'ha;
    #1;
    `checkh(sa[0].m[0], 4'h1);
    `checkh(sa[0].m[1], 4'h2);
    `checkh(sa[0].k, 8'h3);
    `checkh(sa[1].m[0], 4'h4);
    `checkh(sa[1].m[1], 4'h5);
    `checkh(sa[1].k, 8'h6);

    `checkh(sb[1].k, 8'h63);
    `checkh(sb[0].k, 8'ha1);
    `checkh(sb[2].k, 8'h1);
    `checkh(sb[0].m[1], 4'h1);
    `checkh(sb[1].m[1], 4'h1);
    `checkh(sb[2].m[1], 4'h9);
    `checkh(sb[2].m[0], 4'h1);
    for (i = 0; i < 3; ++i) begin
      `checkh(sb[i].k, i == 1 ? 8'h63 : i == 0 ? 8'ha1 : 8'h1);
      `checkh(sb[i].k[5:2], i == 1 ? 4'h8 : i == 0 ? 4'h8 : 4'h0);
      `checkh(sb[i].m[1], i == 2 ? 4'h9 : 4'h1);
    end

    release sb[1].k;
    release sb[0].k[7:4];
    sb[1].k = 8'h11;
    sb[0].k = 8'h12;
    i = 1;
    `checkh(sb[i].k, 8'h11);
    `checkh(sb[i-1].k, 8'h12);
    `checkh(sb[i+1].m[1], 4'h9);
    $finish;
  end
endmodule
