# simplified script to do synthesis step-by-step
# we will only use a single library and single VT type
 
# set the library path we'd like to use for the design
set LIB_PATH /escnfs/courses/sp24-cse-60762.01/public/intel16libs/std_cells

# I'm doing this explicitly, but tcl lets you glob
set seq_lib ${LIB_PATH}/seq_nom/lib/lib224_b0m_6t_108pp_seq_nom_tttt_1p000v_25c_tttt_ctyp_nldm.lib.gz
set base_lib ${LIB_PATH}/base_nom/lib/lib224_b0m_6t_108pp_base_nom_tttt_1p000v_25c_tttt_ctyp_nldm.lib.gz

# we've got a sequential and a combinational logic library to use
read_libs [list $seq_lib $base_lib]



# let's make the HDL amenable to future pnr steps
# let's get rid of some sv features 
set_db hdl_array_naming_style "%s\[%d\]"
set_db hdl_instance_array_naming_style "%s\[%d\]"
set_db remove_assigns true

# set RTL path
set RTL_PATH ../src/

# set your top module name
set DESIGN_NAME riscv_stub

# I'm reading all the system verilog files in there
foreach file [glob -nocomplain -type f $RTL_PATH/*.sv] {
	puts "Reading file: $file"
	read_hdl -sv $file
}


# need to elaborate before doing any synthesis
elaborate

# check what your errors are
# check_design -unresolved

# Set the path to the directory containing the SDC files
set CONST_PATH ./constraints

current_design [get_db designs  $DESIGN_NAME]

foreach file [glob -nocomplain -type f $CONST_PATH/*.sdc] {
	puts "Reading file: $file"
	read_sdc $file
}

# generic synthesis steps
set_db / .syn_generic_effort medium
syn_generic

# mapping steps
set_db / .syn_map_effort medium

# set things up correctly for mapping 
# cadence makes mistakes regarding clock cells and not clock cells
# so we'll make this a do-not-use during optimization

set_db [get_db lib_cells *b0mc*] .avoid false
set_db [get_db lib_cells *b0mc*] .dont_use false

syn_map

# opt steps
set_db / .syn_opt_effort medium

# set things up correctly for opt 
# cadence makes mistakes regarding clock cells and not clock cells
# so we'll make this a do-not-use during optimization

set_db [get_db lib_cells *b0mc*] .avoid true 
set_db [get_db lib_cells *b0mc*] .dont_use true

syn_opt


# write out the relevant files
write_db ${DESIGN_NAME} -to_file ${DESIGN_NAME}.db 
write_hdl > ${DESIGN_NAME}_synth.v
write_sdc > ${DESIGN_NAME}_synth.sdc 
