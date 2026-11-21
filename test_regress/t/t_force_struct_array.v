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
  typedef struct {
    logic [7:0] x;
    logic [7:0] y[2];
  } e_t;
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
  e_t ea[16];  // A member forced in each element
  e_t ecp[16];
  e_t em[4][8];  // A member forced in every other element
  e_t emcp[4][8];
  for (genvar gi = 0; gi < 4; ++gi) begin : gen_i
    for (genvar gj = 0; gj < 8; gj += 2) begin : gen_j
      initial force em[gi][gj].y[1] = 8'(gi * 8 + gj + 100);
    end
  end

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
    // A write to an element is seen by a later copy, but not over a force
    i = 0;
    sc[i].k = 8'h13;
    all = sc;
    `checkh(all[0].k, 8'h13);
    i = 1;
    sc[i].m[1] = 4'h3;
    sc[i].k = 8'h14;
    cp = sc[1];
    `checkh(cp.m[1], 4'h3);
    cp = sc[i];
    `checkh(cp.k, 8'h21);
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
    // A member forced in each of many elements
    for (int n = 0; n < 16; ++n) begin
      ea[n].x = 8'(n);
      ea[n].y[0] = 8'(n + 1);
      ea[n].y[1] = 8'(n + 2);
    end
    force ea[0].y[1] = 8'd0;
    force ea[1].y[1] = 8'd3;
    force ea[2].y[1] = 8'd6;
    force ea[3].y[1] = 8'd9;
    force ea[4].y[1] = 8'd12;
    force ea[5].y[1] = 8'd15;
    force ea[6].y[1] = 8'd18;
    force ea[7].y[1] = 8'd21;
    force ea[8].y[1] = 8'd24;
    force ea[9].y[1] = 8'd27;
    force ea[10].y[1] = 8'd30;
    force ea[11].y[1] = 8'd33;
    force ea[12].y[1] = 8'd36;
    force ea[13].y[1] = 8'd39;
    force ea[14].y[1] = 8'd42;
    force ea[15].y[1] = 8'd45;
    #1;
    ecp = ea;
    for (int n = 0; n < 16; ++n) begin
      `checkh(ecp[n].x, 8'(n));
      `checkh(ecp[n].y[0], 8'(n + 1));
      `checkh(ecp[n].y[1], 8'(n * 3));
    end
    for (int n = 0; n < 16; ++n) begin
      ea[n].y[1] = 8'd0;
      ea[n].x = 8'(n + 5);
    end
    #1;
    ecp = ea;
    for (int n = 0; n < 16; ++n) begin
      `checkh(ecp[n].x, 8'(n + 5));
      `checkh(ecp[n].y[1], 8'(n * 3));
    end
    release ea[0].y[1];
    release ea[1].y[1];
    release ea[2].y[1];
    release ea[3].y[1];
    release ea[4].y[1];
    release ea[5].y[1];
    release ea[6].y[1];
    release ea[7].y[1];
    release ea[8].y[1];
    release ea[9].y[1];
    release ea[10].y[1];
    release ea[11].y[1];
    release ea[12].y[1];
    release ea[13].y[1];
    release ea[14].y[1];
    release ea[15].y[1];
    ea[3].y[1] = 8'd1;
    ecp = ea;
    `checkh(ecp[3].y[1], 8'd1);
    `checkh(ecp[4].y[1], 8'd12);
    // A member forced in every other element of a two dimensional array
    for (int n = 0; n < 4; ++n) begin
      for (int k = 0; k < 8; ++k) begin
        em[n][k].x = 8'(n + k);
        em[n][k].y[1] = 8'(n * 8 + k);
      end
    end
    emcp = em;
    for (int n = 0; n < 4; ++n) begin
      for (int k = 0; k < 8; ++k) begin
        `checkh(emcp[n][k].x, 8'(n + k));
        `checkh(emcp[n][k].y[1], 8'(n * 8 + k + (k % 2 == 0 ? 100 : 0)));
      end
    end
    $finish;
  end
endmodule
