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
  st_t sc[3];  // Elements and members of elements forced
  st_t sd[2][2];
  st_t cp;
  st_t all[3];
  st_t sub[2];
  int i;

  // Reads through a queue and an associative array of an element
  typedef struct {
    logic [7:0] q[$];
    int aa[int];
    logic flag;
  } qe_t;
  qe_t qsa[2];
  qe_t qecp;
  int qi = 1;
  initial begin
    qsa[1].q.push_back(8'h56);
    qsa[1].aa[3] = 7;
    force qsa[0].flag = 1'b1;
    `checkh(qsa[1].q[0], 8'h56);
    `checkh(qsa[qi].q[0], 8'h56);
    `checkh(qsa[qi].q[0][7:4], 4'h5);
    `checkh(qsa[1].aa[3], 7);
    `checkh(qsa[qi].aa[3], 7);
    `checkh(qsa[0].flag, 1'b1);
    qecp = qsa[1];
    `checkh(qecp.q[0], 8'h56);
    `checkh(qecp.aa[3], 7);
    release qsa[0].flag;
  end

  initial begin
    for (int n = 0; n < 2; ++n) src[n] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    for (int n = 0; n < 3; ++n) sb[n] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    sc = sb;
    sd = '{2{src}};
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

    // Copies of an element and of the array with forced members
    force sc[1].k = 8'h21;
    force sc[2].m[0] = 4'h7;
    cp = sc[1];
    `checkh(cp.k, 8'h21);
    `checkh(cp.m[0], 4'h1);
    i = 2;
    cp = sc[i];
    `checkh(cp.m[0], 4'h7);
    all = sc;
    `checkh(all[0].k, 8'h1);
    `checkh(all[1].k, 8'h21);
    `checkh(all[2].m[0], 4'h7);
    force sd[1][0].k = 8'h31;
    sub = sd[1];
    `checkh(sub[0].k, 8'h31);
    `checkh(sub[1].k, 8'h1);

    // A force of an element releases the forces of its members
    force sc[1] = '{m: '{4'h4, 4'h5}, k: 8'h6};
    `checkh(sc[1].k, 8'h6);
    force sc[1].m[1] = 4'hb;
    i = 1;
    `checkh(sc[i].m[0], 4'h4);
    `checkh(sc[i].m[1], 4'hb);
    cp = sc[1];
    `checkh(cp.m[1], 4'hb);
    `checkh(cp.k, 8'h6);
    all = sc;
    `checkh(all[1].m[1], 4'hb);
    `checkh(all[2].m[0], 4'h7);
    release sc[1];
    `checkh(sc[1].m[1], 4'hb);
    `checkh(sc[1].k, 8'h6);
    sc[1].k = 8'h12;
    cp = sc[1];
    `checkh(cp.k, 8'h12);
    $finish;
  end
endmodule
