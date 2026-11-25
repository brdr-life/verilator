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
    logic [6:0] x;
    logic [8:0] y;
  } in_t;
  typedef struct {
    in_t in;
    logic [32:0] arr[1:3];
    logic flag;
  } st_t;

  // Forces of the whole struct and of its members, read whole and by member
  st_t s;
  wire st_t ws = s;
  wire [8:0] wy = s.in.y;
  initial begin
    st_t f, g, cp;
    in_t ci;
    logic sel;
    int idx;
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
    force s.in.x = 7'd5;
    force s.arr[2] = 99;
    cp = s;
    `checkh(cp.in.x, 7'd5);
    `checkh(cp.in.y, 9'd2);
    `checkh(cp.arr[1], 10);
    `checkh(cp.arr[2], 99);
    ci = s.in;
    `checkh(ci.x, 7'd5);
    s.in.y = 3;
    cp = s;
    `checkh(cp.in.y, 9'd3);
    // A write is seen by a later read of the whole, but not over a force
    idx = 3;
    s.arr[idx] = 13;
    cp = s;
    `checkh(cp.arr[3], 13);
    s.arr[2] = 14;
    cp = s;
    `checkh(cp.arr[2], 99);
    s.in = f.in;
    cp = s;
    `checkh(cp.in.x, 7'd5);
    #1;
    `checkh(ws.in.x, 7'd5);
    `checkh(ws.arr[2], 99);

    // A member read has the force of the whole, which replaces the member forces
    sel = 1;
    force s = sel ? f : g;
    `checkh(s.in.x, 7'd21);
    `checkh(s.arr[2], 31);
    `checkh(s.flag, 1'b1);
    ci = s.in;
    `checkh(ci.y, 9'd22);
    sel = 0;
    f.in.y = 77;
    g.in.y = 78;
    #1;
    `checkh(s.in.x, 7'd41);
    `checkh(s.in.y, 9'd78);
    `checkh(wy, 9'd78);
    `checkh(ws.in.x, 7'd41);

    // A member force over the force of the whole
    force s.in = ci;
    force s.in.y = 9'd6;
    cp = s;
    `checkh(cp.in.x, 7'd21);
    `checkh(cp.in.y, 9'd6);
    `checkh(cp.arr[3], 32);
    release s.in;
    `checkh(s.in.x, 7'd41);
    `checkh(s.in.y, 9'd78);
    force s.arr[2] = 98;

    // A release of the whole releases the members, which keep their values
    release s;
    `checkh(s.in.x, 7'd41);
    `checkh(s.arr[2], 98);
    s.arr[2] = 3;
    s.in.x = 4;
    cp = s;
    `checkh(cp.arr[2], 3);
    `checkh(cp.in.x, 7'd4);
    `checkh(cp.flag, 1'b1);
  end

  // Members of a union are overlaid
  typedef union {
    logic [30:0] a;
    logic [30:0] b;
  } u_t;
  initial begin
    u_t u, uf, ucp;
    bit en_b;
    en_b = 0;
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
    // A release of the other member releases the force
    force u.a = 5;
    release u.b;
    `checkh(u.a, 5);
    u.b = 6;
    `checkh(u.a, 6);
  end

  // A union as a member of a struct
  typedef struct {
    u_t u;
    logic [4:0] k;
  } su_t;
  initial begin
    su_t su, sucp;
    su.u.a = 1;
    su.k = 2;
    force su.u.a = 3;
    `checkh(su.u.b, 3);
    sucp = su;
    `checkh(sucp.u.a, 3);
    `checkh(sucp.k, 5'h2);
    su.u.b = 7;
    su.k = 4;
    sucp = su;
    `checkh(sucp.u.a, 3);
    `checkh(sucp.k, 5'h4);
    force su.u.b = 5;
    `checkh(su.u.a, 5);
    sucp = su;
    `checkh(sucp.u.a, 5);
    release su.u.a;
    sucp = su;
    `checkh(sucp.u.b, 5);
    su.u.a = 8;
    sucp = su;
    `checkh(sucp.u.b, 8);
  end

  // A procedural assignment of a member beside a forced member, read whole
  typedef struct {
    logic [6:0] x;
    logic [8:0] y;
    logic [4:0] z;
  } pa_t;
  initial begin
    pa_t pa, pacp;
    logic [6:0] v;
    pa.x = 1;
    pa.y = 2;
    pa.z = 3;
    v = 7'h15;
    force pa.y = 9'h99;
    // verilator lint_off IEEEMAYDEPRECATE
    assign pa.x = v;
    // verilator lint_on IEEEMAYDEPRECATE
    pacp = pa;
    `checkh(pacp.x, 7'h15);
    `checkh(pacp.y, 9'h99);
    `checkh(pacp.z, 5'h3);
    pa.z = 4;
    pacp = pa;
    `checkh(pacp.x, 7'h15);
    `checkh(pacp.z, 5'h4);
    // verilator lint_off IEEEMAYDEPRECATE
    deassign pa.x;
    // verilator lint_on IEEEMAYDEPRECATE
    pacp = pa;
    `checkh(pacp.x, 7'h15);
    pa.x = 6;
    pacp = pa;
    `checkh(pacp.x, 7'h6);
    `checkh(pacp.y, 9'h99);
    release pa.y;
    pa.y = 7;
    pacp = pa;
    `checkh(pacp.y, 9'h7);
  end

  // Non-blocking writes beside a forced member, read whole after them
  initial begin
    in_t nb, nbcp;
    nb.x = 1;
    nb.y = 2;
    force nb.x = 7'h55;
    nb.y <= 3;
    nb.x <= 4;
    #1;
    nbcp = nb;
    `checkh(nbcp.x, 7'h55);
    `checkh(nbcp.y, 9'h3);
    release nb.x;
    nb.y <= 5;
    #1;
    nbcp = nb;
    `checkh(nbcp.x, 7'h55);
    `checkh(nbcp.y, 9'h5);
    nb.x <= 6;
    #1;
    nbcp = nb;
    `checkh(nbcp.x, 7'h6);
  end

  // Writes through an associative array beside a forced member, read whole
  typedef struct {
    int aa[int];
    logic [6:0] v;
  } qa_t;
  initial begin
    qa_t qa, qacp;
    int qk;
    qk = 2;
    qa.aa[1] = 5;
    qa.v = 7'h01;
    force qa.v = 7'h12;
    qacp = qa;
    `checkh(qacp.aa[1], 5);
    `checkh(qacp.v, 7'h12);
    qa.aa[1] = 6;
    qa.aa[qk] = 7;
    qacp = qa;
    `checkh(qacp.aa[1], 6);
    `checkh(qacp.aa[2], 7);
    `checkh(qacp.v, 7'h12);
    release qa.v;
  end

  // A read of the whole where only a member that is not the first is forced
  initial begin
    st_t s2, cp2;
    s2.in.x = 1;
    s2.in.y = 2;
    s2.arr = '{50, 51, 52};
    s2.flag = 0;
    force s2.in.y = 9'd9;
    cp2 = s2;
    `checkh(cp2.in.x, 7'd1);
    `checkh(cp2.in.y, 9'd9);
    `checkh(cp2.arr[3], 52);
    s2.in.x = 3;
    s2.in.y = 4;
    cp2 = s2;
    `checkh(cp2.in.x, 7'd3);
    `checkh(cp2.in.y, 9'd9);
    release s2.in.y;
    cp2 = s2;
    `checkh(cp2.in.y, 9'd9);
  end

  // Writes with a call on the right or in the index, beside forced members
  function automatic in_t mk_in(logic [6:0] x, logic [8:0] y);
    mk_in.x = x;
    mk_in.y = y;
  endfunction
  function automatic logic [32:0] mk_word(logic [32:0] v);
    $write("");  // Not inlined as a constant
    return v;
  endfunction
  function automatic int next_idx(int i);
    $write("");
    return i;
  endfunction
  initial begin
    st_t w, cpw;
    int widx;
    w.in.x = 1;
    w.in.y = 2;
    w.arr = '{60, 61, 62};
    w.flag = 0;
    force w.in.x = 7'd5;
    force w.arr[2] = 99;
    w.in = mk_in(7'd7, 9'd8);
    cpw = w;
    `checkh(cpw.in.x, 7'd5);
    `checkh(cpw.in.y, 9'd8);
    widx = 3;
    w.arr[widx] = mk_word(15);
    cpw = w;
    `checkh(cpw.arr[3], 15);
    widx = 2;
    w.arr[widx] = mk_word(16);
    cpw = w;
    `checkh(cpw.arr[2], 99);
    w.arr[next_idx(1)] = 17;
    cpw = w;
    `checkh(cpw.arr[1], 17);
    `checkh(cpw.arr[2], 99);
    w.arr[next_idx(2)] = 18;
    cpw = w;
    `checkh(cpw.arr[2], 99);
    `checkh(cpw.in.x, 7'd5);
    // An index read from the variable that is written
    w.in.y = 9'd3;
    w.arr[w.in.y[1:0]] = 21;
    cpw = w;
    `checkh(cpw.arr[3], 21);
    `checkh(cpw.arr[2], 99);
    w.in.y = 9'd2;
    w.arr[w.in.y[1:0]] = 22;
    cpw = w;
    `checkh(cpw.arr[2], 99);
    `checkh(cpw.arr[3], 21);
    release w.arr[2];
    release w.in.x;
    cpw = w;
    `checkh(cpw.arr[2], 99);
    `checkh(cpw.in.x, 7'd5);
  end

  // Members of different widths, the first forced
  typedef struct {
    logic [6:0] a;
    logic [32:0] b;
    logic [2:0] c;
  } m_t;
  initial begin
    m_t m, mcp;
    m.a = 1;
    m.b = 2;
    m.c = 3;
    force m.a = 7'h7e;
    m.b = 33;
    m.a = 7'h01;
    mcp = m;
    `checkh(mcp.a, 7'h7e);
    `checkh(mcp.b, 33);
    `checkh(mcp.c, 3'd3);
    release m.a;
    m.a = 7'h02;
    mcp = m;
    `checkh(mcp.a, 7'h02);
  end

  // A member write while the whole is forced to a variable
  initial begin
    in_t fs, fsrc;
    fs.x = 1;
    fs.y = 2;
    fsrc.x = 3;
    fsrc.y = 4;
    force fs = fsrc;
    fs.x = 7'd99;
    `checkh(fs.x, 7'd3);
    fsrc.y = 9'd40;
    #1;
    `checkh(fs.y, 9'd40);
    release fs;
    fs.x = 7'd7;
    `checkh(fs.x, 7'd7);
    `checkh(fs.y, 9'd40);
  end

  // Reads at each level above a member of a struct in an array in a struct member
  typedef struct {
    logic [4:0] f;
    logic [4:0] g;
  } leaf_t;
  typedef struct {
    leaf_t l[2:1];
    logic [6:0] tag;
  } mid_t;
  typedef struct {
    mid_t m;
    int id;
  } top_t;
  initial begin
    top_t n, ncp;
    mid_t nm;
    leaf_t nl;
    n.m.l[1].f = 5'h1;
    n.m.l[1].g = 5'h2;
    n.m.l[2].f = 5'h3;
    n.m.l[2].g = 5'h4;
    n.m.tag = 7'h55;
    n.id = 9;
    force n.m.l[2].g = 5'ha;
    ncp = n;
    `checkh(ncp.m.l[2].g, 5'ha);
    `checkh(ncp.m.l[1].g, 5'h2);
    `checkh(ncp.id, 9);
    nm = n.m;
    `checkh(nm.l[2].g, 5'ha);
    `checkh(nm.tag, 7'h55);
    nl = n.m.l[2];
    `checkh(nl.g, 5'ha);
    `checkh(nl.f, 5'h3);
    n.m.l[2].g = 5'h0;
    n.m.l[2].f = 5'h6;
    ncp = n;
    `checkh(ncp.m.l[2].f, 5'h6);
    `checkh(ncp.m.l[2].g, 5'ha);
    release n.m.l[2].g;
    n.m.l[2].g = 5'h1;
    ncp = n;
    `checkh(ncp.m.l[2].g, 5'h1);
  end

  // A member forced at each depth of nested structs
  typedef struct {
    logic [8:0] v;
    logic [8:0] w;
  } d0_t;
  typedef struct {
    logic [8:0] v;
    d0_t c;
    logic [8:0] w;
  } d1_t;
  typedef struct {
    logic [8:0] v;
    d1_t c;
    logic [8:0] w;
  } d2_t;
  typedef struct {
    logic [8:0] v;
    d2_t c;
    logic [8:0] w;
  } d3_t;
  typedef struct {
    logic [8:0] v;
    d3_t c;
    logic [8:0] w;
  } d4_t;
  typedef struct {
    logic [8:0] v;
    d4_t c;
    logic [8:0] w;
  } d5_t;
  typedef struct {
    logic [8:0] v;
    d5_t c;
    logic [8:0] w;
  } d6_t;
  typedef struct {
    logic [8:0] v;
    d6_t c;
    logic [8:0] w;
  } d7_t;
  typedef struct {
    logic [8:0] v;
    d7_t c;
    logic [8:0] w;
  } d8_t;
  initial begin
    d8_t ds, dcp;
    ds.v = 9'd0;
    ds.w = 9'd100;
    ds.c.v = 9'd1;
    ds.c.w = 9'd101;
    ds.c.c.v = 9'd2;
    ds.c.c.w = 9'd102;
    ds.c.c.c.v = 9'd3;
    ds.c.c.c.w = 9'd103;
    ds.c.c.c.c.v = 9'd4;
    ds.c.c.c.c.w = 9'd104;
    ds.c.c.c.c.c.v = 9'd5;
    ds.c.c.c.c.c.w = 9'd105;
    ds.c.c.c.c.c.c.v = 9'd6;
    ds.c.c.c.c.c.c.w = 9'd106;
    ds.c.c.c.c.c.c.c.v = 9'd7;
    ds.c.c.c.c.c.c.c.w = 9'd107;
    ds.c.c.c.c.c.c.c.c.v = 9'd8;
    ds.c.c.c.c.c.c.c.c.w = 9'd108;
    force ds.v = 9'd200;
    force ds.c.v = 9'd201;
    force ds.c.c.v = 9'd202;
    force ds.c.c.c.v = 9'd203;
    force ds.c.c.c.c.v = 9'd204;
    force ds.c.c.c.c.c.v = 9'd205;
    force ds.c.c.c.c.c.c.v = 9'd206;
    force ds.c.c.c.c.c.c.c.v = 9'd207;
    force ds.c.c.c.c.c.c.c.c.v = 9'd208;
    dcp = ds;
    `checkh(dcp.v, 9'd200);
    `checkh(dcp.w, 9'd100);
    `checkh(dcp.c.v, 9'd201);
    `checkh(dcp.c.w, 9'd101);
    `checkh(dcp.c.c.v, 9'd202);
    `checkh(dcp.c.c.w, 9'd102);
    `checkh(dcp.c.c.c.v, 9'd203);
    `checkh(dcp.c.c.c.w, 9'd103);
    `checkh(dcp.c.c.c.c.v, 9'd204);
    `checkh(dcp.c.c.c.c.w, 9'd104);
    `checkh(dcp.c.c.c.c.c.v, 9'd205);
    `checkh(dcp.c.c.c.c.c.w, 9'd105);
    `checkh(dcp.c.c.c.c.c.c.v, 9'd206);
    `checkh(dcp.c.c.c.c.c.c.w, 9'd106);
    `checkh(dcp.c.c.c.c.c.c.c.v, 9'd207);
    `checkh(dcp.c.c.c.c.c.c.c.w, 9'd107);
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 9'd208);
    `checkh(dcp.c.c.c.c.c.c.c.c.w, 9'd108);
    ds.w = 9'd1;
    ds.v = 9'd0;
    ds.c.w = 9'd2;
    ds.c.v = 9'd0;
    ds.c.c.w = 9'd3;
    ds.c.c.v = 9'd0;
    ds.c.c.c.w = 9'd4;
    ds.c.c.c.v = 9'd0;
    ds.c.c.c.c.w = 9'd5;
    ds.c.c.c.c.v = 9'd0;
    ds.c.c.c.c.c.w = 9'd6;
    ds.c.c.c.c.c.v = 9'd0;
    ds.c.c.c.c.c.c.w = 9'd7;
    ds.c.c.c.c.c.c.v = 9'd0;
    ds.c.c.c.c.c.c.c.w = 9'd8;
    ds.c.c.c.c.c.c.c.v = 9'd0;
    ds.c.c.c.c.c.c.c.c.w = 9'd9;
    ds.c.c.c.c.c.c.c.c.v = 9'd0;
    dcp = ds;
    `checkh(dcp.v, 9'd200);
    `checkh(dcp.w, 9'd1);
    `checkh(dcp.c.v, 9'd201);
    `checkh(dcp.c.w, 9'd2);
    `checkh(dcp.c.c.v, 9'd202);
    `checkh(dcp.c.c.w, 9'd3);
    `checkh(dcp.c.c.c.v, 9'd203);
    `checkh(dcp.c.c.c.w, 9'd4);
    `checkh(dcp.c.c.c.c.v, 9'd204);
    `checkh(dcp.c.c.c.c.w, 9'd5);
    `checkh(dcp.c.c.c.c.c.v, 9'd205);
    `checkh(dcp.c.c.c.c.c.w, 9'd6);
    `checkh(dcp.c.c.c.c.c.c.v, 9'd206);
    `checkh(dcp.c.c.c.c.c.c.w, 9'd7);
    `checkh(dcp.c.c.c.c.c.c.c.v, 9'd207);
    `checkh(dcp.c.c.c.c.c.c.c.w, 9'd8);
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 9'd208);
    `checkh(dcp.c.c.c.c.c.c.c.c.w, 9'd9);
    release ds.v;
    release ds.c.v;
    release ds.c.c.v;
    release ds.c.c.c.v;
    release ds.c.c.c.c.v;
    release ds.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.c.v;
    release ds.c.c.c.c.c.c.c.c.v;
    ds.c.c.c.c.c.c.c.c.v = 9'd7;
    dcp = ds;
    `checkh(dcp.c.c.c.c.c.c.c.c.v, 9'd7);
    `checkh(dcp.v, 9'd200);
  end

  initial begin
    #10;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
