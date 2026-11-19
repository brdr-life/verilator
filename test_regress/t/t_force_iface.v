// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

interface intf;
  logic value;
  modport mp(output value);
endinterface

module dut (
    interface buses[1],
    intf bus,
    intf.mp busmp
);
  initial begin
    force buses[0].value = 1'b1;
    force bus.value = 1'b1;
    force busmp.value = 1'b1;
    if (buses[0].value !== 1'b1) $stop;
    if (bus.value !== 1'b1) $stop;
    if (busmp.value !== 1'b1) $stop;
    release buses[0].value;
    release bus.value;
    release busmp.value;
    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule

module t;
  intf buses[1] ();
  intf bus ();
  intf busmp ();
  dut dut (.*);
endmodule
