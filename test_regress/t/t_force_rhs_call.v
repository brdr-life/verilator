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
    logic [7:0] a;
    logic [7:0] z;
  } s_t;

  logic [7:0] arr[2];
  logic [7:0] asn[2];
  s_t s;
  logic [7:0] b;

  function automatic logic [7:0] f(logic [7:0] x);
    return x + 8'd1;
  endfunction

  initial begin
    b = 8'd1;
    force arr[1] = f(b);
    force s.a = f(b);
    assign asn[1] = f(b);
    #1;
    `checkh(arr[1], 8'd2);
    `checkh(s.a, 8'd2);
    `checkh(asn[1], 8'd2);

    // The right-hand sides are re-evaluated when their operand changes
    b = 8'd5;
    #1;
    `checkh(arr[1], 8'd6);
    `checkh(s.a, 8'd6);
    `checkh(asn[1], 8'd6);

    $write("*-* All Finished *-*\n");
    $finish;
  end

endmodule
