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
    st_t big[32768][32768];
    force big[0][0].y = 8'h40;
    $finish;
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
