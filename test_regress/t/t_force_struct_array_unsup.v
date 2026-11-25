// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  typedef struct {
    logic [7:0] x;
    logic [7:0] y;
  } st_t;

  initial begin
    st_t s[2];
    st_t w;
    st_t big[32768][32768];
    force s[1].y = 8'h40;
    force s[0] = w;
    force big[0][0].y = 8'h40;
    $finish;
  end

  // Reads above forced members of elements, and forces of nested or overlaid members
  typedef struct {
    logic [6:0] b;
    logic [2:0] c;
  } in_t;
  typedef union {
    logic [6:0] a;
    logic [6:0] b;
  } u_t;
  typedef struct {
    in_t m;
    u_t u;
  } ms_t;
  initial begin
    ms_t ma[2];
    ms_t md[2][2];
    ms_t mrow[2];
    ms_t macp[2];
    ms_t me;
    in_t mi;
    logic [6:0] mx;
    logic meq;
    int mk;
    force ma[1].m.b = 7'h1;
    force ma[1].u.a = 7'h2;
    me = ma[1];
    mi = ma[1].m;
    macp = ma;
    mx = ma[1].u.b;
    force md[1][0].m.b = 7'h1;
    meq = md[1] == mrow;
    me = ma[mk];
    mx = ma[mk].u.b;
    force ma[1].m = '{b: 7'h3, c: 3'h4};
    release ma[1].u.b;
    force ma[0].m = '{b: 7'h5, c: 3'h6};
    force ma[0].m.b = 7'h7;
  end

  // A path below a forced member of an element read through a read-write reference
  typedef struct {
    logic [6:0] value;
    logic flag;
  } rw_t;
  function automatic logic [6:0] get(ref logic [6:0] value);
    return value;
  endfunction
  initial begin
    rw_t ra[2];
    logic [6:0] rx;
    int ri;
    force ra[1].value = 7'h31;
    rx = get(ra[1].value);
    rx = get(ra[ri].value);
  end
endmodule
