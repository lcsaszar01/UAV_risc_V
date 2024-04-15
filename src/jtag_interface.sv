module jtag_interface (
  input  logic tck_i,     // JTAG test clock pad
  input  logic tms_i,     // JTAG test mode select pad
  input  logic trst_ni,   // JTAG test reset pad
  input  logic td_i,      // JTAG test data input pad
  output logic td_o,      // JTAG test data output pad
  output logic tdo_oe_o,  // Data out output enable

  output logic [4:0] ir_out,      // Instruction Register Output (internal)
  input  logic [4:0] ir_in,       // Instruction Register Input (internal)
  output logic       ir_en,       // Instruction Register Enable (internal)
  output logic       capture_dr,  // Capture Data Register (internal)
  output logic       shift_dr,    // Shift Data Register (internal)
  output logic       update_dr    // Update Data Register (internal)
);

  // JTAG TAP Controller States
  enum logic [3:0] {
    RESET, IDLE, SELECT_DR, CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
    SELECT_IR, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
  } state, next_state;

  // State Transition Logic
  always_comb begin
    case (state)
      RESET      : next_state = tms_i ? RESET : IDLE;
      IDLE       : next_state = tms_i ? SELECT_DR : IDLE;
      SELECT_DR  : next_state = tms_i ? SELECT_IR : CAPTURE_DR;
      CAPTURE_DR : next_state = tms_i ? EXIT1_DR : SHIFT_DR;
      SHIFT_DR   : next_state = tms_i ? EXIT1_DR : SHIFT_DR;
      EXIT1_DR   : next_state = tms_i ? UPDATE_DR : PAUSE_DR;
      PAUSE_DR   : next_state = tms_i ? EXIT2_DR : PAUSE_DR;
      EXIT2_DR   : next_state = tms_i ? UPDATE_DR : SHIFT_DR;
      UPDATE_DR  : next_state = tms_i ? SELECT_DR : IDLE;
      SELECT_IR  : next_state = tms_i ? RESET : CAPTURE_IR;
      CAPTURE_IR : next_state = tms_i ? EXIT1_IR : SHIFT_IR;
      SHIFT_IR   : next_state = tms_i ? EXIT1_IR : SHIFT_IR;
      EXIT1_IR   : next_state = tms_i ? UPDATE_IR : PAUSE_IR;
      PAUSE_IR   : next_state = tms_i ? EXIT2_IR : PAUSE_IR;
      EXIT2_IR   : next_state = tms_i ? UPDATE_IR : SHIFT_IR;
      UPDATE_IR  : next_state = tms_i ? SELECT_DR : IDLE;
      default    : next_state = RESET;
    endcase
  end

  // State Register
  always_ff @(posedge tck_i or negedge trst_ni) begin
    if (~trst_ni)
      state <= RESET;
    else
      state <= next_state;
  end

  // Output Logic
  assign tdo_oe_o   = (state == SHIFT_IR) || (state == SHIFT_DR);
  assign ir_en      = (state == CAPTURE_IR);
  assign capture_dr = (state == CAPTURE_DR);
  assign shift_dr   = (state == SHIFT_DR);
  assign update_dr  = (state == UPDATE_DR);

  // Shift Registers
  always_ff @(posedge tck_i or negedge trst_ni) begin
    if (~trst_ni) begin
        ir_out <= 0;
        td_o <= 0;
     end
    else if (ir_en)
      ir_out <= ir_in;
    else if (shift_dr)
      td_o <= td_i;
  end

endmodule
