 
 #SOURCE
 source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/NetLib.tcl
 source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocConfigLib.tcl

  proc reloc_design {args} {
 #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set checkpoint_location {}
  set interface_side {}
  set ref_cell {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			   -checkpoint { 
				set checkpoint_location [lshift args]
			  } -interface_side { 
				set interface_side [lshift args]
			  } -ref_cell { 
				set ref_cell [lshift args]
			  } -help {
			  incr help
			  }
			  default {
				if {[string match "-*" flag]} {
					puts "Error - option '$flag' is not a valid option."
					incr error
				} else {
					puts "ERROR - option '$flag' is not a valid option."
					incr error
				}
			  }
		  }
	  }
	  
	  if {$error} {
		return -code error {ERROR: }
	  }

	  if {[llength $checkpoint_location]==0} {
		return -code error {ERROR: Determine the checkpoint which has to be read for the black_boxes}
	  }
	  
	  if {[llength $interface_side]==0} {
		return -code error {ERROR: Determine a interface side for the pblocks}
	  }
	  
	  if {[lsearch -exact {LEFT RIGHT} $interface_side]==-1} {
		return -code error {ERROR: Determine a valid interface side. You can choose between LEFT and RIGHT interface side}
	  }
	  
	  if {[llength $ref_cell]==0} {
		return -code error {ERROR: Determine a reference cell for the relocation flow}
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-check_point <Checkpoint>]
						[-interface_side <LEFT/RIGHT>]
						[-ref_cell <Reference Black_Box Cell>]
						
			Description: Generates a configuration .ini file in $Project_directory/"Project_name".reloc/reloc_configuration.ini
						 
			Example:    reloc_design -checkpoint C:/Xilinx/ProjectVivado/New_ISPR/Sources/rp_sources/rp1/led_clocked_rp1.dcp -interface_side LEFT -ref_cell dsg_1_i/led_clk_3_0/U0/U0/reconfig_rpLED
			
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #---------------------------------------------------------------------------------------------------------------------- 
	##Config_Init of Setup_File
	set side $interface_side
	set rp_block $ref_cell
	
	global env	
	
	set_property CONTAIN_ROUTING TRUE [get_pblocks]
	set_property EXCLUDE_PLACEMENT TRUE [get_pblocks]	
	set_property PARTPIN_SPREADING 3 [get_pblocks]
	
	set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1}]




	
	source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
	set GLOBAL_RELOC_STATE::sourced_RelocSetup 1

	##check which fpga architecture is used by the project
	set device_part [get_property DEVICE [get_parts -of_objects [get_projects]]]
	init_plattform -part $device_part

	 ###starting initilization for isolated FLOW
	set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance $top_instance
	set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance	
	 
	set cellFiltered $instance_below_top
	 
	##Set HD.ISOLATED to draw the static partition 
	for {set x 0} {$x<[llength $cellFiltered]} {incr x} {
	set_property HD.ISOLATED 1 [get_cells [lindex $cellFiltered $x]]
	}
		##Setting Clock nets to global
	set_property HD.ISOLATED_EXEMPT true [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ CLK.gclk.* }]

    ##Draw static Partition
	set pblock_list [get_pblocks *]
	set pblock_neighbours [get_pblock_neighbours -pblocks $pblock_list]
	set static_coordinates [draw_static_region -name static]	


	set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==1 || IS_BLACK_BOX==TRUE}]
	
	##Include the netlist for black box instances 
	for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		read_checkpoint -cell [lindex $black_box_list $x] $checkpoint_location
	 }
	set RELOC_FLOW::read_cp_done 1 

	##Insert LUT Cells for fixing the interfaces and to avoid feed-through routes through nets from io-pad nets
	 place_dummy_cells -place_in STATIC
	 puts "place_static_partition_cells: PLACED"
	 ##Placing LUT1 in reconfigurable cells for later usage of fixing the interface net between static and reconfigurable partition for relocation
	 place_dummy_cells -place_in RP
	 #place_rp_in_cell_partition_cells
	  puts "place_reconfig_partition_cells: PLACED"
	 ##Placing buffer cells to avoid feedthroughs through global nets which are outgoing from input pads
	 place_buf_cells
	 puts "place_buf_cells: PLACED"
	 set RELOC_FLOW::placed_dummy_cells 1 




	##create list which cell is connected to which pblock
	set pblock_cell_assignment {}
	for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		set pblock_of_cell [get_pblocks -of_objects [get_cells [lindex $black_box_list $x]]]
		set cell_pb "[lindex $black_box_list $x] $pblock_of_cell"
		set cell_pb {}
		set cell_pb [linsert $cell_pb 0 [lindex $black_box_list $x]]
		set cell_pb [linsert $cell_pb 1 $pblock_of_cell]
		set pblock_cell_assignment [linsert $pblock_cell_assignment [llength $pblock_cell_assignment] $cell_pb]
	}
	

	
	##reassign-->after creation -->new assignment needed
	
	for {set x 0} {$x<[llength $pblock_cell_assignment]} {incr x} {
		add_cells_to_pblock [lindex [lindex $pblock_cell_assignment $x] 1] [get_cells [lindex [lindex $pblock_cell_assignment $x] 0]] -clear_locs
	}
	 
	 ####################################################### LOCK STATIC CELLS ####################################################################################################
	
	lock_static_cells -ref_cell $ref_cell -side $side -static_coordinates $static_coordinates

	 ##############################################################################################################################################################################


	set recon_instances $black_box_list
	set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance $top_instance
	set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance

	set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==True}]
	set black_box_list $recon_instances
	set all_instances $instance_below_top

	##Save position of static partition (has to be deleted for HD.RECONFIGURABLE Flow)
	set static_pblocks [get_property PBLOCK [get_cells $static_instance]]
	set grid_ranges_static [get_property GRID_RANGES [get_pblocks $static_pblocks]]

	##Delete static Partition
	delete_pblock [get_pblocks  $static_pblocks]
	 for {set x 0} {$x<[llength $instance_below_top]} {incr x} {
		set_property HD.ISOLATED 0 [get_cells [lindex $instance_below_top $x]]
	}

	
	 ##########unassign from pblock
	 set pb_assigned_top {}
	 set rp_instances_pb_assigned {}
	
	 ##assign reconfigurable instances to placed partitions 
	 for {set x 0} {$x<[llength $recon_instances]} {incr x} {
		set pb_rp_top [get_property PBLOCK [get_cell [lindex $recon_instances $x]]]
		set pb_rp_instance [get_property PBLOCK [get_cell [lindex $black_box_list [lsearch -exact $black_box_list [lindex $recon_instances $x]]]]]
		set instance_insert "[lindex $black_box_list [lsearch -exact $black_box_list [lindex $recon_instances $x]]] $pb_rp_instance"
		set insert "[lindex $recon_instances $x] $pb_rp_top"
		set pb_assigned_top [linsert $pb_assigned_top [llength $pb_assigned_top] $insert]
		set rp_instances_pb_assigned [linsert $rp_instances_pb_assigned [llength $rp_instances_pb_assigned] $instance_insert]
		remove_cells_from_pblock $pb_rp_top [get_cells [lindex $recon_instances $x]]
		add_cells_to_pblock $pb_rp_instance [get_cells [lindex $black_box_list [lsearch -exact $black_box_list [lindex $recon_instances $x]]]]
	 }
	 
	 

	 for {set x 0} {$x<[llength $black_box_list]} {incr x} {	
		set_property HD.RECONFIGURABLE 1 [get_cells [lindex $black_box_list $x]]
	}
	set_property RESET_AFTER_RECONFIG 1 [get_pblocks ]


	puts "FIRST RECONFIGURATION IMPLEMENTATION"
	 opt_design
	 place_design -directive Explore
	 route_design -directive Explore 
	  
	## get Pins of reference instance
	set locked_rp_pins [get_pins -of_objects [get_cells $ref_cell]]

	
	set partition_placement {}
	 ##Lock the inserted LUT cells which are connected via the interface net with the reference instance
	 ##Lock the interface nets of the reference instance
	 for {set x 0} {$x<[llength $locked_rp_pins]} {incr x} {
		###locking the placement of rp_cells and routing and lut bels
		set rp_net [get_nets -of_objects [get_pins [lindex $locked_rp_pins $x]]]
		if {[get_property TYPE [get_nets $rp_net]]!="GLOBAL_CLOCK" && [get_property TYPE [get_nets $rp_net]]!="LOCAL_CLOCK" && [get_property TYPE [get_nets $rp_net]]!="REGIONAL_CLOCK"} {
			set_property is_route_fixed 1 [get_nets $rp_net] -quiet
			set rp_leaf_cells [get_LeafCells -net $rp_net -direction INOUT]
			set_property is_bel_fixed 1 [get_cells $rp_leaf_cells] -quiet
			set_property is_loc_fixed 1 [get_cells $rp_leaf_cells] -quiet
			set_property DONT_TOUCH 1 [get_cells $rp_leaf_cells] 
			set_property DONT_TOUCH 1 [get_nets $rp_net]
		} else {
			set rp_leaf_cells [get_LeafCells -net $rp_net -direction INOUT]
			set_property DONT_TOUCH 1 [get_cells $rp_leaf_cells] 
			set_property DONT_TOUCH 1 [get_nets $rp_net]		
		} 
	}
	## Get the relative placement of the Partition Pins of the reference instance
	set partition_tiles_position [get_partition_pin -ref_cell $ref_cell -side $side]
	
    ## After unroute and unplace --> Creation of Hard Macros and fixed Positions of inserted LUT Cells which are connected via interface nets with the reference instance
	##							 --> fixed interface nets of the reference instance							
	route_design -unroute
	place_design -unplace

	 ################################################################## SAVE PARTPIN POSITION #################################################################################
	 
	
	 ##########################################################################################################################################################################

	  for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		set_property HD.RECONFIGURABLE 0 [get_cells [lindex $black_box_list $x]]
	}
	set_property RESET_AFTER_RECONFIG 0 [get_pblocks ]

	 ############################################################# COPY BEL, BEL_PIN, FIXED_ROUTE, CELL POSITION TO OTHER RP INSTANCES #########################################
	copy_lock_static_cells -ref_cell $ref_cell -static_coordinates $static_coordinates -side $side
	
	copy_lock_rp_cells -ref_cell $ref_cell -side $side
	 
	copy_lock_interface_nets -ref_cell $ref_cell
	 
	 ######################################################################################################################################################################### 
	 
	  #################partition_pin placement for rest rp instances
	set rp_instances [get_cells -hierarchical * -filter {BLACK_BOX==1}]
	for {set x 0} {$x<[llength $rp_instances]} {incr x} {
		set rp_pins [get_pins -of_objects [get_cells [lindex $rp_instances $x]]]
		set rp_coor [get_rect -pblocks [get_property PBLOCK [get_cells [lindex $rp_instances $x]]] -exact]

		for {set y 0} {$y<[llength $partition_tiles_position]} {incr y} {
			for {set z 0} {$z<[llength $rp_pins]} {incr z} {
				if {[StringPart_Compare [lindex $rp_pins $z] [lindex [lindex $partition_tiles_position $y] 0]]==1} {
					#if {[get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $z]]]]!="GLOBAL_CLOCK" && [get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $z]]]]!="LOCAL_CLOCK" && [get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $z]]]]!="REGIONAL_CLOCK"} {
					if {$side=="LEFT"} {
						set filter_expr "ROW==[expr {[lindex [lindex $rp_coor 0] 2] - [lindex [lindex $partition_tiles_position $y] 2]}] && COLUMN==[expr {[lindex [lindex $rp_coor 0] 1] + [lindex [lindex $partition_tiles_position $y] 1]}]"
					} else {
						set filter_expr "ROW==[expr {[lindex [lindex $rp_coor 0] 2] - [lindex [lindex $partition_tiles_position $y] 2]}] && COLUMN==[expr {[lindex [lindex $rp_coor 0] 3] - [lindex [lindex $partition_tiles_position $y] 1]}]"
					}
					set part_pin_tile [get_tiles -filter $filter_expr]
					set_property HD.PARTPIN_LOCS $part_pin_tile [get_pins [lindex $rp_pins $z]]
					#}
				}
			}
		}
	} 
	 ############################################################# Locking cells of inserted LUT cells associated with ibuf cells to transform a gloabl net into a local net #########################################
	 set Input_Buffer_Cells [get_cells -filter {PRIMITIVE_GROUP==IO && REF_NAME==IBUF} -quiet]
	 if {[llength $Input_Buffer_Cells]!=0} {
		locking_buf_glob_cells
		} 

	 #########################################################################################################################################################################
	 
	 #########refresh pblock_assignment--> highest instances have to refer to partition in the floorplan during HD.ISOLATED FLOW
	 ##########unassign from pblock
	 set pb_assigned_top {}
	 set rp_instances_pb_assigned {}
	 
	 for {set x 0} {$x<[llength $recon_instances]} {incr x} {
		set pb_rp_top [get_property PBLOCK [get_cell [lindex $recon_instances $x]]]
		set pb_rp_instance [get_property PBLOCK [get_cell [lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]]]]
		set instance_insert "[lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]] $pb_rp_instance"
		set insert "[lindex $recon_instances $x] $pb_rp_top"
		set pb_assigned_top [linsert $pb_assigned_top [llength $pb_assigned_top] $insert]
		set rp_instances_pb_assigned [linsert $rp_instances_pb_assigned [llength $rp_instances_pb_assigned] $instance_insert]
		remove_cells_from_pblock $pb_rp_instance [get_cells [lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]]]
	 }
	## Do not consider Violations of IO-Pad Placement of the processing system while HD.ISOLATED FLOW
	set_property SEVERITY {Warning} [get_drc_checks HDIS-18] 

	 ###create static partition again for HD.ISOLATED FLOW
	 create_pblock static
	 resize_pblock static -add $grid_ranges_static
	 add_cells_to_pblock static [get_cells $static_instance]
	 
	 ##reassign reconfigurable instances to partition (highest instance of reconfigurable instances)
	  for {set x 0} {$x<[llength $recon_instances]} {incr x} {
		add_cells_to_pblock [lindex [lindex $pb_assigned_top $x] 1] [get_cells [lindex [lindex $pb_assigned_top $x] 0]]
		puts "add_cells_to_pblock [lindex [lindex $pb_assigned_top $x] 1] [get_cells [lindex [lindex $pb_assigned_top $x] 0]]"
	 }
	 
	  for {set x 0} {$x<[llength $instance_below_top]} {incr x} {
		set_property HD.ISOLATED 1 [get_cells [lindex $instance_below_top $x]]
	}
	
	 ###place and route HD.ISOLATED DESIGN for getting static routing
	 
	 puts "ISOLATION IMPLEMENTATION"
	 
	 #opt_design
	 place_design   
	 route_design -preserve  
	 
	 set static_pblocks [get_property PBLOCK [get_cells $static_instance]]
	 
	 delete_pblock [get_pblocks  $static_pblocks]
	 
	 ####################################################################
	 ##########   Clock_fixing auskommentiert #############################
	 #################   10-03-2016   ########################################
	 
	 ##Clock fixing neu hier
	## set available_clk_pins [get_clk_pins -ref_cell $ref_cell] 
	
	##if {$available_clk_pins==1} {
		##set clk_line_nodes [get_rp_clk_nodes -ref_cell $ref_cell]
	##}
	
	 ##set clk_net [get_nets -hierarchical -filter {TYPE==GLOBAL_CLOCK}]
	 ##set_property IS_ROUTE_FIXED 0 [get_nets [lindex $clk_net 0]]
	 ##set_property IS_ROUTE_FIXED 0 [get_nets [lindex $clk_net 0]]
	 ##route_design -unroute -net [get_nets $clk_net]	 
	 # ###Now locking routing static and change into RP-Design flow
	 ##fixing net of clk partition pins
	##if {$available_clk_pins==1} {
		##fix_clk_partpin_route -clk_nodes $clk_line_nodes
	##}
	 
	 lock_design -level routing -quiet
	 

	 
	 
	 
	  for {set x 0} {$x<[llength $instance_below_top]} {incr x} {
		set_property HD.ISOLATED 0 [get_cells [lindex $instance_below_top $x]]
	}
	
	 #set_property DONT_TOUCH TRUE [get_cells -hierarchical]
	 #set_property DONT_TOUCH TRUE [get_nets  -hierarchical -filter]
	 ##########unassign from pblock
	 set pb_assigned_top {}
	 set rp_instances_pb_assigned {}
	 ##reassign highest reconfigurable instances from partition, and assign the reconfigurable instances in order of HD.RECONFIGURABLE FLOW
	 for {set x 0} {$x<[llength $recon_instances]} {incr x} {
		set pb_rp_top [get_property PBLOCK [get_cell [lindex $recon_instances $x]]]
		set pb_rp_instance [get_property PBLOCK [get_cell [lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]]]]
		set instance_insert "[lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]] $pb_rp_instance"
		set insert "[lindex $recon_instances $x] $pb_rp_top"
		set pb_assigned_top [linsert $pb_assigned_top [llength $pb_assigned_top] $insert]
		set rp_instances_pb_assigned [linsert $rp_instances_pb_assigned [llength $rp_instances_pb_assigned] $instance_insert]
		remove_cells_from_pblock $pb_rp_top [get_cells [lindex $recon_instances $x]]
		add_cells_to_pblock $pb_rp_instance [get_cells [lindex $black_box_list [search_String $black_box_list [lindex $recon_instances $x] 0]]]
	 }
	 
	 
	 for {set x 0} {$x<[llength $black_box_list]} {incr x} {	
		set_property HD.RECONFIGURABLE 1 [get_cells [lindex $black_box_list $x]]
	}
	set_property RESET_AFTER_RECONFIG 1 [get_pblocks ]
		 puts "LAST RECONFIGURATION IMPLEMENTATION"
	 #opt_design
	 place_design
	 route_design -preserve 
	 lock_design -unlock -level routing
	 ####Now making ready for Reconfiguration use
	 
	 #lock_design -level routing -unlock
	 
	 for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		update_design -cell [lindex $black_box_list $x] -black_box -quiet
	 }	 

	 lock_design -level routing
	 		
			
	set_property CONTAIN_ROUTING TRUE [get_pblocks]
	set_property EXCLUDE_PLACEMENT TRUE [get_pblocks]
	
	set_property POST_CRC DISABLE [current_design]
	set_property BITSTREAM.GENERAL.CRC DISABLE [get_designs]
	
	 #Reset static variables 
	 set RELOC_FLOW::read_cp_done 0 
	 set RELOC_FLOW::placed_dummy_cells 0
 }