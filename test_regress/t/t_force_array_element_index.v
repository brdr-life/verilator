// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Reading an unpacked array at a run-time index, while some element of that
// array is forced, must work and must see the forced element when the index
// selects it (IEEE 1800-2023 10.6.2).
//
// Before the accompanying fix this failed to elaborate with an internal error,
// because the force-aware read built the flattened element index assuming every
// array select was a constant.  Only a force target has to name a constant
// element; an ordinary read may select at run time.

// verilog_format: off
`define stop $stop
`define checkh(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0x exp=%0x\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

module sub (
    input logic [3:0] idx,
    output logic [7:0] rd,
    output logic [7:0] rd2d,
    output logic [7:0] proc,
    output logic [7:0] rdns,
    output logic [7:0] rd3d,
    input logic [1:0] s0,
    input logic [1:0] s1,
    input logic [1:0] s2,
    input logic [63:0] wide,
    output logic [7:0] sweep,
    output logic [7:0] rdwide
);
  logic [7:0] mem[16];
  logic [7:0] m2[4][4];
  // Non-square, so a transposed stride or swapped dimension order is detectable.
  logic [7:0] mns[2][5];
  logic [7:0] m3[2][3][4];

  initial begin
    for (int i = 0; i < 16; ++i) mem[i] = 8'h10 + i[7:0];
    for (int i = 0; i < 4; ++i) for (int j = 0; j < 4; ++j) m2[i][j] = 8'h40 + 8'(i * 4 + j);
    for (int i = 0; i < 2; ++i) for (int j = 0; j < 5; ++j) mns[i][j] = 8'h60 + 8'(i * 5 + j);
    for (int i = 0; i < 2; ++i)
    for (int j = 0; j < 3; ++j)
    for (int k = 0; k < 4; ++k) m3[i][j][k] = 8'h80 + 8'((i * 3 + j) * 4 + k);
  end

  // Continuous read at a run-time index.
  assign rd = mem[idx];
  // Two unpacked dimensions, both indexed at run time.
  assign rd2d = m2[idx[3:2]][idx[1:0]];
  // The same run-time indexed read, procedurally.
  always_comb proc = mem[idx];
  // Non-square and 3-D, all subscripts selected at run time.
  assign rdns = mns[idx[2]][3'(idx[1:0])];
  assign rd3d = m3[idx[3]][idx[1:0]%3][idx[1:0]];
  // Every subscript driven independently, so the sweep below reaches all elements.
  assign sweep = m3[s0[0]][s1][s2];
  // A 64-bit index. V3Width truncates it to the array's index width, so this is
  // the same element a plain read selects; WIDTHTRUNC is expected and waived.
  /* verilator lint_off WIDTHTRUNC */
  assign rdwide = mem[wide];
  /* verilator lint_on WIDTHTRUNC */
endmodule

module t;
  logic [3:0] addr;
  logic [7:0] rd, rd2d, proc, rdns, rd3d, sweep, rdwide;
  logic [1:0] s0, s1, s2;
  logic [63:0] wide;

  sub u (
      .idx(addr),
      .rd(rd),
      .rd2d(rd2d),
      .proc(proc),
      .rdns(rdns),
      .rd3d(rd3d),
      .s0(s0),
      .s1(s1),
      .s2(s2),
      .wide(wide),
      .sweep(sweep),
      .rdwide(rdwide)
  );

  initial begin
    addr = 4'h6;
    #1;
    // Nothing forced yet.
    `checkh(rd, 8'h16)
    `checkh(proc, 8'h16)
    `checkh(rd2d, 8'h46)  // m2[1][2]

    force u.mem[7] = 8'haa;
    force u.m2[2][3] = 8'hbb;
    #1;
    // Index still selects an element that is not forced.
    `checkh(rd, 8'h16)
    `checkh(proc, 8'h16)
    `checkh(rd2d, 8'h46)

    addr = 4'h7;
    #1;
    // Run-time index now selects the forced element of the 1-D array.
    `checkh(rd, 8'haa)
    `checkh(proc, 8'haa)
    `checkh(rd2d, 8'h47)  // m2[1][3], not forced

    addr = 4'hb;
    #1;
    // Run-time index now selects the forced element of the 2-D array.
    `checkh(rd, 8'h1b)
    `checkh(proc, 8'h1b)
    `checkh(rd2d, 8'hbb)  // m2[2][3]

    // Non-square and 3-D reads at run-time subscripts.  A swapped stride would
    // pick a different element in each of these.
    addr = 4'h6;  // [2]=1 [1:0]=2 -> mns[1][2]; [3]=0 [1:0]%3=2 [1:0]=2 -> m3[0][2][2]
    #1;
    `checkh(rdns, 8'h67)
    `checkh(rd3d, 8'h8a)

    addr = 4'h3;  // [2]=0 [1:0]=3 -> mns[0][3]; [3]=0 [1:0]%3=0 [1:0]=3 -> m3[0][0][3]
    #1;
    `checkh(rdns, 8'h63)
    `checkh(rd3d, 8'h83)

    // A forced index must be seen by the run-time indexed read of a forced array,
    // and the continuous and procedural reads must agree.
    force u.idx = 4'h7;
    #1;
    `checkh(rd, 8'haa)
    `checkh(proc, 8'haa)

    release u.mem[7];
    force u.idx = 4'h5;
    #1;
    `checkh(rd, 8'h15)
    `checkh(proc, 8'h15)

    // Exhaustive sweep of the 3-D array against an independent model, with one
    // element forced.  Any stride or dimension-order error picks a different
    // element for some subscript triple and is caught here regardless of shape.
    force u.m3[1][2][3] = 8'hde;
    #1;
    for (int i = 0; i < 2; ++i) begin
      for (int j = 0; j < 3; ++j) begin
        for (int k = 0; k < 4; ++k) begin
          logic [7:0] want;
          s0 = 2'(i);
          s1 = 2'(j);
          s2 = 2'(k);
          want = (i == 1 && j == 2 && k == 3) ? 8'hde : 8'h80 + 8'((i * 3 + j) * 4 + k);
          #1;
          `checkh(sweep, want)
        end
      end
    end
    release u.m3[1][2][3];

    // A 64-bit index is truncated to the array's index width, forced or not.
    wide = 64'd9;
    #1;
    `checkh(rdwide, 8'h19)
    force u.mem[9] = 8'h5a;
    #1;
    `checkh(rdwide, 8'h5a)
    wide = 64'h1_0000_0009;  // truncates to 9, same element
    #1;
    `checkh(rdwide, 8'h5a)
    release u.mem[9];

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
