// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 BRDR LIFE
// SPDX-License-Identifier: CC0-1.0

module t;
  class Cls;
    static int s_stat;
    int m_prop;
    task tsk;
      force m_prop = 1;  // <---- BAD class property
    endtask
  endclass

  Cls c;
  int assoc[int];
  int dyn[];
  int q[$];

  task automatic tsk(input int port);
    int autov;
    force autov = 1;  // <---- BAD automatic variable
    force port = 1;  // Not checked, as every task port is marked automatic
  endtask

  initial begin
    force Cls::s_stat = 1;  // ok
    release Cls::s_stat;  // ok

    // IEEE 1800-2023 6.21 automatic variables, elements of dynamically sized
    // arrays, and non-static class properties shall not be written with
    // procedural continuous assignments.
    force c.m_prop = 1;  // <---- BAD class property
    release c.m_prop;  // <---- BAD class property
    force assoc[0] = 1;  // <---- BAD associative array element
    force dyn[0] = 1;  // <---- BAD dynamic array element
    force q[0] = 1;  // <---- BAD queue element
    release q[0];  // <---- BAD queue element
  end

endmodule
