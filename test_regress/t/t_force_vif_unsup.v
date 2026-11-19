// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

interface intf;
  logic value;
  logic [7:0] data;
endinterface

module t;
  intf i0 ();
  intf i1 ();
  virtual intf vif = i0;
  virtual intf vif2;

  initial begin
    force vif.value = 1'b1;
    release vif.value;
    vif2 = i1;
    force vif2.data = 8'haa;
    release vif2.data;
  end
endmodule
