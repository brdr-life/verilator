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

  initial begin
    st_t sb[3];  // Only members of elements forced
    int i;
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
  end

  // Reads through a queue and an associative array of an element
  typedef struct {
    logic [7:0] q[$];
    int aa[int];
    logic flag;
  } qe_t;
  initial begin
    qe_t qsa[2];
    qe_t qecp;
    int qi;
    qi = 1;
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

  // Copies of an element and of the array with forced members
  initial begin
    st_t sc[3];  // Elements and members of elements forced
    st_t sd[2:1][0:2];
    st_t cp;
    st_t all[3];
    st_t sub[0:2];
    int idx;
    for (int n = 0; n < 3; ++n) sc[n] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    for (int n = 1; n <= 2; ++n) begin
      for (int k = 0; k <= 2; ++k) sd[n][k] = '{m: '{4'h1, 4'h1}, k: 8'h1};
    end
    force sc[1].k = 8'h21;
    force sc[2].m[0] = 4'h7;
    cp = sc[1];
    `checkh(cp.k, 8'h21);
    `checkh(cp.m[0], 4'h1);
    idx = 2;
    cp = sc[idx];
    `checkh(cp.m[0], 4'h7);
    all = sc;
    `checkh(all[0].k, 8'h1);
    `checkh(all[1].k, 8'h21);
    `checkh(all[2].m[0], 4'h7);
    force sd[1][0].k = 8'h31;
    sub = sd[1];
    `checkh(sub[0].k, 8'h31);
    `checkh(sub[1].k, 8'h1);
    sub = sd[2];
    `checkh(sub[0].k, 8'h1);

    // A force of an element releases the forces of its members
    force sc[1] = '{m: '{4'h4, 4'h5}, k: 8'h6};
    `checkh(sc[1].k, 8'h6);
    force sc[1].m[1] = 4'hb;
    idx = 1;
    `checkh(sc[idx].m[0], 4'h4);
    `checkh(sc[idx].m[1], 4'hb);
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
  end

  // A force of an element of a member array of an element, read below it
  typedef struct {
    logic [6:0] value;
  } v_t;
  typedef struct {
    v_t arr[3:1];
    logic flag;
  } av_t;
  initial begin
    av_t av[2];
    logic [6:0] v;
    av[1].arr[2].value = 7'h1;
    v = 7'h31;
    force av[1].arr[2] = '{value: v};
    `checkh(av[1].arr[2].value, 7'h31);
    v = 7'h41;
    #1;
    `checkh(av[1].arr[2].value, 7'h41);
    release av[1].arr[2];
  end

  // Reads below forced members of elements, a write below and releases
  typedef struct {
    logic [6:0] b;
    logic [2:0] c;
  } bm_t;
  typedef struct {
    bm_t m;
    logic flag;
  } bs_t;
  initial begin
    bs_t bs[2];
    bm_t bcp;
    logic [6:0] v;
    int bi;
    bs[0].m.b = 7'h2;
    bs[1].m.b = 7'h1;
    v = 7'h35;
    force bs[0].m = '{b: 7'h52, c: 3'h3};
    force bs[1].m.b = v;
    `checkh(bs[0].m.b, 7'h52);
    `checkh(bs[0].m.b[6:4], 3'h5);
    `checkh(bs[1].m.b, 7'h35);
    `checkh(bs[1].m.b[0], 1'b1);
    for (bi = 0; bi < 2; ++bi) begin
      `checkh(bs[bi].m.b, bi == 0 ? 7'h52 : 7'h35);
    end
    bcp = bs[0].m;
    `checkh(bcp.c, 3'h3);
    bs[0].m.c = 3'h6;
    `checkh(bs[0].m.c, 3'h3);
    release bs[0].m;
    `checkh(bs[0].m.c, 3'h3);
    bs[0].m.c = 3'h6;
    `checkh(bs[0].m.c, 3'h6);
    v = 7'h45;
    #1;
    `checkh(bs[1].m.b, 7'h45);
    release bs[1].m.b;
  end

  // Reads below a forced member of an element of a two dimensional array, and of a row
  initial begin
    av_t bd[2][3];
    av_t brow[3];
    logic [6:0] v;
    int bi;
    int bj;
    bd[0][1].arr[1].value = 7'h7;
    brow[1].arr[1].value = 7'h7;
    v = 7'h35;
    force bd[1][2].arr[1] = '{value: v};
    `checkh(bd[1][2].arr[1].value, 7'h35);
    bi = 1;
    bj = 2;
    `checkh(bd[bi][bj].arr[1].value, 7'h35);
    bi = 0;
    bj = 1;
    `checkh(bd[bi][bj].arr[1].value, 7'h7);
    `checkh(bd[0] == brow, 1'b1);
    v = 7'h45;
    #1;
    `checkh(bd[1][2].arr[1].value, 7'h45);
    release bd[1][2].arr[1];
  end

  // Reads below forced members of elements with non-zero bounds, descending and ascending
  initial begin
    bs_t bo[3:1];
    bs_t bp[1:3];
    int bi;
    force bo[2].m.b = 7'h35;
    force bp[3].m = '{b: 7'h44, c: 3'h1};
    `checkh(bo[2].m.b, 7'h35);
    `checkh(bp[3].m.b, 7'h44);
    bi = 2;
    `checkh(bo[bi].m.b, 7'h35);
    bi = 3;
    `checkh(bp[bi].m.b, 7'h44);
    `checkh(bp[bi].m.c, 3'h1);
    release bo[2].m.b;
    release bp[3].m;
  end

  // An element index out of range does not read the force of another path
  typedef struct {
    logic [6:0] x;
    logic [6:0] y;
  } xy_t;
  initial begin
    xy_t bx[2];
    xy_t bxu[2];
    int bi;
    for (int n = 0; n < 2; ++n) begin
      bx[n] = '{x: 7'(n + 1), y: 7'(n + 3)};
      bxu[n] = '{x: 7'(n + 1), y: 7'(n + 3)};
    end
    force bx[1].x = 7'h61;
    force bx[0].y = 7'h62;
    bi = 2;
    `checkh(bx[bi].x, bxu[bi].x);
    release bx[1].x;
    release bx[0].y;
  end

  // A whole element read with a non-constant index beside a member released but never forced
  initial begin
    xy_t rx[2];
    xy_t rxu[2];
    xy_t re;
    xy_t reu;
    int ri;
    rx[1] = '{x: 7'h11, y: 7'h12};
    rxu[1] = '{x: 7'h11, y: 7'h12};
    release rx[1].x;
    ri = 1;
    re = rx[ri];
    `checkh(re.x, 7'h11);
    `checkh(re.y, 7'h12);
    ri = 2;
    re = rx[ri];
    reu = rxu[ri];
    `checkh(re.x, reu.x);
  end

  // A forced member of a union in an element, beside the other member of another element
  typedef union {
    logic [6:0] a;
    logic [6:0] b;
  } bu_t;
  typedef struct {
    bu_t u;
    logic flag;
  } bus_t;
  initial begin
    bus_t bu[2];
    bu[0].u.b = 7'h5;
    force bu[1].u.a = 7'h35;
    `checkh(bu[1].u.a, 7'h35);
    `checkh(bu[0].u.b, 7'h5);
    release bu[1].u.a;
  end

  // A member of an element of a net, forced and read below
  bs_t bsrc[2];
  wire bs_t bw[2];
  assign bw = bsrc;
  initial begin
    bsrc[1].m.b = 7'h1;
    #1;
    force bw[1].m = '{b: 7'h31, c: 3'h2};
    #1;
    `checkh(bw[1].m.b, 7'h31);
    release bw[1].m;
    #1;
    `checkh(bw[1].m.b, 7'h1);
  end

  // Reads above forced members of elements, and nested and overlaid forces
  typedef union {
    logic [6:0] a;
    logic [6:0] b;
  } nu_t;
  typedef struct {
    bm_t m;
    nu_t u;
  } ns_t;
  initial begin
    ns_t na[2];
    ns_t ncp[2];
    ns_t ne;
    bm_t nm;
    bs_t nd[2][2];
    bs_t nrow[2];
    na[1].m.c = 3'h2;
    force na[1].m.b = 7'h11;
    force na[1].u.a = 7'h12;
    ne = na[1];
    `checkh(ne.m.b, 7'h11);
    `checkh(ne.u.a, 7'h12);
    nm = na[1].m;
    `checkh(nm.b, 7'h11);
    `checkh(nm.c, 3'h2);
    ncp = na;
    `checkh(ncp[1].m.b, 7'h11);
    `checkh(na[1].u.b, 7'h12);
    force nd[1][0].m.b = 7'h13;
    nrow[0].m.b = 7'h13;
    `checkh(nd[1] == nrow, 1'b1);
    force na[1].m = '{b: 7'h21, c: 3'h4};
    `checkh(na[1].m.b, 7'h21);
    force na[1].m.b = 7'h22;
    `checkh(na[1].m.b, 7'h22);
    `checkh(na[1].m.c, 3'h4);
    force na[1].u.b = 7'h23;
    `checkh(na[1].u.a, 7'h23);
    release na[1].u.b;
    `checkh(na[1].u.a, 7'h23);
  end

  // Members of a union in an element are overlaid
  typedef union {
    logic [6:0] a;
    logic [6:0] b;
  } eu_t;
  typedef struct {
    eu_t u;
    logic [4:0] k;
  } ue_t;
  initial begin
    ue_t ua[3:1];
    ue_t uacp[3:1];
    ue_t ucp;
    for (int n = 1; n <= 3; ++n) begin
      ua[n].u.a = 7'(n);
      ua[n].k = 5'(n + 10);
    end
    force ua[2].u.a = 7'h55;
    uacp = ua;
    `checkh(uacp[2].u.a, 7'h55);
    `checkh(uacp[1].u.a, 7'h1);
    `checkh(uacp[3].k, 5'd13);
    `checkh(ua[2].u.b, 7'h55);
    // A write of the other member of the forced union, and of members beside it
    ua[2].u.b = 7'h11;
    ua[2].k = 5'h7;
    ua[3].u.b = 7'h22;
    uacp = ua;
    ucp = ua[2];
    `checkh(uacp[2].u.a, 7'h55);
    `checkh(uacp[2].k, 5'h7);
    `checkh(uacp[3].u.b, 7'h22);
    `checkh(ucp.u.a, 7'h55);
    release ua[2].u.a;
    uacp = ua;
    `checkh(uacp[2].u.a, 7'h55);
    ua[2].u.a = 7'h33;
    uacp = ua;
    `checkh(uacp[2].u.a, 7'h33);
  end

  // After every case
  initial begin
    #10;
    $finish;
  end
endmodule
