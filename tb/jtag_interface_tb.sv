module jtag_interface_tb;

  // Simulation parameters
  parameter TOGGLE = 10; // Clock toggle rate
  parameter TICK = 10;   // One simulation step
  parameter TIMEOUT = 1000; // End of simulation

  // JTAG interface signals
  logic tck_i;
  logic tms_i;
  logic trst_ni;
  logic td_i;
  logic td_o;
  logic tdo_oe_o;
  logic [4:0] ir_out;
  logic [4:0] ir_in;
  logic ir_en;
  logic capture_dr;
  logic shift_dr;
  logic update_dr;

  // Instantiate the JTAG interface module
  jtag_interface dut (
    .tck_i(tck_i),
    .tms_i(tms_i),
    .trst_ni(trst_ni),
    .td_i(td_i),
    .td_o(td_o),
    .tdo_oe_o(tdo_oe_o),
    .ir_out(ir_out),
    .ir_in(ir_in),
    .ir_en(ir_en),
    .capture_dr(capture_dr),
    .shift_dr(shift_dr),
    .update_dr(update_dr)
  );

  // Clock generation
  always begin
    #(TOGGLE) tck_i = ~tck_i;
end


  // Test stimulus
  initial begin
    tck_i = 0;

    // Initialize inputs
    tms_i = 0;
    td_i = 0;
    ir_in = 5'b00000;

    // Apply reset
    trst_ni = 0;
    $display("state before assert: %b", dut.state);
    assert(dut.state == dut.RESET) else $error("JTAG TAP not in RESET state after reset");
    #(TICK);
    #(TICK);
    trst_ni = 1;
    #(TICK);
    assert(dut.state == dut.IDLE) else $error("JTAG TAP not in IDLE state after TMS=0");

    // Test case 1: Shifting data into the Data Register
    #(TICK) tms_i = 1; // Select DR
    #(TICK) tms_i = 0; // Capture DR
    assert(capture_dr == 1) else $error("Capture DR signal not asserted");
    #(TICK) tms_i = 0; // Shift DR
    assert(shift_dr == 1) else $error("Shift DR signal not asserted");
    for (int i = 0; i < 8; i++) begin
      td_i = i[0];
      #(TICK);
    end
    #(TICK) tms_i = 1; // Exit1 DR
    #(TICK) tms_i = 1; // Update DR
    assert(update_dr == 1) else $error("Update DR signal not asserted");
    #(TICK) tms_i = 0; // Run Test/Idle

    // Test case 2: Shifting data into the Instruction Register
    #(TICK) tms_i = 1; // Select DR
    #(TICK) tms_i = 1; // Select IR
    #(TICK) tms_i = 0; // Capture IR
    assert(ir_en == 1) else $error("IR enable signal not asserted");
    #(TICK) tms_i = 0; // Shift IR
    for (int i = 0; i < 5; i++) begin
      td_i = i[0];
      #(TICK);
    end
    #(TICK) tms_i = 1; // Exit1 IR
    #(TICK) tms_i = 1; // Update IR
    assert(ir_out == ir_in) else $error("IR output does not match IR input");
    #(TICK) tms_i = 0; // Run Test/Idle

    // Add more test cases and assertions as needed

    #(TIMEOUT);
    $finish;
  end

  // Monitoring and assertions
  always @(posedge tck_i) begin
    $display("Time: %0t, STATE: %b, TMS: %b, TDI: %b, TDO: %b, IR_OUT: %b",
             $time, dut.state, tms_i, td_i, td_o, ir_out);
    
    // Assert that TDO is driven only during Shift-DR and Shift-IR states
    assert(tdo_oe_o == ((dut.state == dut.SHIFT_DR) || (dut.state == dut.SHIFT_IR)))
      else $error("TDO output enable signal not asserted correctly");
  end

endmodule
