# Find the location of the top directory
set project_dir [file dirname [file normalize [info script]]]
set project_dir ${project_dir}/../../..

# The full part name for use when generating the project
# Custom PCB
set full_part_name xc7a50tftg256-1

# The part name that appears in the hardware manager to upload the bitstream to the FPGA
set short_part_name xc7a50t_0

cd $project_dir/workspace/vivado/scripts
set outputDir ../projectflow
file mkdir $outputDir

create_project SAR_ADC ./$outputDir -part $full_part_name -force

# Add libraries to the project - note some libraries may be pulled in as sub-libraries and thus don't need to be pulled in again

source $project_dir/lib/sv-ethernet/scripts/include_files.tcl

# Add files to the project - either the folder containing the files or the files themselves

add_files $project_dir/rtl/syn/

# Change this line if using some other constraint file
# Arty A7
#add_files -fileset constrs_1 $project_dir/rtl/constraints/Arty-A7-100-Master.xdc
# Custom PCB
add_files -fileset constrs_1 $project_dir/rtl/constraints/SAR_ADC-FTG256.xdc

#add_files -force -norecurse
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# Synthesize, implement and upload bitstream to device, uncomment to automate
# launch_runs synth_1
# wait_on_run synth_1
# 
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# puts "Implementation done!"
# set_param labtools.override_cs_server_version_check 1
# open_hw_manager
# connect_hw_server -allow_non_jtag
# open_hw_target
# set_property PROGRAM.FILE {$project_dir/workspace/vivado/projectflow/littleriscy.runs/impl_1/riscv_core.bit} [get_hw_devices $short_part_name]
# current_hw_device [get_hw_devices $short_part_name]
# refresh_hw_device -update_hw_probes false [lindex [get_hw_devices $short_part_name] 0]
# program_hw_devices [get_hw_devices $short_part_name]