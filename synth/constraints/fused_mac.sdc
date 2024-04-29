# fused_mac.sdc
  
# Define clock
create_clock -name clk -period 1000 [get_ports clk]
set_clock_uncertainty -setup 50 [get_clocks clk]
set_clock_uncertainty -hold 50 [get_clocks clk]

# Define default input/output delays
set_input_delay 1000 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1000 [all_outputs]

# Define input and output port transition times
set_input_transition 1000 [all_inputs]
set_output_delay 1000 [all_outputs]

# Set max_transition for input ports
set_max_transition 400 [all_inputs]

# Set max_transition for output ports
set_max_transition 400 [all_outputs]

# Set the default load for output ports
set_load 50 [all_outputs]
