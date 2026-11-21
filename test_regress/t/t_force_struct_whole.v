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
  st_t s2, cp2;
  st_t w, cpw;
  int widx;
  wire st_t ws = s;
  wire [7:0] wy = s.in.y;
  logic sel;
  u_t u, uf, ucp;
  bit en_b = 0;
  int idx;

  function automatic in_t mk_in(logic [7:0] x, logic [7:0] y);
    mk_in.x = x;
    mk_in.y = y;
  endfunction
  function automatic logic [31:0] mk_word(int v);
    $write("");  // Not inlined as a constant
    return v;
  endfunction
  function automatic int next_idx(int i);
    $write("");
    return i;
  endfunction

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

    // A read of the whole where only a member that is not the first is forced
    s2.in.x = 1;
    s2.in.y = 2;
    s2.arr = '{50, 51, 52};
    s2.flag = 0;
    force s2.in.y = 8'd9;
    cp2 = s2;
    `checkh(cp2.in.x, 8'd1);
    `checkh(cp2.in.y, 8'd9);
    `checkh(cp2.arr[2], 52);
    s2.in.x = 3;
    s2.in.y = 4;
    cp2 = s2;
    `checkh(cp2.in.x, 8'd3);
    `checkh(cp2.in.y, 8'd9);
    release s2.in.y;
    cp2 = s2;
    `checkh(cp2.in.y, 8'd9);

    // Writes with a call on the right or in the index, beside forced members
    w.in.x = 1;
    w.in.y = 2;
    w.arr = '{60, 61, 62};
    w.flag = 0;
    force w.in.x = 8'd5;
    force w.arr[1] = 99;
    w.in = mk_in(8'd7, 8'd8);
    cpw = w;
    `checkh(cpw.in.x, 8'd5);
    `checkh(cpw.in.y, 8'd8);
    widx = 2;
    w.arr[widx] = mk_word(15);
    cpw = w;
    `checkh(cpw.arr[2], 15);
    widx = 1;
    w.arr[widx] = mk_word(16);
    cpw = w;
    `checkh(cpw.arr[1], 99);
    w.arr[next_idx(0)] = 17;
    cpw = w;
    `checkh(cpw.arr[0], 17);
    `checkh(cpw.arr[1], 99);
    w.arr[next_idx(1)] = 18;
    cpw = w;
    `checkh(cpw.arr[1], 99);
    `checkh(cpw.in.x, 8'd5);
    // An index read from the variable that is written
    w.in.y = 8'd2;
    w.arr[w.in.y[1:0]] = 21;
    cpw = w;
    `checkh(cpw.arr[2], 21);
    `checkh(cpw.arr[1], 99);
    w.in.y = 8'd1;
    w.arr[w.in.y[1:0]] = 22;
    cpw = w;
    `checkh(cpw.arr[1], 99);
    `checkh(cpw.arr[2], 21);
    release w.arr[1];
    release w.in.x;
    cpw = w;
    `checkh(cpw.arr[1], 99);
    `checkh(cpw.in.x, 8'd5);

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
