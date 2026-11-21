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
  typedef struct {
    logic [7:0] a;
    int b;
    logic [3:0] c;
  } m_t;
  typedef struct {
    logic [3:0] f;
    logic [3:0] g;
  } leaf_t;
  typedef struct {
    leaf_t l[2];
    logic [7:0] tag;
  } mid_t;
  typedef struct {
    mid_t m;
    int id;
  } top_t;
  typedef struct {
    logic [7:0] v;
    logic [7:0] w;
  } d0_t;
  typedef struct {
    logic [7:0] v;
    d0_t c;
    logic [7:0] w;
  } d1_t;
  typedef struct {
    logic [7:0] v;
    d1_t c;
    logic [7:0] w;
  } d2_t;
  typedef struct {
    logic [7:0] v;
    d2_t c;
    logic [7:0] w;
  } d3_t;
  typedef struct {
    logic [7:0] v;
    d3_t c;
    logic [7:0] w;
  } d4_t;
  typedef struct {
    logic [7:0] v;
    d4_t c;
    logic [7:0] w;
  } d5_t;
  typedef struct {
    logic [7:0] v;
    d5_t c;
    logic [7:0] w;
  } d6_t;
  typedef struct {
    logic [7:0] v;
    d6_t c;
    logic [7:0] w;
  } d7_t;
  typedef struct {
    logic [7:0] v;
    d7_t c;
    logic [7:0] w;
  } d8_t;
  typedef union {
    int a;
    int b;
  } u_t;

  st_t s, f, g, cp;
  in_t ci;
  st_t s2, cp2;
  st_t w, cpw;
  m_t m, mcp;
  in_t fs, fsrc;
  top_t n, ncp;
  mid_t nm;
  leaf_t nl;
  d8_t ds, dcp;  // A member forced at each depth
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

    // Members of different widths, the first forced
    m.a = 1;
    m.b = 2;
    m.c = 3;
    force m.a = 8'h7e;
    m.b = 33;
    m.a = 8'h01;
    mcp = m;
    `checkh(mcp.a, 8'h7e);
    `checkh(mcp.b, 33);
    `checkh(mcp.c, 4'd3);
    release m.a;
    m.a = 8'h02;
    mcp = m;
    `checkh(mcp.a, 8'h02);

    // A member write while the whole is forced to a variable
    fs.x = 1;
    fs.y = 2;
    fsrc.x = 3;
    fsrc.y = 4;
    force fs = fsrc;
    fs.x = 8'd99;
    `checkh(fs.x, 8'd3);
    fsrc.y = 8'd40;
    #1;
    `checkh(fs.y, 8'd40);
    release fs;
    fs.x = 8'd7;
    `checkh(fs.x, 8'd7);
    `checkh(fs.y, 8'd40);

    // Reads at each level above a member of a struct in an array in a struct member
    n.m.l[0].f = 4'h1;
    n.m.l[0].g = 4'h2;
    n.m.l[1].f = 4'h3;
    n.m.l[1].g = 4'h4;
    n.m.tag = 8'h55;
    n.id = 9;
    force n.m.l[1].g = 4'ha;
    ncp = n;
    `checkh(ncp.m.l[1].g, 4'ha);
    `checkh(ncp.m.l[0].g, 4'h2);
    `checkh(ncp.id, 9);
    nm = n.m;
    `checkh(nm.l[1].g, 4'ha);
    `checkh(nm.tag, 8'h55);
    nl = n.m.l[1];
    `checkh(nl.g, 4'ha);
    `checkh(nl.f, 4'h3);
    n.m.l[1].g = 4'h0;
    n.m.l[1].f = 4'h6;
    ncp = n;
    `checkh(ncp.m.l[1].f, 4'h6);
    `checkh(ncp.m.l[1].g, 4'ha);
    release n.m.l[1].g;
    n.m.l[1].g = 4'h1;
    ncp = n;
    `checkh(ncp.m.l[1].g, 4'h1);

    // A member forced at each depth of nested structs
    ds.v = 8'd0;
    ds.w = 8'd100;
    ds.c.v = 8'd1;
    ds.c.w = 8'd101;
    ds.c.c.v = 8'd2;
    ds.c.c.w = 8'd102;
    ds.c.c.c.v = 8'd3;
    ds.c.c.c.w = 8'd103;
    ds.c.c.c.c.v = 8'd4;
    ds.c.c.c.c.w = 8'd104;
    ds.c.c.c.c.c.v = 8'd5;
    ds.c.c.c.c.c.w = 8'd105;
    ds.c.c.c.c.c.c.v = 8'd6;
    ds.c.c.c.c.c.c.w = 8'd106;
    ds.c.c.c.c.c.c.c.v = 8'd7;
    ds.c.c.c.c.c.c.c.w = 8'd107;
    ds.c.c.c.c.c.c.c.c.v = 8'd8;
    ds.c.c.c.c.c.c.c.c.w = 8'd108;
    force ds.v = 8'd200;
    force ds.c.v = 8'd201;
    force ds.c.c.v = 8'd202;
    force ds.c.c.c.v = 8'd203;
    force ds.c.c.c.c.v = 8'd204;
    force ds.c.c.c.c.c.v = 8'd205;
    force ds.c.c.c.c.c.c.v = 8'd206;
    force ds.c.c.c.c.c.c.c.v = 8'd207;
    force ds.c.c.c.c.c.c.c.c.v = 8'd208;
    dcp = ds;
    `checkh(dcp.v, 8'd200);
    `checkh(dcp.w, 8'd100);
    `checkh(dcp.c.v, 8'd201);
    `checkh(dcp.c.w, 8'd101);
    `checkh(dcp.c.c.v, 8'd202);
    `checkh(dcp.c.c.w, 8'd102);
    `checkh(dcp.c.c.c.v, 8'd203);
    `checkh(dcp.c.c.c.w, 8'd103);
    `checkh(dcp.c.c.c.c.v, 8'd204);
    `checkh(dcp.c.c.c.c.w, 8'd104);
    `checkh(dcp.c.c.c.c.c.v, 8'd205);
    `checkh(dcp.c.c.c.c.c.w, 8'd105);
    `checkh(dcp.c.c.c.c.c.c.v, 8'd206);
    `checkh(dcp.c.c.c.c.c.c.w, 8'd106);
    `checkh(dcp.c.c.c.c.c.c.c.v, 8'd207);
    `checkh(dcp.c.c.c.c.c.c.c.w, 8'd107);
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 8'd208);
    `checkh(dcp.c.c.c.c.c.c.c.c.w, 8'd108);
    ds.w = 8'd1;
    ds.v = 8'd0;
    ds.c.w = 8'd2;
    ds.c.v = 8'd0;
    ds.c.c.w = 8'd3;
    ds.c.c.v = 8'd0;
    ds.c.c.c.w = 8'd4;
    ds.c.c.c.v = 8'd0;
    ds.c.c.c.c.w = 8'd5;
    ds.c.c.c.c.v = 8'd0;
    ds.c.c.c.c.c.w = 8'd6;
    ds.c.c.c.c.c.v = 8'd0;
    ds.c.c.c.c.c.c.w = 8'd7;
    ds.c.c.c.c.c.c.v = 8'd0;
    ds.c.c.c.c.c.c.c.w = 8'd8;
    ds.c.c.c.c.c.c.c.v = 8'd0;
    ds.c.c.c.c.c.c.c.c.w = 8'd9;
    ds.c.c.c.c.c.c.c.c.v = 8'd0;
    dcp = ds;
    `checkh(dcp.v, 8'd200);
    `checkh(dcp.w, 8'd1);
    `checkh(dcp.c.v, 8'd201);
    `checkh(dcp.c.w, 8'd2);
    `checkh(dcp.c.c.v, 8'd202);
    `checkh(dcp.c.c.w, 8'd3);
    `checkh(dcp.c.c.c.v, 8'd203);
    `checkh(dcp.c.c.c.w, 8'd4);
    `checkh(dcp.c.c.c.c.v, 8'd204);
    `checkh(dcp.c.c.c.c.w, 8'd5);
    `checkh(dcp.c.c.c.c.c.v, 8'd205);
    `checkh(dcp.c.c.c.c.c.w, 8'd6);
    `checkh(dcp.c.c.c.c.c.c.v, 8'd206);
    `checkh(dcp.c.c.c.c.c.c.w, 8'd7);
    `checkh(dcp.c.c.c.c.c.c.c.v, 8'd207);
    `checkh(dcp.c.c.c.c.c.c.c.w, 8'd8);
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 8'd208);
    `checkh(dcp.c.c.c.c.c.c.c.c.w, 8'd9);
    release ds.v;
    release ds.c.v;
    release ds.c.c.v;
    release ds.c.c.c.v;
    release ds.c.c.c.c.v;
    release ds.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.c.c.v;
    ds.c.c.c.c.c.c.c.c.v = 8'd7;
    dcp = ds;
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 8'd7);
    `checkh(dcp.v, 8'd200);

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
