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
    logic [7:0] x;
    logic [7:0] y;
  } in_t;
  typedef struct {
    in_t in;
    logic [31:0] arr[3];
    logic flag;
  } st_t;
  typedef union {
    int a;
    int b;
  } u_t;

  st_t s, f, g, cp;
  in_t ci;
  wire st_t ws = s;
  wire [7:0] wy = s.in.y;
  logic sel;
  u_t u, uf, ucp;
  bit en_b = 0;
  int idx;

  // Writes through an associative array beside a forced member, read whole
  typedef struct {
    int aa[int];
    logic [7:0] v;
  } qa_t;
  qa_t qa, qacp;
  int qk = 2;
  initial begin
    qa.aa[1] = 5;
    qa.v = 8'h01;
    force qa.v = 8'h12;
    qacp = qa;
    `checkh(qacp.aa[1], 5);
    `checkh(qacp.v, 8'h12);
    qa.aa[1] = 6;
    qa.aa[qk] = 7;
    qacp = qa;
    `checkh(qacp.aa[1], 6);
    `checkh(qacp.aa[2], 7);
    `checkh(qacp.v, 8'h12);
    release qa.v;
  end

  initial begin
    s.in.x = 1;
    s.in.y = 2;
    s.arr = '{10, 11, 12};
    s.flag = 0;
    f.in.x = 21;
    f.in.y = 22;
    f.arr = '{30, 31, 32};
    f.flag = 1;
    g = f;
    g.in.x = 41;

    // A read of the whole or of a struct member has the forced members below it
    force s.in.x = 8'd5;
    force s.arr[1] = 99;
    cp = s;
    `checkh(cp.in.x, 8'd5);
    `checkh(cp.in.y, 8'd2);
    `checkh(cp.arr[0], 10);
    `checkh(cp.arr[1], 99);
    ci = s.in;
    `checkh(ci.x, 8'd5);
    s.in.y = 3;
    cp = s;
    `checkh(cp.in.y, 8'd3);
    // A write is seen by a later read of the whole, but not over a force
    idx = 2;
    s.arr[idx] = 13;
    cp = s;
    `checkh(cp.arr[2], 13);
    s.arr[1] = 14;
    cp = s;
    `checkh(cp.arr[1], 99);
    s.in = f.in;
    cp = s;
    `checkh(cp.in.x, 8'd5);
    #1;
    `checkh(ws.in.x, 8'd5);
    `checkh(ws.arr[1], 99);

    // A member read has the force of the whole, which replaces the member forces
    sel = 1;
    force s = sel ? f : g;
    `checkh(s.in.x, 8'd21);
    `checkh(s.arr[1], 31);
    `checkh(s.flag, 1'b1);
    ci = s.in;
    `checkh(ci.y, 8'd22);
    sel = 0;
    f.in.y = 77;
    g.in.y = 78;
    #1;
    `checkh(s.in.x, 8'd41);
    `checkh(s.in.y, 8'd78);
    `checkh(wy, 8'd78);
    `checkh(ws.in.x, 8'd41);

    // A member force over the force of the whole
    force s.in = ci;
    force s.in.y = 8'd6;
    cp = s;
    `checkh(cp.in.x, 8'd21);
    `checkh(cp.in.y, 8'd6);
    `checkh(cp.arr[2], 32);
    release s.in;
    `checkh(s.in.x, 8'd41);
    `checkh(s.in.y, 8'd78);
    force s.arr[1] = 98;

    // A release of the whole releases the members, which keep their values
    release s;
    `checkh(s.in.x, 8'd41);
    `checkh(s.arr[1], 98);
    s.arr[1] = 3;
    s.in.x = 4;
    cp = s;
    `checkh(cp.arr[1], 3);
    `checkh(cp.in.x, 8'd4);
    `checkh(cp.flag, 1'b1);

    // Members of a union are overlaid
    u.a = 1;
    force u.a = 2;
    if (en_b) force u.b = 3;
    ucp = u;
    `checkh(ucp.a, 2);
    `checkh(u.b, 2);
    u.b = 7;
    ucp = u;
    `checkh(ucp.a, 2);
    force u.b = 4;
    `checkh(u.a, 4);
    uf.a = 9;
    force u = uf;
    `checkh(u.a, 9);
    `checkh(u.b, 9);
    release u;
    `checkh(u.b, 9);

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
