// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

interface intf;
  logic value;
endinterface

module t;
  intf i0 ();
  virtual intf vif = i0;

  initial begin
    force vif.value = 1'b1;
    release vif.value;
  end
endmodule
