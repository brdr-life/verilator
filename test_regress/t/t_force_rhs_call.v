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
  logic [7:0] c;
  int calls;
  int ia, ib, iq;

  function automatic logic [7:0] f(logic [7:0] x);
    return x + 8'd1;
  endfunction
  function automatic logic [7:0] g(logic [7:0] x);
    calls++;
    return x + 8'd1;
  endfunction
  function automatic int mix(int x);
    return (x * x) + 1;
  endfunction

  initial begin
    b = 8'd1;
    force arr[1] = f(b);
    force s.a = f(b);
    assign asn[1] = f(b);
    force s.z = f(f(b)) + f(b + 8'd1);
    // A call with side effects is made once
    force arr[0] = g(b);
    assign asn[0] = g(b);
    assign c = g(b);
    #1;
    `checkh(arr[1], 8'd2);
    `checkh(s.a, 8'd2);
    `checkh(asn[1], 8'd2);
    `checkh(s.z, 8'd6);
    `checkh(arr[0], 8'd2);
    `checkh(asn[0], 8'd2);
    `checkh(c, 8'd2);
    `checkh(calls, 3);

    // The right-hand sides are re-evaluated when their operand changes
    b = 8'd5;
    #1;
    `checkh(arr[1], 8'd6);
    `checkh(s.a, 8'd6);
    `checkh(asn[1], 8'd6);
    `checkh(s.z, 8'd14);

    // A variable forced to an expression with a call
    ia = 3;
    ib = 5;
    force iq = ib + mix(ia);
    #1;
    `checkh(iq, 15);
    ia = 4;
    #1;
    `checkh(iq, 22);
    ib = -2;
    #1;
    `checkh(iq, 15);
    release iq;
    #1;
    `checkh(iq, 15);

    $write("*-* All Finished *-*\n");
    $finish;
  end

endmodule
