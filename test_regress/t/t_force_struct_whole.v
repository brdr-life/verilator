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

  initial begin
    #10;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
