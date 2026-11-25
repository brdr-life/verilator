// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  // Non-constant indices of the reads
  int i;
  int j;

  // Array of structs with a member of an element forced, read directly and through a
  // read-write reference
  typedef struct {
    struct {logic [6:0] value;} arr[3:2];
    logic flag;
  } st_t;
  st_t s;
  logic [6:0] q;
  logic [6:0] qr;
  function automatic logic [6:0] get(ref logic [6:0] value);
    return value;
  endfunction
  assign q = s.arr[i].value;
  initial begin
    force s.arr[3].value = 7'h25;
    qr = get(s.arr[i].value);
  end

  // Two non-constant indices, one error
  typedef struct {logic [4:0] m2[1:2][5:3];} md_t;
  md_t sm;
  logic [4:0] q2;
  assign q2 = sm.m2[i][j];
  initial force sm.m2[2][3] = 5'h15;

  typedef struct {logic [6:0] x[3:2];} a_t;
  typedef struct {logic [6:0] y[3:2];} b_t;
  typedef union {
    a_t a;
    b_t b;
  } u_t;

  // Array in a union member that is overlaid by the one with a forced element
  typedef struct {
    u_t u;
    logic flag;
  } su_t;
  su_t su;
  logic [6:0] qu;
  assign qu = su.u.b.y[i];
  initial force su.u.a.x[3] = 7'h31;

  // Array below a forced element of an array of structs
  typedef struct {a_t e[2:1];} se_t;
  se_t se;
  logic [6:0] qe;
  assign qe = se.e[2].x[i];
  initial force se.e[2] = se.e[1];

  // Whole array member forced, which forces each element
  typedef struct {logic [6:0] m[3:1];} whole_t;
  whole_t sw;
  logic [6:0] qw;
  assign qw = sw.m[i];
  initial force sw.m = '{7'h53, 7'h52, 7'h51};

  // Forced element read through a read-write reference
  st_t sx;
  logic [6:0] qx;
  initial begin
    force sx.arr[3].value = 7'h61;
    qx = get(sx.arr[3].value);
  end

  // Array element and another member forced, read through selects with non-constant indices
  typedef struct {
    logic [7:0] vec;
    logic [3:0] arr[3];
    logic flag;
  } st2_t;
  st2_t s2;
  logic [3:0] r;
  logic [3:0] v;
  assign r = s2.arr[i-1];
  assign v = s2.vec[i+:4];  // Supported
  initial begin
    force s2.flag = 1'b1;
    force s2.arr[0] = 4'hc;
  end

  // A member array of an element read with a non-constant index, beside a forced element of
  // that member array in another element
  typedef struct {logic [3:0] m[2];} ma_t;
  ma_t ae[3];
  logic [3:0] qae;
  assign qae = ae[0].m[i];
  initial force ae[2].m[1] = 4'h9;
endmodule
