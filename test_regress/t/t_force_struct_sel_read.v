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
    logic [7:0] vec;
    int aa[int];
    logic flag;
  } st_t;
  st_t s;
  st_t s2;
  int i;

  // Part-selects through a queue beside a forced part-select
  typedef struct {
    logic [7:0] vec;
    logic [7:0] q[$];
  } sq_t;
  sq_t sq;
  initial begin
    sq.vec = 8'h34;
    sq.q.push_back(8'h56);
    force sq.vec[3:0] = 4'hf;
    `checkh(sq.q[0][3:0], 4'h6);
    `checkh(sq.q[sq.q.size()-1][7:4], 4'h5);
    `checkh(sq.vec[3:0], 4'hf);
    release sq.vec[3:0];
  end

  initial begin
    s.vec = 8'h34;
    s.aa[3] = 7;
    i = 2;
    // Reads of a variable with a forced part-select that do not select from it
    s2.vec = 8'h34;
    s2.flag = 1'b0;
    force s2.vec[3:0] = 4'hf;
    #1;
    `checkh(s2.flag, 1'b0);
    `checkh(s2.vec[3:0], 4'hf);
    release s2.vec[3:0];
    force s.flag = 1'b1;
    #1;
    // Other members read through non-constant and associative selects
    `checkh(s.vec[i], 1'b1);
    `checkh(s.vec[i+:4], 4'hd);
    `checkh(s.aa[3], 7);
    `checkh(s.aa[i+1], 7);
    `checkh(s.flag, 1'b1);
    release s.flag;
    // Selects of a member with a forced part-select
    force s.vec[3:0] = 4'hf;
    #1;
    `checkh(s.vec, 8'h3f);
    `checkh(s.vec[2], 1'b1);
    `checkh(s.vec[i], 1'b1);
    `checkh(s.vec[5:2], 4'hf);
    `checkh(s.vec[3:0], 4'hf);
    `checkh({s.vec[i+:4], s.vec[7:4]}, 8'hf3);
    if ($sformatf("%h %h", s.vec[2], s.vec[5:2]) != "1 f") $stop;
    force s.vec[5:2] = 4'h0;
    #1;
    `checkh(s.vec, 8'h03);
    release s.vec[4:3];
    s.vec = 8'hff;
    `checkh(s.vec, 8'hdb);
    force s.vec = 8'h5a;
    #1;
    `checkh(s.vec[i+:4], 4'h6);
    release s.vec;
    $finish;
  end
endmodule
