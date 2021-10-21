	#SOURCE
	#source %APPDATA%/RELCO_TCL/StringLib.tcl
	source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/FpgaHardwareLib.tcl


	##looks only if clk pins are there
proc get_clk_pins {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set cell {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set cell [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <rp_Cell>]
						
			Description: This procedure gets the nodes of fixed clk_line on the used clock line horizontaly and the node of the bufg cell.
						 This function is only used when only one cell is contacted in the rp region to the clk net
						 
			Example:    get_clk_pins -ref_cell mb_st_i/mb_0_1/U0/rc_i
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------

	 set all_nets [get_nets -of_objects [get_pins -of_objects [get_cells $cell]]]
	 set net_type [get_property TYPE [get_nets $all_nets]]
	 set clk_type [lsearch -all -regexp $net_type .*CLOCK]
	 
	 if {[llength $clk_type]!=0} {
		return 1
	 } else {
		return 0
	 }	 
}	
	
proc get_BusNet { args } {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set bus {}
  set bus_nr 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -bus { 
				set bus [lshift args]
			  }
			  -bus_nr {
				set bus_nr [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-bus <Net>]
						[-bus_nr <N/-1>]
						
			Description: Get a single Net from a bus net. If bus_nr is -1 the whole Name of the bus will be returned.
						 
			Example:    get_BusNet -net cl_i/ex/U0/reg_in[0] -bus_nr 1
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------	  
	set prop_name [get_property BUS_NAME  [get_nets [expr {$bus}]]]
	set bus_name $prop_name
	##set length [string length [expr {$bus}]]
	set bus_index_start [string last / [expr {$bus}] [string length [expr {$bus}]]
	set bus_width [get_property BUS_START [get_nets $bus]]
	
	if {$bus_nr>$bus_width} {
		return -code error {Bus Number bus_nr $bus_nr is not legal}
	}
		 
	if {$bus_nr != -1} {
		set busnet_back [string replace $bus [expr {$bus_index_start+1}] $length "$bus_name[$bus_nr]"]
	} else {
		set busnet_back [string replace $bus [expr {$bus_index_start+1}] $length "$bus_name"]		
	}
	
	#puts $busnet_back
	
	return $busnet_back	
}

	###################################################LEAF Cells an einem Netz erhalten und wählen zwischen in und out
proc get_LeafCells { args } {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set net {}
  set direction {}
  set help 0
  set error 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -net { 
				set net [lshift args]
			  }
			  -direction {
				set direction [lshift args]
			  }
			  -help {
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
	
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <Net>]
						[-direction <IN/OUT/INOUT>]
						
			Description: Get the connected leaf Cells of a net in specified direction. 
						 Direction are In and OUT. To get leaf Cells in both directions you have write INOUT.
						 Returns a list of connected leaf Cells
						 
			
			Example:    get_LeafCells -net cl_i/ex/U0/reg_in[0] -direction IN
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  	if {$error} {
		return -code error {ERROR: }
	  }
  
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------	
	if {$direction=="IN"} {
		set ftr_direction DIRECTION==IN	
	} elseif {$direction=="OUT"} {
	    set ftr_direction DIRECTION==OUT	
	} elseif {$direction=="INOUT"} {
		set ftr_direction "DIRECTION==IN || DIRECTION==OUT"
	} else {
		return -code error {In get_LeafCells Proc: No valid direction $direction}
	}
	
	set leaf_cell_list [get_cells -of_objects [get_pins -of_objects [get_nets $net] -leaf -filter $ftr_direction]]
	
	return $leaf_cell_list
}

	###########################Delete Nets which are not connected to any pins or loads	
proc Remove_Unconnected_Nets { args } {	

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -instance { 
				set instance [lshift args]
				}
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-instance <Instance>]
					
			Description: Removes all Nets under the denoted Instance
			
			Example:    Remove_Unconnected_Nets -instance cl_i/test
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
  
	  if {$error} {
		return -code error {ERROR: }
	  }  
	  
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	set unconnected_nets [get_nets -hierarchical -regexp .*$instance.* -filter {ROUTE_STATUS==NOLOADS && PIN_COUNT==0 && FLAT_PIN_COUNT==0 && DRIVER_COUNT==0}]
	
	if {[llength $unconnected_nets]==0} {
		#puts "No unconnected nets"
		return -code ok {"No unconnected nets"}
	}
	
	while {[llength $unconnected_nets]!=0} {
			set bus_net [get_nets [lindex $unconnected_nets 0]]
			###################################herausfinden, ob alle netze des buses no loads haben
			set bus_start [get_property BUS_STOP  [get_nets $bus_net]]
			set bus_end   [get_property BUS_START [get_nets $bus_net]]
			set nr_loads 0
			
			if {[get_property BUS_WIDTH [get_nets $bus_net]]!=" "} {	
			    set bus_end   [expr {$bus_end + 1}]	
				for {set y $bus_start} {$y<$bus_end} {incr y} {
				 set bus [get_BusNet -net $bus_net -bus_nr $y]
				 
					if {[get_property ROUTE_STATUS [get_nets $bus]]=="NOLOADS" && [get_property DRIVER_COUNT [get_nets $bus]]t==0 && [get_property PIN_COUNT [get_nets $bus]]==0 && [get_property FLAT_PIN_COUNT [get_nets $bus]]==0} {
						set nr_loads [expr {$nr_loads + 1}]
					}
					puts "NR_LOADS: $nr_loads AND NR_OF_BUSES:$bus_count"
					if {$nr_loads==$bus_count} {
						set bus_nr [get_BusNet -net $bus_net -bus_nr -1]
						remove_net $bus_nr
						puts "REMOVED: $bus_nr"
					}
				}
			} else {
			remove_net $bus_net			
			}
			set unconnected_nets [get_nets -hierarchical -regexp .*$instance.* -filter {ROUTE_STATUS==NOLOADS && PIN_COUNT==0 && FLAT_PIN_COUNT==0 && DRIVER_COUNT==0} -quiet]
	}
	
	return -code ok {}
}
 ####################################### schauen ob alle Busleitung keine Verbindung-->dann Verbindung auflösen andernfalls geht es nicht
proc disconnect_remove_net { args } {
	set net {}
	set prune 0
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -net { 
				set net [lshift args]
				}
			  -prune {
			  incr prune
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <Net>]
						[-prune]

						
			Description: Removes the denoted nets and whole buses and the connection pins and prots on the cells, when -prune is used
			
			Example:    disconnect_remove_net -net cl_i/x/reg_in[0]
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
  
	  if {$error} {
		return -code error {ERROR: }
	  }  

	   if {$prune} {
		 set prune -prune
	  } else {
		 set prune {}
	  }
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------	 
	set bus_count [get_property BUS_WIDTH [get_nets $net]]
	set bus_start [get_property BUS_STOP  [get_nets $net]]
	set bus_end   [get_property BUS_START [get_nets $net]]
	set nr_loads 0
	
	puts "bus_count: $bus_count"
	puts "bus_start: $bus_start"
	puts "bus_end: $bus_end"
	
	
	
	if {[llength $bus_count]==0} {
	##############delete when only one net
	disconnect_net $prune  -net $net -objects [get_pins -of_objects [get_nets $net]]
	remove_net $prune $net
	} else {
			set bus_end   [expr {$bus_end + 1}]	
	###########################when net is a bus-->check if some part of bus is connected
			set bus_name [get_property BUS_NAME [get_nets $net]]
			for {set x $bus_start} {$x<$bus_end} {incr x} {
				set bus [get_BusNet -net $net -bus_nr $x]
				disconnect_net $prune  -net $bus -objects [get_pins -of_objects [get_nets $bus]]				
			}	
			set bus_nr [get_BusNet -net $bus -bus_nr -1]
			remove_net $prune $bus_nr
		}
		
	return -code ok {}
}

 
 proc get_InstancePin { args } {
 	set boundary_type {}
	set net {}
	set error 0
	set help 0
	
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -boundary_type { 
				set boundary_type [lshift args]
				}
			  -net {
			    set net [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <Net>]
						[-boundary_type <upper/lower>]

						
			Description: Get the upper pin or the lower pin of a net depending on the -boundary_type option
			
			Example:    get_InstancePin -net cl_i/led/reg_in[0] -boundary_type upper
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
	  
	  if {$error} {
		return -code error {ERROR: }
	  }  
	  
	  if {[llength $net]==0} {
		return -code error {Declaration of -net is missing}
		incr error
	  }
	  if {[llength $boundary_type]==0} {
		return -code error {Declaration of -boundary_type is missing}
		incr error
	  } else {
		if {$boundary_type!="upper" && $boundary_type!="lower"} {
			incr error
		} 
	  }
	  
	  if {$error} {
		return -code error {Wrong inputs for -boundary_type}
	  }
	  
	  

	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 
	 
	 ################################################################herausfinden was die kleinste Instantzlänge ist
	set all_con_pins [get_pins -of_objects [get_nets $net]] 
	set min_depth [InstanceDepth [lindex $all_con_pins 0]]
	set min_instance [lindex $all_con_pins 0]

	for {set x 0} {$x<[llength $all_con_pins]} {incr x} {			
		set old_min_depth $min_depth
		set min_depth [min_value $min_depth [InstanceDepth [lindex $all_con_pins $x]]]
					
		if {$min_depth!=$old_min_depth && $min_depth<$old_min_depth} {
			set min_instance [lindex $all_con_pins $x]						
		}
	}
	 ##puts "min_instance: $min_instance"
	 ##puts "min_depth: $min_depth"
	
	
	
	################################################################listen generieren mit kleinsten Instanzen und größten
	set upper_depth 0
	set upper_pin_list {}
	set lower_pin_list $all_con_pins
	
		for {set x 0} {$x<[llength $all_con_pins]} {incr x} {
		
			set upper_depth [InstanceDepth [lindex $all_con_pins $x]]	
			
			if {$upper_depth==$min_depth} {
				set upper_pin_list [linsert  $upper_pin_list 1 [lindex $all_con_pins $x]]
				set lower_pin_list [lremove $lower_pin_list [lindex $all_con_pins $x]]
			}
		}
		
	##puts "upper_pin_list: $upper_pin_list"
	##puts "lower_pin_list: $lower_pin_list"
	
	
	if {$boundary_type=="lower"} {
		return [join $lower_pin_list]
	} else {
		return [join $upper_pin_list]
	} 
	  
 }
 
proc get_top_cell {args} {
	set object {}
	set error 0
	set help 0
	
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -object { 
				set object [lshift args]
				}
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-object <cell, pin, net>]						
			Description: Get the top cell of a net or a cell or pin
			
			Example:    get_parent_cell -object mb_st_i/static_part_mb2_0/reset1 mb_st_i/static_part_mb2_0/reset2 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
	  
	  if {$error} {
		return -code error {ERROR: }
	  }  
	  
	  if {[llength $object]==0} {
		return -code error {Declaration of -net is missing}
		incr error
	  }

	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 
	 set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance $top_instance
	set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
	set cellFiltered $instance_below_top
	current_instance
	
	set found_cell {}
	
	for {set x 0} {$x<[llength $cellFiltered]} {incr x} {
		if {[lsearch -regexp $object [lindex $cellFiltered $x].*]!=-1} {
			set found_cell [lindex $cellFiltered $x]
		}
	}
	
	if {[llength $found_cell]==0} {
		return -code error {get_top_cell: NO CELL MATCHED}
	} else {
		return $found_cell
	}
	
}
 
proc get_top_net {args} {
 	set net {}
	set created_net {}
	set instance {}
	set error 0
	set help 0
	
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -instance { 
				set instance [lshift args]
				}
			  -net {
			    set net [lshift args]
			  }
			  -created_net {
			    set created_net [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <Net>]
						[-instance <cell>]
						[-created_net <part net name>] [optional]

						
			Description: Get the upper net of the instance assigned under -instance option of the net which is assigned under -net. Searching for top ALIAS of net -net under -instance. 
			
			Example:    get_top_net -net cl_i/led/reg_in[0] -instance mb_st_i/static_part_mb2_0
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
	  
	  if {$error} {
		return -code error {ERROR: }
	  }  
	  
	  if {[llength $net]==0} {
		return -code error {Declaration of -net is missing}
		incr error
	  }
	  if {[llength $instance]==0} {
		return -code error {Declaration of -instance is missing}
		incr error
	  }
	  
	  if {$error} {
		return -code error {Wrong inputs for -boundary_type}
	  }
	  
	  

	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------	
	set end 0
	set parent_net {}
#	puts "INSTANCE: $instance"
#	puts "net: $net"
	set net_segments [get_nets -segments $net]
	set idx_inst_fnd [lsearch -all -regexp $net_segments $instance.*]

	set highest_inst {}
	
	##get nets of highest instance, which are connected between each instance
	for {set x 0} {$x<[llength $idx_inst_fnd]} {incr x} {
		puts "[lindex $net_segments [lindex $idx_inst_fnd $x]]" 
		puts "[lsearch -regexp [lindex $net_segments [lindex $idx_inst_fnd $x]] .*$created_net.*]"
		if {[llength [split [lindex $net_segments [lindex $idx_inst_fnd $x]] /]]==3 && [lsearch -regexp [lindex $net_segments [lindex $idx_inst_fnd $x]] .*$created_net.*]==-1} {
			set first_inst_length [llength [split [lindex $net_segments [lindex $idx_inst_fnd $x]] /]]
			set highest_inst [lindex $net_segments [lindex $idx_inst_fnd $x]]
		}
	}
	set parent_net $highest_inst
	
	
	if {[llength $parent_net]!=0} {
		return [join $parent_net]
	} else {
		return -code error {"NO PARENT_NET FOUND"}
	}
}
  #################### DEFINITION: puts_LeafCell -net -cell -cell_name -cell_pin_in -cell_pin_out
  #-----------------------------------------darauf achten in welche richtung das netz verläuft------> netz startet immer von Ausgangszelle, je nachdem in_pins und out_pins vertauschen für korrekte Verdrahtung
  #--------------------------als -net nur das parent Net angeben
  proc puts_LeafCell { args } {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set net {}
  set cell {}
  set cell_name {}
  set cell_pin_in {}
  set cell_pin_out {}
  set cell_inst_pin {}
  set error 0
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -net { 
				set net [lshift args]
			  }
			  -cell {
				set cell [lshift args]
			  }
			  -cell_name {
				set cell_name [lshift args]
			  }
			  -cell_pin_in {
				set cell_pin_in [lshift args]
			  }
			  -cell_pin_out {
				set cell_pin_out [lshift args]
			  } 
			  -cell_instance_pin {
				set cell_inst_pin [lshift args]
			  } 
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <Net>]
						[-cell <Cell>]
						[-cell_name <Name>]
						[-cell_pin_in <PinInofCell>]
						[-cell_pin_out <PinOutofCell>]
						
			Description: The puts_LeafCell procedure puts a LeafCell on the position of the denoted net. 
						 This function disconnects the denoted net and puts a Cell between the disconnected nodes. 
						 After disconnecting, the Cell will be connected to the before disconnected nodes. 
						 You have to be aware of the usage of cell_pin_in and cell_pin_out option. It is direction 
						 dependend on the denoted net.
			
			Example:    puts_LeafCell -net cl_i/bl/U0/reg_in[0] -cell LUT1 -cell_name TEST1 -cell_pin_in I0 -cell_pin_out O -cell_instance_pin reset1
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }
  
	  if {$error} {
		return -code error {ERROR: }
	  }  
	  
	  if {[llength $cell_pin_in]==0 || [llength $cell_pin_out]==0} {
		return -code error {Declaration of -cell_pin_in and -cell_pin_out is missing}
	  }
	  if {[llength $net]==0 || [llength $cell]==0 || [llength $cell_name]==0} {
		return -code error {Declaration of -net or -cell or -cell_name is missing}
	  }
	  
	  if {[llength $cell_inst_pin]==0} {
		return -code error {No cell_instance_pin is declared}
	  }

	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
 			
		puts "CELL_NAME: $cell_name"

		###########################Verbindung zur niedrigeren Instanz auflösen
		
		##set instance pin 
		set new_pin_list $cell_inst_pin
				
		##get the direction of the instance 		
		set direction_leafCell [get_property DIRECTION [get_pins $new_pin_list]]	
		
		##How to place the cell in between the net, determined by the direction of the instance pin 
		if {$direction_leafCell=="IN"} {
			set cell_pin_in0 $cell_pin_out
			set cell_pin_out0 $cell_pin_in
		} else {
			set cell_pin_in0 $cell_pin_in
			set cell_pin_out0 $cell_pin_out		
		}			
		
		##decide in which instance the cell has to be placed
		set instance_depth [InstanceDepth $net]
		set new_instance_Path [InstancePath $net [expr {$instance_depth - 1}]]
		
		##create instance name
		if {$instance_depth==0} {
		 set LeafCell_Name "$cell_name"				
		 set LeafNet_Name "net_[expr {$cell_name}]"			 
		} else {
		 set LeafCell_Name "[expr {$new_instance_Path}]/$cell_name"	
		 set LeafNet_Name "[expr {$new_instance_Path}]/net_[expr {$cell_name}]"			 
		}
		
		create_cell -reference $cell $LeafCell_Name
		
		
		set actual_pins [get_property REF_PIN_NAME [get_pins -of_objects [get_cells $LeafCell_Name]]]
	
		if {[lsearch $actual_pins $cell_pin_in]==-1 || [lsearch $actual_pins $cell_pin_out]==-1} {
			remove_cell [get_cells $LeafCell_Name]
			return -code error {Wrong -cell_pin_in or -cell_pin_out PINS are passed to procedure puts_LeafCell}
		}

		
		##disconnect old net from instance pin
		disconnect_net  -net $net -objects $new_pin_list
		
		set_property DONT_TOUCH 1 [get_cells $LeafCell_Name]
		
		##create new net
		create_net $LeafNet_Name
		

			##erstmal neue Verbindung von unterer Instanz zu der neuen Zelle schaffen
			
		##connect old net to pin of created cell (Input/Output)
		set direction "REF_PIN_NAME==[expr {$cell_pin_in0}]"
		set in_pin_list [get_pins -of_objects [get_cells $LeafCell_Name] -filter $direction]
		connect_net -net $net -objects $in_pin_list
			
			
		##connect created net to pin of created cell (Output/Input)
		set direction "REF_PIN_NAME==[expr {$cell_pin_out0}]"	
		set out_pin_list  [linsert $new_pin_list 1 [get_pins -of_objects [get_cells $LeafCell_Name] -filter $direction]]
		connect_net -net $LeafNet_Name -objects $out_pin_list
					
		return $LeafCell_Name
		
  }
  
proc lock_static_cells {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set side {}
 set static_coordinates {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }
			  -side { 
				set side [lshift args]
			  }	
			  -static_coordinates { 
				set static_coordinates [lshift args]
			  }				  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]
						[-side <LEFT/RIGHT>]
						[-static_coordinates <static_coordinates>]
						
			Description: Locks the cells of the static region at the side choosed by user through option -side.
						 At this point only option LEFT or RIGHT position is existing for this procedure. This procedure needs the
						 static_coordinates as argument, so a right placement could be done.
			 
			Example:    lock_static_cells -ref_cell $ref_cell -side LEFT -static_coordinates $static_coordinates
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------


	set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1}]
	set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==1 || IS_BLACK_BOX==TRUE}]
	set rp_pins [get_pins -of_objects [get_cells $ref_cell]]
	set used_pblock [get_property PBLOCK [get_cells $ref_cell]]

	set actual_static_coordinates [lindex $static_coordinates [search_part_list $static_coordinates $used_pblock]]

	##get coordinate of fence position beside the reference partition
	set start_value [lindex $actual_static_coordinates [expr {[search_part_list $actual_static_coordinates $side] + 1}]]
	##search for next clb column; returns x value of found clb column and the slices in this column
	set slices_last_row [get_slices -pblock $used_pblock -side $side -start $start_value -return_all]
	
	##determine in which column to place the static cells connected to the reference cell via interface nets
	set slices [lindex $slices_last_row 0]
	set last_value [lindex $slices_last_row 1] 

	set mid_slice [expr {[llength $slices]/2}] 
	set coor_pblock [join [get_rect -pblocks $used_pblock -exact]]
	set row_search  [lindex $coor_pblock 2]
	

	set cnt 0
	set lut_cnt 0
	set chosen_slice 0
	set clock_cnt 0
	
	##choose direction to search the next clb column
	if {$side=="LEFT"} {
		set new_start_val -1
	} else {
		set new_start_val 1	
	}
	##new
	set clb_column_cnt 1
	set lut_slice [llength $GLOBAL_PBLOCK::slice_lut]
	
	
	for {set x 0} {$x<[llength $rp_pins]} {incr x} {
		puts "-------------------------------------------------------PIN: [lindex $rp_pins $x]"
		set net_type [get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $x]]]]
		if {$net_type!="GLOBAL_CLOCK" && $net_type!="LOCAL_CLOCK" && $net_type!="REGIONAL_CLOCK"} {
			puts "x: $x"
			set multiple_x [expr {round (double ($x/([llength $slices]*$lut_slice)))}]
			puts "mult_x: $multiple_x"
			puts "if {$x>=[expr {($multiple_x*$lut_slice*[llength $slices])-1}] && $multiple_x!=0 && [expr {$x-($multiple_x*$lut_slice*[llength $slices])+1}]==1}"
			##search for next clb 
			if {$x>=[expr {($multiple_x*$lut_slice*[llength $slices])-1}] && $multiple_x!=0 && [expr {$x-($multiple_x*$lut_slice*[llength $lut_slices])+1}]==1} {
				set start_value [expr {$last_value + $new_start_val}]
				set slices_last_row [get_slices -side $side -start $start_value -return_all -search_in_row $row_search]
				set filter_expr "ROW<=[lindex $coor_pblock 2] && ROW>=[lindex $coor_pblock 4] && COLUMN==[lindex $slices_last_row 1] && TILE_TYPE!=NULL"
				set slices [get_sites -of_objects [get_tiles -filter $filter_expr]]
				set last_value [lindex $slices_last_row 1]	
				set lut_cnt 0
				set cnt 0
				set chosen_slice 0
				puts "slices: $slices"
			}
			puts "NETS: get_LeafCells -net [get_nets -of_objects [get_pins [lindex $rp_pins $x]]] -direction INOUT"
			set leaf_cell [get_LeafCells -net [get_nets -of_objects [get_pins [lindex $rp_pins $x]]] -direction INOUT]

			set static_cell [search_String $leaf_cell $static_instance 0]
			set leaf_cell [lindex $leaf_cell $static_cell]
			puts "static_cell: $static_cell"
			puts "leaf_cell: $leaf_cell"

			puts "LEAF_CELL LOCKING: $leaf_cell"
			
			##determine in which lut the cell has to be placed of the chosen slice
			if {$lut_cnt==0 || $lut_cnt==[llength $GLOBAL_PBLOCK::slice_lut]} {
				incr cnt 
				if {$cnt==1} {
					set slice_nr [expr {$mid_slice - 1 - $chosen_slice}] 
				} else {
					set slice_nr [expr {$mid_slice + $chosen_slice}] 	
					set cnt 0
					incr chosen_slice
				}
			}
			if {$lut_cnt==[llength $GLOBAL_PBLOCK::slice_lut]} {
				set lut_cnt 0
			}	
			puts "lut_cnt: $lut_cnt"
			puts "slice_nr: $slice_nr"
			puts "SLICE: [lindex $slices $slice_nr]"
	
			##place cell in  lut [BEL] and a chosen slice [LOC]
			set_property LOC [lindex $slices $slice_nr] [get_cells $leaf_cell]
			set_property BEL [lindex $GLOBAL_PBLOCK::slice_lut $lut_cnt] [get_cells $leaf_cell]
			set_property DONT_TOUCH 1 [get_cells $leaf_cell]
			
			incr lut_cnt
								
		} else {
			incr clock_cnt
		}
	}
}

proc get_partition_pin {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set error 0
 set help 0
 set side {}

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }
			  -side { 
				set side [lshift args]
			  }				  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]
						[-side <LEFT/RIGHT>]

						
			Description: Locks the cells of the static region at the side choosed by user through option -side.
						 At this point only option LEFT or RIGHT position is existing for this procedure. This procedure needs the
						 static_coordinates as argument, so a right placement could be done. 
						 
			Return Value: List like {{reg_in[0] 1 12} {reg_in[1] 2 13} .... {reg_out[1] 5 9}}
						 Index 0: REF_NAME of ref_cell
						 Index 1: Relative x coordinate
						 Index 2: Relative y coordinate
						 
			Info:		 Reference Point is lower left corner of the associated pblock of reference cell ref_cell
			 
			Example:    get_partition_pin -ref_cell $ref_cell -side LEFT
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 
 set partition_placement {}
 set ref_cell_pins [get_pins -of_objects [get_cells $ref_cell]]
 set pblock [get_property PBLOCK [get_cells $ref_cell]]
 
 if {[llength $pblock]==0} {
	return -code error {get_partition_pin: No pblock is assigned for this ref_cell}
 }
 set ref_pblock_coor [get_rect -pblocks $pblock -exact]
 
  for {set x 0} {$x<[llength $ref_cell_pins]} {incr x} {
	
	###partition_placement saving ref_pin_name and relative coordinates for interconnects
	set ref_pin_name [get_property REF_PIN_NAME [get_pins [lindex $ref_cell_pins $x]]]
	set partition_tile [get_property HD.ASSIGNED_PPLOCS [get_pins [lindex $ref_cell_pins $x]]]
	if {[llength $partition_tile]==0} {
		return -code error {get_partition_pin: No partition pins assigned for reference cell ref_cell}	
	}
	set x_orig [get_property COLUMN [get_tiles [lindex $partition_tile 0]]]
	set y_orig [get_property ROW [get_tiles [lindex $partition_tile 0]]]
	if {$side=="LEFT"} {
		set x_relative [expr {$x_orig - [lindex [lindex $ref_pblock_coor 0] 1]}]
		set y_relative [expr {[lindex [lindex $ref_pblock_coor 0] 2] - $y_orig}]
	} else {
		set x_relative [expr {[lindex [lindex $ref_pblock_coor 0] 3] - $x_orig}]
		set y_relative [expr {[lindex [lindex $ref_pblock_coor 0] 2] - $y_orig}]	
	}
	set placement "$ref_pin_name $x_relative $y_relative"
	set partition_placement [linsert $partition_placement [llength $partition_placement] $placement]	
}
 
 return $partition_placement
}


proc locking_buf_glob_cells {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 

						
			Description: Locking Cells of buffer_outputs which are generated by the procedure to generate buffer_cells 
			 
			Example:    locking_buf_glob_cells  
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
	set recon_instances [get_cells -hierarchical * -filter {RELOC==1}]

	set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance $top_instance
	set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance

	#set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==True}]

	set all_instances $instance_below_top 
	
	 for {set x 0} {$x<[llength $recon_instances]} {incr x} {
		set all_instances [lremove $all_instances [lindex $recon_instances $x]]
	}

	set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1}]
 
	set Input_Buffer_Cells [get_cells -filter {PRIMITIVE_GROUP==IO && REF_NAME==IBUF}]

	for {set x 0} {$x<[llength $Input_Buffer_Cells]} {incr x} {
		set end 0
		set connected_leaf_cells [get_LeafCells -net [get_nets -of_objects [get_cells [lindex $Input_Buffer_Cells $x]]] -direction INOUT]
		puts "connected_leaf_cells: $connected_leaf_cells"
		
		for {set y 0} {$y<[llength $connected_leaf_cells]} {incr y} {
			if {[get_property STATUS [lindex $connected_leaf_cells $y]]=="FIXED"} {
				puts "STATUS: [get_property STATUS [lindex $connected_leaf_cells $y]]"
				set fixed_buf_cell [lindex $connected_leaf_cells $y]
				set fixed_site [get_property LOC [get_cells $fixed_buf_cell]]
			}		
		}
		
		
		set x_orig [get_property COLUMN [get_tiles -of_objects [get_sites $fixed_site]]]
		set y_orig [get_property ROW [get_tiles -of_objects [get_sites $fixed_site]]]
		
		 set all_sites [get_sites -of_objects [get_tiles -of_objects [get_sites $fixed_site]]]
		
		 if {[search_String $all_sites $fixed_site 1]!=0} {
			set y_orig [expr {$y_orig - 1}]
		 }

		###entscheiden ob slices nach links oder rechts suchen
		if {$x_orig==[lindex $GLOBAL_PBLOCK::x_range 1]} {
			set side LEFT
		} else {
			set side RIGHT
		}
		
		
		set static_buf_slices [lindex [get_slices -side $side -start $x_orig -search_in_row $y_orig] 0]
		
		set static_buf_cell [lindex $connected_leaf_cells [search_String $connected_leaf_cells $static_instance 0]]
		
		set_property LOC $static_buf_slices [get_cells $static_buf_cell]
		set_property DONT_TOUCH 1 [get_cells $static_buf_cell]
		set static_buf_nets [get_nets -of_objects [get_cells $static_buf_cell]]
		##schauen nach dem Netz welches in die untere Instanz verbunden ist
		
		set net_1	[get_pins -of_objects [get_nets [lindex $static_buf_nets 0]] -filter {IS_LEAF==0}]
		set net_2	[get_pins -of_objects [get_nets [lindex $static_buf_nets 1]] -filter {IS_LEAF==0}]
		
		if {[string length $net_1]>[string length $net_2]} {
			set net $net_1
		} else {
			set net $net_2
		}
		
		set_property DONT_TOUCH 1 [get_nets $net]
	}
}


proc place_dummy_cells {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments 
  #-----------------------------------------------------------------------------------------------------------------
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -place_in {
			  set place [lshift args]
			  }
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {[llength $place]==0} {
		return -code error {place_dummy_cells: No -place_in option is specified}
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
			
			[-place_in <RP/STATIC>]
					
			Description: This procedure places LUT1 Cells in the static instance for later usage of fixing the interface net between static region and reconfigurable region in the relocation design
						 					 
			Example:   place_dummy_cells -place_in STATIC
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
	
	set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1}]
	set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==1}]
	set static_cells {}	

	 ##PLACEMENT OF LUT1 CELLS IN THE STATIC INSTANCE
	for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		set pinList [get_pins -of_objects [get_cells [lindex $black_box_list $x]]]

		set static_cell [lindex $black_box_list $x]

		###Iteration about directions of pins --> IN/OUT
		for {set y 0} {$y<2} {incr y} { 
			
			if {$y==0} {
				set directions IN	
				set static_name OUT
			} else {
				set directions OUT
				set static_name IN
			}

			set pinsFiltered "DIRECTION==$directions"
			##Get all pins in list pinList with direction $directions 
			set pinList [get_pins -of_objects [get_cells [lindex $black_box_list $x]] -filter direction==$directions]
							
			####Iterate about all pins which have same direction $direction
			for {set k 0} {$k<[llength $pinList]} {incr k} {
				set pin [lindex $pinList $k]

				###Get nets which are connected to the Leaf Pins of Leaf Cell
				if {$place=="STATIC"} {
					set parent_net [get_nets -of_objects [get_pins $pin]]
					set rp_net $parent_net

				} else {
					set parent_net [get_nets -boundary_type lower -of_objects [get_pins $pin]]
				}
				
				if {[llength $parent_net]!=0} {
				set net_type [get_property TYPE [get_nets $parent_net]]
					
				###nur zellen einfügen die nicht mit clock netz zusammen sind
				if {$net_type!="GLOBAL_CLOCK" && $net_type!="REGIONAL_CLOCK" && $net_type!="LOCAL_CLOCK"} {
					##Cells verbinden und Cells erstellen
					puts "PARENT_NET : $parent_net" 
					set parent_net [join $parent_net]
		
					####The new cell is placed there, where the parent net is connected to in the static region
					if {$place=="STATIC"} {
						set created_net "RC_DUMMY_STAT"
						set parent_net [get_top_net -net $parent_net -instance $static_instance -created_net $created_net]
						
						set cell_name "RC_DUMMY_STAT[expr {$x}]_[expr {$static_name}]_$k"
					} else {
						set cell_name "RC_DUMMY_RP_[expr {$directions}]_$k"
					}
					
					if {$place=="STATIC"} {
						##get the instance Pin of the static instance in the netlist
						set cell_instance_pin [get_StaticInstancePins -net $rp_net -static_instance $static_instance]
					} else {
						##reconfigurable instance pin
						set cell_instance_pin $pin
					}
					puts "CELL_INSTANCE_PIN: $cell_instance_pin"
					##insert cell
					set full_cell_name [puts_LeafCell -net $parent_net -cell LUT1 -cell_name $cell_name -cell_pin_in I0 -cell_pin_out O -cell_instance_pin $cell_instance_pin] 
					set static_cells [linsert $static_cells [llength $static_cells] $full_cell_name]
					
					##setting INIT VALUE for Look Uptable functionality-->Input==Output for connected signals
					set_property INIT 2'h2 [get_cells $full_cell_name] 
				}
				}

			}
		}
		puts "static_cells: $static_cells"
	}
return $static_cells
}


proc place_buf_cells {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments 
  #-----------------------------------------------------------------------------------------------------------------
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 

			Description: This procedure inserts LUT1 cells in the net of input buffer cells. The cell LUT1 will be placed in static logic. 
						 Usage for avoiding feedthrough signals of pad nets on the fpga.
						 					 
			Example:   place_buf_cells
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 set Input_Buffer_Cells [get_cells -filter {PRIMITIVE_GROUP==IO && REF_NAME==IBUF}]
 set buf_cells {}
	 for {set x 0} {$x<[llength $Input_Buffer_Cells]} {incr x} {

		set lower_nets [get_nets -boundary_type lower -of_objects [get_pins -of_objects [get_nets -of_objects [get_cells [lindex $Input_Buffer_Cells $x]] -filter {ROUTE_STATUS!=INTRASITE}] -filter {IS_LEAF==0}]]
		set static_net [get_nets -boundary_type lower -of_objects [get_pins [get_InstancePin -net [get_nets $lower_nets] -boundary_type lower]]]	
		#puts "static_nets: $static_net"
		set Cell_Name "Buf_glob_[expr {$x}]"
		set buf_cells [linsert $buf_cells [llength $buf_cells] $Cell_Name]
		set cell_instance_pin [get_InstancePin -net $static_net -boundary_type upper]
		set full_cell_name [puts_LeafCell -net $static_net -cell LUT1 -cell_name $Cell_Name -cell_pin_in I0 -cell_pin_out O -cell_instance_pin $cell_instance_pin]
		set_property INIT 2'h2 [get_cells $full_cell_name]
	
	 }
 return $buf_cells
}


proc lock_cell {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set copy_cell {}
 set dest_cell {}
 set side {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -copy_cell { 
				set copy_cell [lshift args]
			  }	
			  -dest_cell { 
				set dest_cell [lshift args]
			  }	
			  -side { 
				set side [lshift args]
			  }				  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]

						
			Description: Copies the constraints of copy_dell to dest_cell and fixes location of the dest_cell with relative coordinates to his own pblock. 
						 
						 
			Info:		 Reference Point is lower left corner of the associated pblock of reference cell dest_cell. Relative coordinates are calculated out of the associated pblock of
						 cell copy_cell.
			 
			Example:    lock_cell -copy_cell cl_i/led_core0/U0/reconfig_rpLED/reg_out[2]_INST_0 -dest_cell cl_i/led_core1/U0/reconfig_rpLED/reg_out[2]_INST_0 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
		##get pBlocks of the denoted cells
		set locked_coor [get_rect -pblocks [get_property PBLOCK [get_cells $copy_cell]] -exact] 
		set rp_coor_dest [get_rect -pblocks [get_property PBLOCK [get_cells $dest_cell]] -exact]
		
		set copy_ref_pins  [get_pins -leaf -of_objects [get_cells $copy_cell] -filter direction=~in]
		
		puts "copy from cell: $copy_cell"
		puts "copy to cell:   $dest_cell"
		
		##get LOC and BEL from cell that is already fixed
		set prop_loc_locked [get_property LOC [get_cells $copy_cell]]
		set prop_bel_locked [get_property BEL [get_cells $copy_cell]]
		set locked_tile [get_tiles -of_objects [get_sites $prop_loc_locked]]
		
		
		##get relative x and y coordinates of fixed cell
		set x_orig [get_property COLUMN [get_tiles $locked_tile]]
		if {$side=="LEFT"} {
			set x_relative [expr {$x_orig - [lindex [lindex $locked_coor 0] 1]}]			
		} else {
			set x_relative [expr {[lindex [lindex $locked_coor 0] 3] -$x_orig}]		
		}
		set y_orig [get_property ROW [get_tiles $locked_tile]]
		set y_relative [expr {[lindex [lindex $locked_coor 0] 2] - $y_orig}]
		set locked_site_position [get_site_position $prop_loc_locked]
		if {$side=="LEFT"} {
			set filter_expr_new "ROW==[expr {[lindex [lindex $rp_coor_dest 0] 2] - $y_relative}] && COLUMN==[expr {[lindex [lindex $rp_coor_dest 0] 1] + $x_relative}]"
			set last_value [expr {[lindex [lindex $rp_coor_dest 0] 1] + $x_relative}]			
		} else {
			set filter_expr_new "ROW==[expr {[lindex [lindex $rp_coor_dest 0] 2] - $y_relative}] && COLUMN==[expr {[lindex [lindex $rp_coor_dest 0] 3] - $x_relative}]"	
			set last_value [expr {[lindex [lindex $rp_coor_dest 0] 3] - $x_relative}]			
		}

		set dest_tile [get_tile -filter $filter_expr_new]

		##compare tile types of fixed cell and to fix cell in destination tile (determined by the relative x and y coordinates)
		set tile_found 0 
		set new_row [expr {[lindex [lindex $rp_coor_dest 0] 2] - $y_relative}]
		set ref_tile_type [get_property TILE_TYPE [get_tiles $locked_tile]]
		set new_tile_type [get_property TILE_TYPE [get_tiles $dest_tile]]

		
		###if tile type of fixed cell is different of not fixed cell search for next clb column
		
		#for 2D Relocation
		set found_clb_idx -1
		for {set clb_idx 0} {$clb_idx<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr clb_idx} {
			if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $clb_idx] $ref_tile_type]!=-1} {
				set found_clb_idx $clb_idx
			}
		}
				
		if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $found_clb_idx] $ref_tile_type]!=-1 && $found_clb_idx!=-1} {
			set new_last_value $last_value
			while {$tile_found==0} {
				set new_slices [get_slices  -side $side -start $new_last_value -search_in_row $new_row]
				puts "new_slices: $new_slices "
				set new_last_value [get_slices  -side $side -start $new_last_value -search_in_row $new_row -slice_column]
				puts "new_tile_type 2: [get_property TILE_TYPE [get_tiles -of_objects [get_sites $new_slices]]]"
				puts  "ref_tile_type 2: $ref_tile_type"
				set new_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites $new_slices]]]
				
				if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $found_clb_idx] $new_tile_type]!=-1} {
					incr tile_found
				} else {
					if {$side=="LEFT"} {
						set new_last_value [expr {$new_last_value + 1}]
					} else {
						set new_last_value [expr {$new_last_value - 1}]
					}
				}
			}
			set dest_tile [get_tile -of_objects [get_sites $new_slices]]
			puts "NEW_TILE: $dest_tile"		
		} else {
		
		}
		
		##locking the cell placement of not fixed cell
		
		set dest_slice [lindex [lsort -increasing [get_sites -of_objects [get_tiles $dest_tile]]] $locked_site_position]
		
		##Set BEL
		if {[llength [get_property BEL [get_cells $dest_cell]]]==0} {
			##for 2D Relocation
			set slice_type [get_property SITE_TYPE [get_sites $dest_slice]]
			set prop_bel_locked [string replace  $prop_bel_locked 0 [expr {[string length $slice_type] - 1}] $slice_type]
			set_property BEL $prop_bel_locked [get_cells $dest_cell]
		} 
		
		##Set BEL Pins
		set pins_connect_list {}
		if {[get_property primitive_group [get_cells $dest_cell]]=="LUT" || [get_property primitive_group [get_cells $dest_cell]]=="INV" || [get_property primitive_group [get_cells $dest_cell]]=="BUF"} {
			for {set x 0} {$x<[llength $copy_ref_pins]} {incr x} {
				set bel_locked_pin [lindex [split [get_bel_pins -of [get_pins [lindex $copy_ref_pins $x]]] /] end]
				set load_pin_locked_in [lindex [split [lindex $copy_ref_pins $x] /] end]
				set pins_connect "$load_pin_locked_in:$bel_locked_pin"
				set pins_connect_list [linsert $pins_connect_list $x $pins_connect]		
			}
			
			if {[llength [get_property LOCK_PINS [get_cells $dest_cell]]]==0} {
				set_property LOCK_PINS $pins_connect_list [get_cells $dest_cell]
			}
		}
		
		##Set LOC 
		if {[llength [get_property LOC [get_cells $dest_cell]]]==0} {
			set_property LOC $dest_slice [get_cells $dest_cell]
			puts "LOCE_SLICE: set_property LOC $dest_slice [get_cells $dest_cell]"
			#set_property DONT_TOUCH 1 [get_cells $rp_leaf_cell]
		}
		
}


proc copy_lock_static_cells {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set static_coordinates {}
 set side {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }		
			  -static_coordinates { 
				set static_coordinates [lshift args]
			  }	
			  -side { 
				set side [lshift args]
			  }				  
			  -help {
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
		return -code error {ERROR }
	  }
	  if {[llength $ref_cell]==0 || [llength $side]==0 || [llength $static_coordinates]==0} {
		return -code error {ERROR: Ref_cell, side or static_coordinates is not determined}
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]
						[-static_coordinates <FROM draw_static_region function>]
						[-side <LEFT/RIGTH>]

						
			Description: Copies the STAT Cell positions of referenced STAT Cells of referenced cell to the rest STAT Cells of the interfaces.	 
			 
			Example:    copy_lock_static_cells -ref_cell $ref_cell -side $side -static_coordinates $static_coordinates
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }		
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 
 set recon_instances [get_cells -hierarchical * -filter {BLACK_BOX==1}]
 set rest_rp [lremove $recon_instances $ref_cell]	 
 set ref_cell_pins [get_pins -of_objects [get_cells $ref_cell]]
 set locked_coor [get_rect -pblocks [get_property PBLOCK [get_cells $ref_cell]] -exact] 

 set locked_ref_pins [get_pins -of_objects [get_cells $ref_cell]]
 
 ##choose direction in which the Cells of rest rp cells have to be placed
 	if {$side=="LEFT"} {
		set new_start_val -1
	} else {
		set new_start_val 1	
	}
 
 for {set x 0} {$x<[llength $rest_rp]} {incr x} {
 	set rest_rp_cell [lindex $rest_rp $x]
	set rest_dest_pins [get_pins -of_objects [get_cells $rest_rp_cell]]
	set coor_pblock [join $locked_coor]
	set row_search [lindex $coor_pblock 2]
	set clk_cnt 0
	
	for {set y 0} {$y<[llength $locked_ref_pins]} {incr y} {
		puts "SIGNAL TYPE: [get_property TYPE [get_nets -of_objects [get_pins [lindex $locked_ref_pins $y]]]] "
		puts "y: $y"
		puts "end y: [llength $locked_ref_pins]"
		##get first clb column
		if {$y==0} {
			set locked_rp_block_coor [get_rect -pblocks [get_pblocks -of_objects [get_cells $ref_cell]] -exact]
			set dest_rp_block_coor [get_rect -pblocks [get_pblocks -of_objects [get_cells $rest_rp_cell]] -exact]
			set used_pblock [lindex [lindex $dest_rp_block_coor 0] 0]
			set actual_static_coordinates [lindex $static_coordinates [search_part_list $static_coordinates $used_pblock]]
			set start_value [lindex $actual_static_coordinates [expr {[search_part_list $actual_static_coordinates $side] + 1}]]		
			set slices_last_row [get_slices -pblock $used_pblock -side $side -start $start_value -return_all]
			set slice_nr_column [llength [lindex $slices_last_row 0]]
		}		
		
		
		set net_type [get_property TYPE [get_nets -of_objects [get_pins [lindex $locked_ref_pins $y]]]] 
			
		if {$net_type!="GLOBAL_CLOCK" && $net_type!="REGIONAL_CLOCK" && $net_type!="LOCAL_CLOCK"} {
		##pin namen des jetzigen pins am locked zelle
		
			set multiple_y [expr {round (double ($y/$slice_nr_column))}]
			puts "mult_x: $multiple_y"
			puts "if {$y>=[expr {($multiple_y*$slice_nr_column)-1}] && $multiple_y!=0 && [expr {$y-($multiple_y*$slice_nr_column)+1}]==1}"
			##serach for next clb column
			if {$y>=[expr {($multiple_y*$slice_nr_column)-1}] && $multiple_y!=0 && [expr {$y-($multiple_y*$slice_nr_column)+1}]==1} {
				puts "------------------------------------------------------------------------------------------------>IN"
				set start_value_2 [expr {[lindex $slices_last_row 1] + $new_start_val}]
				set slices_last_row [get_slices -side $side -start $start_value_2 -return_all -search_in_row $row_search]
				set filter_expr "ROW<=[lindex $coor_pblock 2] && ROW>=[lindex $coor_pblock 4] && COLUMN==[lindex $slices_last_row 1] && TILE_TYPE!=NULL"
				set slices_last_row "{[get_sites -of_objects [get_tiles -filter $filter_expr]]} [lindex $slices_last_row 1]"	
				puts "--------------------------------------------------------------------------------------------->OUT"
			}		
		
		set locked_ref_pin [get_property REF_PIN_NAME [get_pins [lindex $locked_ref_pins $y]]]
		
		##search for identical pin name of rest rp cells 
		for {set z 0} {$z<[llength $rest_dest_pins]} {incr z} {
			if {[StringPart_Compare [lindex $rest_dest_pins $z] $locked_ref_pin]==1} {
				set dest_pin [lindex $rest_dest_pins $z]
			}
		}	
		##determine the net and the relative associated cells of reference  cells and rest  cells
		
		puts "dest_net: [get_nets -of_objects [get_pins $dest_pin]]"
		puts "ref_net: [get_nets  -of_objects [get_pins [lindex $locked_ref_pins $y]]]"
		
		set dest_cells [get_LeafCells -net [get_nets -of_objects [get_pins $dest_pin]] -direction INOUT]
		set ref_locked_cells [get_LeafCells -net [get_nets -of_objects [get_pins [lindex $locked_ref_pins $y]]] -direction INOUT]
		
		##static cells which are relativly associated, because of the placement
		set static_dest_cell [lsearch -regexp $dest_cells .*RC_DUMMY_STAT.*]
		set static_lock_cell [lsearch -regexp $ref_locked_cells .*RC_DUMMY_STAT.*]
		puts "static_dest_cell: $static_dest_cell"
		puts "static_lock_cell: $static_lock_cell"
		
		if {$static_dest_cell==-1 && $static_lock_cell==-1} {
			set inst_ref_rp_cell [InstancePath $ref_cell 2]
			set inst_rest_rp_cell [InstancePath $rest_rp_cell 2]
			set static_dest_cell [lsearch -regexp $ref_locked_cells $inst_ref_rp_cell.*]
			set static_lock_cell [lsearch -regexp $dest_cells $inst_rest_rp_cell.*]
		}
		
		set dest_cell [lindex $dest_cells $static_dest_cell]
		set ref_locked_cell [lindex $ref_locked_cells $static_lock_cell]
		

		puts "Copy from Cell: $ref_locked_cell"
		puts "Copy to cell: $dest_cell"		
		
		##properties from locked cell (static cells which are connected via the interface nets with the reference cell) from which the properties are copied
		set locked_site [get_property LOC [get_cells $ref_locked_cell]]
		set locked_tile [get_tiles -of_objects [get_sites $locked_site]]
		set locked_tile_type [get_property TILE_TYPE [get_tiles $locked_tile]]
		set locked_row  [get_property ROW [get_tiles $locked_tile]]
		puts "locked_row: $locked_row"
		set locked_column  [get_property COLUMN [get_tiles -of_objects [get_sites $locked_site]]]
		puts "locked_column: $locked_column"
		set locked_site_position [get_site_position $locked_site]
		
		set rest_rp_static_coor [lindex $static_coordinates [search_part_list $static_coordinates [get_pblocks -of_objects [get_cells $rest_rp_cell]]]]
		set side_idx_hor [search_String $rest_rp_static_coor $side 1]
			
		##Lower Left corner of pblock in rest_rp_coor as reference point
		set y_relative_loc [expr {[lindex [lindex $locked_rp_block_coor 0] 2] - $locked_row}]
		
		puts "dest_rp: $dest_rp_block_coor"
		puts "y_relative: $y_relative_loc"

		puts "y==$y"

		puts "slices_last_row: $slices_last_row"
		
		set dest_column [lindex $slices_last_row 1]
		set dest_row [expr {[lindex [lindex $dest_rp_block_coor 0] 2] - $y_relative_loc}]
				
		set filter_expr "ROW==$dest_row && COLUMN==$dest_column"
		set dest_tile [get_tiles -filter $filter_expr]
		set dest_tile_type [get_property TILE_TYPE [get_tiles $dest_tile]]
		
		##search for destination column beside the rest rp partition to place the static cells which are connected via interface nets with rest rp instances
		
		##for 2D Relocation		
		set found_clb_idx -1
		for {set clb_idx 0} {$clb_idx<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr clb_idx} {
			if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $clb_idx] $locked_tile_type]!=-1} {
				set found_clb_idx $clb_idx
			}
		}		
		
		##get the appropriate site
		puts "dest_column: $dest_column"
		puts "dest_row: $dest_row"
		

		##search for next clb column
		set tile_found 0
		if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $found_clb_idx] $dest_tile_type]!=-1 && $found_clb_idx!=-1} {
			#set dest_column $last_value
			while {$tile_found==0} {
				set dest_site [get_slices  -side $side -start $dest_column -search_in_row $dest_row]
				set dest_column [get_slices  -side $side -start $dest_column -search_in_row $dest_row -slice_column]
				set dest_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites $dest_site]]]
				
				if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $found_clb_idx] $dest_tile_type]!=-1} {
					incr tile_found
				} else {
					if {$side=="LEFT"} {
						set dest_column [expr {$dest_column - 1}]
					} else {
						set dest_column [expr {$dest_column + 1}]
					}
				}
			}
			set dest_tile [get_tile -of_objects [get_sites $dest_site]]
		} else {
			puts "No compatibel tiles for clbs found in GLOBAL_PBLOCK::compatibel_clbs in RelocSetup.tcl"
		}		

		##herausfinden ob unterer oder oberer Slice vom CLB gewählt
		set dest_slice [lindex [lsort -increasing [get_sites -of_objects [get_tiles $dest_tile]]] $locked_site_position]
		
		##for 2D Relocation
		if {[get_property IS_LOC_FIXED [get_cells $dest_cell]]==1} {
			set_property IS_LOC_FIXED 0 [get_cells $dest_cell]
			set_property IS_BEL_FIXED 0 [get_cells $dest_cell]
			
			
		}
		##Get the the slice and  BEL of fixed static cell 
		set dest_slice_type [get_property SITE_TYPE [get_sites $dest_slice]]
		set prop_bel_locked [get_property BEL [get_cells $ref_locked_cell]]
		set prop_bel_locked [string replace  $prop_bel_locked 0 [expr {[string length $dest_slice_type] - 1}] $dest_slice_type]
		
		##Set the BEL of unfixed static cell
		set_property BEL $prop_bel_locked [get_cells $dest_cell]
		
		##Set the appropriate Connection of nets to the Bel via BEL Pins
		set pins_connect_list {}
		set copy_ref_pins [get_pins -leaf -of_object [get_cells $ref_locked_cell] -filter direction=~in]
		for {set x 0} {$x<[llength $copy_ref_pins]} {incr x} {
			set bel_locked_pin [lindex [split [get_bel_pins -of [get_pins [lindex $copy_ref_pins $x]]] /] end]
			set load_pin_locked_in [lindex [split [lindex $copy_ref_pins $x] /] end]
			set pins_connect "$load_pin_locked_in:$bel_locked_pin"
			set pins_connect_list [linsert $pins_connect_list $x $pins_connect]		
		}
		
		if {[llength [get_property LOCK_PINS [get_cells $dest_cell]]]==0} {
			set_property LOCK_PINS $pins_connect_list [get_cells $dest_cell]
		}
		
		##Set the LOC property of unfixed static cell to fix the static cell
		set_property LOC $dest_slice [get_cells $dest_cell]
		set_property DONT_TOUCH 1 [get_cells $dest_cell]		
			
	} else {
		incr clk_cnt
	}
	}
 } 
 
}

proc copy_lock_rp_cells {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set side {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }	
			  -side { 
				set side [lshift args]
			  }		 			  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]
						[-sdie <LEFT/RIGHT>]

						
			Description: Copies the RP Cells positions from -ref_cell to place own RP Cells 
						 		 
			Example:    copy_lock_rp_cells -ref_cell $ref_cell -side $side
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
	
	###RP Cells of rest rp instances are relatively placed (associated to the side and the corner of the particular partition) to the RP Cells of the reference rp instance
	
	set recon_instances [get_cells -hierarchical * -filter {BLACK_BOX==1}]
	set rest_rp [lremove_element $recon_instances [lsearch $recon_instances $ref_cell]]	
	set ref_cell_pins [get_pins -of_objects [get_cells $ref_cell]]
	set locked_coor [get_rect -pblocks [get_property PBLOCK [get_cells $ref_cell]] -exact] 
	
	for {set x 0} {$x<[llength $rest_rp]} {incr x} {
		set rest_rp_cell [lindex $rest_rp $x]
		set rest_rp_pins [get_pins -of_objects [get_cells $rest_rp_cell]]
		puts "rest_rp_cell: $rest_rp_cell"
		
		set already_locked_cells {}
		
		###locking of cells  in matters of the pins of the reference instance
		for {set y 0} {$y<[llength $ref_cell_pins]} {incr y} {
			set locked_ref_pin [get_property REF_PIN_NAME [get_pins [lindex $ref_cell_pins $y]]]
			puts "y: $y"
			puts "y ende: [llength $ref_cell_pins]"
			set net_type [get_property TYPE [get_nets -of_objects [get_pins [lindex $ref_cell_pins $y]]]] 
		if {$net_type!="GLOBAL_CLOCK" && $net_type!="REGIONAL_CLOCK" && $net_type!="LOCAL_CLOCK"} {
			puts "--------------------------------------------------------------------------------------PIN:[lindex $ref_cell_pins $y]-------------------------------------------------------- "
			##search for identical pin of rest rp instances
			for {set z 0} {$z<[llength $rest_rp_pins]} {incr z} {
				if {[StringPart_Compare [lindex $rest_rp_pins $z] $locked_ref_pin]==1} {
					set rp_pin [lindex $rest_rp_pins $z]
				}
			}
			
			set rp_leaf_cell [get_LeafCells -net [get_nets -of_objects [get_pins $rp_pin]] -direction INOUT]
			  
			for {set rp 0} {$rp<[llength [search_String $rp_leaf_cell [lindex $rest_rp $x] 0]]} {incr rp} {
				##get already locked RP Cells of rerference rp instance and the associated RP Cells of the rest rp instances
				set rp_leaf_cell [lindex $rp_leaf_cell [lindex [search_String $rp_leaf_cell [lindex $rest_rp $x] 0] $rp]]
				set rp_locked_cell [get_LeafCells -net [get_nets -of_objects [get_pins [lindex $ref_cell_pins $y]]] -direction INOUT]
				set rp_locked_cell_idx [lsearch -regexp $rp_locked_cell .*$ref_cell]
				set new_rp_locked_cell {}
				for {set ref 0} {$ref<[llength $rp_locked_cell_idx]} {incr ref} {
					set new_rp_locked_cell [linsert $new_rp_locked_cell [llength $new_rp_locked_cell] [lindex $rp_locked_cell [lindex $rp_locked_cell_idx $ref]]]
				}
				set rp_locked_cell $new_rp_locked_cell
				
				for {set z 0} {$z<[llength $rp_locked_cell]} {incr z} {
					if {[StringPart_Compare [lindex $rp_locked_cell $z] [lindex [split $rp_leaf_cell /] end]]==1} {
						set rp_locked_cell [lindex $rp_locked_cell $z]
					}
				}				
	
				puts "rp_locked_cell: $rp_locked_cell"
				puts "rp_leaf_cell: $rp_leaf_cell"
				
				##locking cell position of RP Cell of rest rp instances
				if {[search_String $already_locked_cells $rp_leaf_cell 1]==-1} {
					lock_cell -copy_cell $rp_locked_cell -dest_cell $rp_leaf_cell -side $side 
					set already_locked_cells [linsert $already_locked_cells [llength $already_locked_cells] $rp_leaf_cell]
					set_property DONT_TOUCH 1 [get_cells $rp_leaf_cell]
				}

			}	
		}
		}
	}
}


proc copy_lock_interface_nets {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }					  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]

						
			Description: Copies interface_nets "fixed_route property" to the according nets of the rest reconfigurable modules.
				         Copies net for 2D and 1D nets. Manipulating Nodes of fixed_route property
						 		 
			Example:    copy_lock_interface_nets -ref_cell $ref_cell 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 set clb_site_types $GLOBAL_PBLOCK::clb_site_types
 set recon_instances [get_cells -hierarchical * -filter {BLACK_BOX==1}]
 set rest_rp [lremove $recon_instances $ref_cell]	 
 set ref_cell_pins [get_pins -of_objects [get_cells $ref_cell]]
 set locked_coor [get_rect -pblocks [get_property PBLOCK [get_cells $ref_cell]] -exact] 
 
 set locked_ref_pins [get_pins -of_objects [get_cells $ref_cell]] 
 
  for {set x 0} {$x<[llength $rest_rp]} {incr x} {
 	set rest_rp_cell [lindex $rest_rp $x]
	set rest_dest_pins [get_pins -of_objects [get_cells $rest_rp_cell]]
	
	
	puts "locked_ref_pins $locked_ref_pins"
	for {set y 0} {$y<[llength $locked_ref_pins]} {incr y} {
		##pin namen des jetzigen pins am locked zelle
		set locked_ref_pin [get_property REF_PIN_NAME [get_pins [lindex $locked_ref_pins $y]]]
		
		##suchen nach dem richtien pin auf rp seite
		for {set z 0} {$z<[llength $rest_dest_pins]} {incr z} {
			if {[StringPart_Compare [lindex $rest_dest_pins $z] $locked_ref_pin]==1} {
				set dest_pin [lindex $rest_dest_pins $z]
			}
		}	

		set locked_interface_net [get_nets -of_objects [get_pins [lindex $locked_ref_pins $y]]]
		set dest_interface_net [get_nets -of_objects [get_pins $dest_pin]]
        
		puts "locked_interface_net: $locked_interface_net"
		puts "dest_interface_net: $dest_interface_net"
		
		set net_type [get_property TYPE [get_nets $locked_interface_net]] 
	    if {$net_type!="GLOBAL_CLOCK" && $net_type!="REGIONAL_CLOCK" && $net_type!="LOCAL_CLOCK"} {

		set locked_cells [get_LeafCells -net $locked_interface_net -direction INOUT]
		set dest_locked_cells [get_LeafCells -net $dest_interface_net -direction INOUT]
		
		set fixed_interface_net [get_property FIXED_ROUTE [get_nets $locked_interface_net]]
		
		##########
		set locked_leaf_pins [get_pins -leaf -of_objects [get_nets $locked_interface_net]]
		
		set locked_pips_rough [get_pips -of_objects [get_nets $locked_interface_net]]
		set detailed_pips     [lindex [get_property FIXED_ROUTE [get_nets $locked_interface_net]] 0]
		puts "locked_pips_rough: $locked_pips_rough"
		set old_detailed_pips $detailed_pips
		puts "old detailed_pips: $detailed_pips"	
		
		for {set z 0} {$z<[llength $locked_leaf_pins]} {incr z} {
			puts "Y: $y"
			puts "Z: $z"
			##Infos zu den Zellen von der die Netzte kopiert werden sollen
			set site_pin [get_site_pins -of_objects [get_pins [lindex $locked_leaf_pins $z]]]
			puts "site_pin: $site_pin"
			set locked_cell [get_cells -of_objects [get_pins [lindex $locked_leaf_pins $z]]]
			set locked_cell_name [lindex [split $locked_cell /] end]
			set locked_node [get_nodes -of_objects [get_site_pins -of_objects [get_pins [lindex $locked_leaf_pins $z]]]]
			set fixed_node [cutString $locked_node [expr {[string first / $locked_node 0] + 1}] [expr {[string length $locked_node]}]]
			set locked_site [get_sites -of_objects [get_cells $locked_cell]]
			set locked_site_position [get_site_position $locked_site]
			set locked_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites $locked_site]]]
			set locked_clb_tile_type [cutString $locked_tile_type 0 [expr {[string first _ $locked_tile_type 0]}]]
			set search_start 0
			
			puts "locked_interface_net: $locked_interface_net"
			puts "dest_interface_net: $dest_interface_net"
			puts "locked_cell: $locked_cell"
			puts "locked_site_position: $locked_site_position"
			puts "locked_node: [get_nodes -of_objects [get_site_pins -of_objects [get_pins [lindex $locked_leaf_pins $z]]]]"
			
			##passende Zelle finden an die das Netz kopiert wird
			for {set r 0} {$r<[llength $dest_locked_cells]} {incr r} {
				##wenn selber statische Zellen eingefügt
				if {[StringPart_Compare $locked_cell_name RC_DUMMY_STAT]==1} {
					if {[StringPart_Compare [lindex $dest_locked_cells $r] RC_DUMMY_STAT]==1} {
						set not_fixed_cell [lindex $dest_locked_cells $r]
					}	
				} else {
				##vorher {[StringPart_Compare [lindex $dest_locked_cells $r] $locked_cell]==1 || [StringPart_Compare [lindex $dest_locked_cells $r] HD_PR]==1} 
				if {[StringPart_Compare [lindex $dest_locked_cells $r] RC_DUMMY_RP]==1 || [StringPart_Compare [lindex $dest_locked_cells $r] HD_PR]==1} {
						set not_fixed_cell [lindex $dest_locked_cells $r]
				} 

				}				
			}	
			

			puts "not_fixed_cell: $not_fixed_cell"
			#puts "----------------------------------------------------------------------------------"
			puts "locked_node: $locked_node"
			#puts "----------------------------------------------------------------------------------"
			
			###Informationen zu den Zellen holen an die Netz kopiert werden soll
			set locked_fixed_site [get_sites -of_objects [get_cells $not_fixed_cell]]
			set locked_fixed_site_position [get_site_position $locked_fixed_site]
			#puts "locked_fixed_site_position: $locked_fixed_site_position"
			set locked_fixed_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites $locked_fixed_site]]]
			set fixed_clb_tile_type [cutString $locked_fixed_tile_type 0 [expr {[string first _ $locked_fixed_tile_type 0]}]]
			
			puts "----------------------------------------------------------------------------------"
			
			if {[get_property IS_OUTPUT_PIN [get_nodes -of_objects [get_site_pins -of_objects [get_pins [lindex $locked_leaf_pins $z]]]]]==1} {
				##String manipulation out of CLBLL_R_X51Y125/CLBLL_LL_A doing CLBLL_R_X51Y125/CLBLL_R.CLBLL_LL_A 
				set part_pip "[cutString $locked_node 0 [expr {[string first / $locked_node 0]}]]/$locked_tile_type.[expr {[cutString $locked_node [expr {[string first / $locked_node 0] + 1}] [string length $locked_node]]}]"
				puts "part_pip: $part_pip"
				set part_pip_idx_list [lsearch -all $locked_pips_rough $part_pip*]
				set part_pip_idx_list [linsert $part_pip_idx_list [llength $part_pip_idx_list] [expr {[lindex $part_pip_idx_list [expr {[llength $part_pip_idx_list] - 1}]] + 1}]]
				puts "PART_PIP_IDX: $part_pip_idx_list"
				
				#set part_pip_idx_list "$part_pip_idx [expr {$part_pip_idx + 1}]" 
				set output_idx 0
			} elseif {[get_property IS_INPUT_PIN [get_nodes -of_objects [get_site_pins -of_objects [get_pins [lindex $locked_leaf_pins $z]]]]]==1} {
				##locked_node: INT_R_X51Y125/NL1BEG_N3
				##part_pip0: INT_R_X51Y125/ 
				set part_pip0 "[cutString $locked_node 0 [expr {[string first / $locked_node 0] + 1}]]"
				##part_pip1: NL1BEG_N3
				set part_pip1 "[cutString $locked_node [expr {[string first / $locked_node 0] + 1}] [string length $locked_node]]"
				##search in rough pips for expr INT_R_X51Y125/*NL1BEG_N3 
				set part_pip_idx_list [expr {[lsearch $locked_pips_rough $part_pip0*$part_pip1] + 1}]
				set output_idx 0
			}		
			
			############netze durchgehen um die route entsprechend zu verändern
			##Example fixed route: { CLBLL_LL_A CLBLL_LOGIC_OUTS12 NL1BEG_N3 EE2BEG3 NE2BEG3 SE2BEG3  { SL1BEG3 SW2BEG3 IMUX_L8 CLBLM_M_A5 }  SW2BEG3  { IMUX_L15 CLBLM_M_B1 }  IMUX_L31 CLBLM_M_C5 } 
			##erstmal Liste aufbröseln 
			
			 puts "BEFORE CONVERTION:            old detailed_pips: $detailed_pips"
			 if {$z==0} {
			 set idx 0
			 set old_list $detailed_pips
			 set list_start {}
			 set list_end {}
			 set end 0
			 while {$end==0} {
				if {[llength [lindex $old_list $idx]]!=1} {
					set list_start [linsert $list_start 0 $idx]
					set new_list [list_dissolve $old_list]
					set list_end [linsert  $list_end 0 [expr {[llength $new_list] - [llength $old_list]}]]
					
					if {[llength $new_list]==[llength $old_list]} {
						set end 1
					}
					
					set old_list $new_list
				}
				incr idx
			 }
			
			set detailed_pips $new_list
			}
			
			set in_list 0
			for {set r 0} {$r<[llength $detailed_pips]} {incr r} {		
						puts "part_pip_idx_list : $part_pip_idx_list"
						
						if {$r==[lindex $part_pip_idx_list $output_idx]} {
							puts "r: $r "
							puts "$output_idx!=[lindex $part_pip_idx_list [expr {[llength $part_pip_idx_list] - 1}]]"
							if {$output_idx!=[lindex $part_pip_idx_list [expr {[llength $part_pip_idx_list] - 1}]]} {
								set old_node [lindex $detailed_pips $r]
								set clb_type_idx [search_part_list $clb_site_types $fixed_clb_tile_type]
								set clb_site_typ_idx [expr {1 + $locked_fixed_site_position}]

								set slice_type [lindex [lindex $clb_site_types $clb_type_idx] $clb_site_typ_idx]
								set new_node "[expr {$fixed_clb_tile_type}]_[expr {$slice_type}][cutString $old_node [string last _ $old_node [string length $old_node]] [string length $old_node]]"
							} else {
								set old_node [lindex $detailed_pips $r]
								set clb_type_idx [search_part_list $clb_site_types $fixed_clb_tile_type]
								set clb_site_typ_idx [expr {1 + $locked_fixed_site_position}]
	
								set slice_type [lindex [lindex $clb_site_types $clb_type_idx] $clb_site_typ_idx]
								set new_node "[expr {$fixed_clb_tile_type}][cutString $old_node [string first _ $old_node 0] [string length $old_node]]"								
							}
							
							set detailed_pips [lreplace $detailed_pips $r $r $new_node]

							if {[llength $part_pip_idx_list]!=1} {
								incr output_idx
							}
							
							
						}		
			}	
		}

		##liste wieder zusammen bauen
		 set build_list {}
		 set new_list $detailed_pips
		 puts "list_end: $list_end"
		 puts "list_start: $list_start"
		 for {set l 1} {$l<[llength $list_end]} {incr l} {
			set build_list {}
			for {set n [lindex $list_start $l]} {$n<=[expr {[lindex $list_end $l] + [lindex $list_start $l]}]} {incr n} {
				set build_list [linsert $build_list [llength $build_list] [lindex $new_list $n]]
			}
			set new_list [lreplace $new_list [lindex $list_start $l]  [expr {[lindex $list_end $l] + [lindex $list_start $l]}] $build_list]
		 }	
		 set detailed_pips $new_list
		 
		puts "new detailed_pips: $detailed_pips"
		puts "old detailed_pips: $old_detailed_pips"
		set new_detailed_pips {}
		set new_detailed_pips [linsert $new_detailed_pips 0 $detailed_pips]
		set_property FIXED_ROUTE $detailed_pips [get_nets [get_property PARENT [get_nets $dest_interface_net]]]	
	}		
	}
 }
 
}

proc lock_rp_cells {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set ref_cell {}
 set side {}
 set static_coordinates {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set ref_cell [lshift args]
			  }
			  -side { 
				set side [lshift args]
			  }				  
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <ref_cell>]
						[-side <LEFT/RIGHT>]
						
			Description: Places the RP Cells 
			 
			Example:    lock_rp_cells 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 
	#set rp_block cl_i/led_core0
	set recon_instances [get_cells -hierarchical * -filter {RELOC==1}]

	set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance $top_instance
	set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
	current_instance

	set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1}]
	
	

	set rp_pins [get_pins -of_objects [get_cells $ref_cell]]
	set used_pblock [get_property PBLOCK [get_cells $ref_cell]]

	set actual_static_coordinates [get_rect -pblocks [get_pblocks -of_objects [get_cells $ref_cell]]]
	set actual_static_coordinates [join $actual_static_coordinates]

	set start_value [lindex $actual_static_coordinates 1]
	#puts "1: get_slices -pblock $used_pblock -side $side -start $start_value"
	set slices [get_slices -pblock $used_pblock -side $side -start $start_value]
	#puts "2: get_slices -pblock $used_pblock -side $side -start $start_value -slice_column"
	set last_value [get_slices -pblock $used_pblock -side $side -start $start_value -slice_column]

	set mid_slice [expr {[llength $slices]/2}] 

	set locked_placement {}
	set cnt 0
	set lut_cnt 0
	set chosen_slice 0
	set used_pins {}
	set locked_coor [get_rect -pblocks [get_property PBLOCK [get_cells $ref_cell]] -exact]
	
	set ref_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites [lindex $slices 0]]]]

	for {set x 0} {$x<[llength $rp_pins]} {incr x} {
		puts "-------------------------------------------------------PIN: [lindex $rp_pins $x]"
		set net_type [get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $x]]]] 
		if {$net_type!="GLOBAL_CLOCK" && $net_type!="LOCAL_CLOCK" && $net_type!="REGIONAL_CLOCK"} {
			if {$x>=[llength $slices]} {
				set start_value [expr {$last_value + 1}]
				set slices [get_slices -pblock pblock_1 -side $side -start $start_value]
				set last_value [get_slices -pblock pblock_1 -side $side -start $start_value -slice_column]	
				set chosen_slice 0
				puts "slices: $slices"
				set ref_tile_type [get_property TILE_TYPE [get_tiles -of_objects [get_sites [lindex $slices 0]]]]
			}
			puts "NETS: get_LeafCells -net [get_nets -of_objects [get_pins [lindex $rp_pins $x]]] -direction INOUT"
			set leaf_cell [get_LeafCells -net [get_nets -of_objects [get_pins [lindex $rp_pins $x]]] -direction INOUT]
			#set all_leaf_cells $leaf_cell
			set static_cell [search_String $leaf_cell $ref_cell 0]
			set leaf_cell [lindex $leaf_cell [lindex $static_cell 0]]
			# for {set rem 0} {$rem<[llength $all_leaf_cells]} {incr rem} {
				# set leaf_cell [lremove_element $leaf_cell [lsearch -regexp $leaf_cell $ref_cell.*]]
			# }
			puts "LEAF_CELL LOCKING: $leaf_cell"
			
			if {$lut_cnt==0 || $lut_cnt==[llength $GLOBAL_PBLOCK::slice_lut]} {
				incr cnt 
				if {$cnt==1} {
					set slice_nr [expr {$mid_slice - 1 - $chosen_slice}] 
				} else {
					set slice_nr [expr {$mid_slice + $chosen_slice}] 	
					set cnt 0
					incr chosen_slice
				}
			}
			if {$lut_cnt==[llength $GLOBAL_PBLOCK::slice_lut]} {
				set lut_cnt 0
			}		

			
			set_property LOC [lindex $slices $slice_nr] [get_cells $leaf_cell]
			set_property BEL [lindex $GLOBAL_PBLOCK::slice_lut $lut_cnt] [get_cells $leaf_cell]
			
			incr lut_cnt
			
			set_property DONT_TOUCH 1 [get_cells $leaf_cell]
			
			set prop_locked_bel [get_property BEL [get_cells $leaf_cell]]
			set prop_locked_tile [get_tiles -of_objects [get_sites [lindex $slices $slice_nr]]]
			
			set x_orig [get_property COLUMN [get_tiles $prop_locked_tile]]
			set x_relative [expr {$x_orig - [lindex [lindex $locked_coor 0] 1]}]
			set y_orig [get_property ROW [get_tiles $prop_locked_tile]]
			set y_relative [expr {$y_orig - [lindex [lindex $locked_coor 0] 4]}]	
				
			set used_pins "[lindex $rp_pins $x] $leaf_cell $prop_locked_bel [get_site_position [lindex $slices $slice_nr]] $x_relative $y_relative"
			set locked_placement [linsert $locked_placement [llength $locked_placement] $used_pins]	
		}
	}
	}

	
 proc get_rp_clk_nodes {args} { 
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set cell {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -ref_cell { 
				set cell [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-ref_cell <rp_Cell>]
						
			Description: This procedure gets the nodes of fixed clk_line on the used clock line horizontaly and the node of the bufg cell.
						 This function is only used when only one cell is contacted in the rp region to the clk net
						 
			Example:    get_rp_clk_nodes -ref_cell mb_st_i/mb_0_1/U0/rc_i
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	set clk_net {}
	set clk_net [get_nets -of_objects [get_cells $cell] -filter {TYPE==GLOBAL_CLOCK || TYPE==LOCAL_CLOCK || TYPE==REGIONAL_CLOCK} -quiet]
	set clk_nodes {}
	
	if {[llength $clk_net]!=0} { 
	
	
	for {set x 0} {$x<[llength $clk_net]} {incr x} {
		set all_act_clk_pips [get_pips -of_objects [lindex $clk_net $x]]
		set clk_pin [get_InstancePin -net [get_nets [lindex $clk_net $x]] -boundary_type lower]

		set clk_cells [get_LeafCells -net [lindex $clk_net $x] -direction INOUT]
		set clk_rp_cells [lindex $clk_cells [lsearch -regexp $clk_cells $cell.*]]
		
		##erstmal ohne mehrere Zellen
		if {[llength $clk_rp_cells]!=1} {
			return -code error {There is more than one clk cell contacted to the clk line in the rp cell}
		}

		set clk_cell_site [get_sites -of_objects [get_cells $clk_rp_cells]]
		set clk_cell_tile [get_tiles -of_objects [get_sites $clk_cell_site]]

		##fnd_pip --> pip of clk_cell_tile 
		set fnd_pip [lsearch -regexp $all_act_clk_pips $clk_cell_tile.*]
		set all_clk_hrow_tiles [lsearch -regexp -all $all_act_clk_pips CLK_HROW.*]
		set end 0
		set x 0

		while {$end==0} {
			
			if {$fnd_pip>[lindex $all_clk_hrow_tiles $x] && $fnd_pip<[lindex $all_clk_hrow_tiles [expr {$x + 1}]]} {
				set clk_hrow_found $x
				set clk_pip [lindex $all_act_clk_pips [lindex $all_clk_hrow_tiles $x]]
				incr end
			}
			incr x
			if {$x==[llength $all_clk_hrow_tiles]} {
				if {$fnd_pip>[lindex $all_clk_hrow_tiles [expr {$x - 1}]]} {
				set clk_hrow_found [expr {$x - 1}]
				set clk_pip [lindex $all_act_clk_pips [lindex $all_clk_hrow_tiles [expr {$x - 1}]]]
				incr end		
				}
				incr end
			}
		}

		set apropriate_node_hrow [get_nodes -of_objects [get_pips $clk_pip] -filter {IS_OUTPUT_PIN==0 && IS_INPUT_PIN==0}]

		set bufg_tiles [lsearch -regexp -all $all_act_clk_pips CLK_BUFG.*]

		set clk_bufg_pip [lindex $all_act_clk_pips [lindex $bufg_tiles 0]]

		set apropriate_node_bufg [get_nodes -of_objects [get_pips $clk_bufg_pip] -filter {IS_OUTPUT_PIN==1}]
		
		set clk_name [get_property REF_PIN_NAME [get_pins $clk_pin]]
		
		set clk_node_info "$clk_pin $clk_name $apropriate_node_bufg $apropriate_node_hrow"
		
		set clk_nodes [linsert $clk_nodes [llength $clk_nodes] $clk_node_info]
		}
	} else {
		return -code error {No Clk pins and appropriate nets found for the reference cell}
	}
	
	#if {[llength $clk_nodes]==1} {
		#return [join $clk_nodes]
	#} else {
		return $clk_nodes
	#}
}

proc get_ordered_net_nodes {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set net {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -net { 
				set net [lshift args]
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-net <net>]
						
			Description: Reorder the nodes of a route accurate related to the pips order.
						 
			Example:    get_ordered_net_nodes -net $net
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 
	 set pips [get_pips -of_objects [get_nets $net]]
	 set new_node_list {}
	 
	 for {set x 0} {$x<[llength $pips]} {incr x} {
		set node [get_nodes -of_objects [get_pips [lindex $pips $x]]]
		
		if {[lsearch -exact $new_node_list [lindex $node 1]]==-1} {
			set new_node_list [linsert $new_node_list [llength $new_node_list] [lindex $node 1]]
		}
		
		if {[lsearch -exact $new_node_list [lindex $node 0]]==-1} {
			set new_node_list [linsert $new_node_list [llength $new_node_list] [lindex $node 0]]
		}		

	 }
	 
	return $new_node_list
}

proc fix_clk_partpin_route {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set all_clk_nodes {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			 -clk_nodes {
				set all_clk_nodes [lshift args]			  
			  }
			  -help {
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
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-clk_nodes <CLK_NODES>]
						
			Description: This procedure fixes the route for clocking partition_pins. The clocking route will be partially fixed from global Buffer till the input of the reconfiguration Pblock.
						 
			Example:    fix_clk_partpin_route -clk_nodes {mb_st_i/mb_0_1/U0/rc_i/Clk CLK_BUFG_TOP_R_X87Y53/CLK_BUFG_BUFGCTRL0_O CLK_HROW_TOP_R_X87Y130/CLK_HROW_CK_HCLK_OUT_R0}
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 

	 
	 set black_box_list [get_cells -hierarchical -filter {BLACK_BOX==1}]
	 set all_rp_pblocks [get_pblocks -of_objects [get_cells $black_box_list]]
	 set coor_all_rp_pblocks [get_rect -pblocks $all_rp_pblocks -exact]
	 set center_clk_regions {}
	 set pblock_list {}

	 
	 set mid_tile [get_tiles -filter {TYPE=~CLK_BUFG_TOP*}]
	 set column_val [get_property COLUMN [get_tiles $mid_tile]]
	 set row_val [get_property ROW [get_tiles $mid_tile]]
	 set fpga_mid_point "$column_val $row_val"
	 set all_clk_reg_coor [get_clk_region_coordinates -all]
	 set pblock_in_cr [pblock_in_clk_region -pblocks $all_rp_pblocks]

	 
     ##get_pblocks with reference to reconfiguration cell (instance)
	for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		set pblock [lindex $black_box_list $x]
		set pblock_name [get_pblocks -of_objects [get_cells [lindex $black_box_list $x]]] 
		set pblock [linsert $pblock 1 $pblock_name]
		set pblock_list [linsert $pblock_list [llength $pblock_list] $pblock]
	}	 
	
	##get center clk_regions --->top first clock regions on buffer global top
	for {set x 0} {$x<[llength [get_clock_regions]]} {incr x} {
		set clk_region_coor [lindex $all_clk_reg_coor $x]
		if {[lindex $clk_region_coor 2]==[lindex $fpga_mid_point 1]} {
			set center_clk_regions [linsert $center_clk_regions [llength $center_clk_regions] [lindex $clk_region_coor 0]]
		}
	}
	
	##get top and bottom clockregions from center point
	set center_clk_row_idx [get_property ROW_INDEX [get_clock_regions [lindex $center_clk_regions 0]]]
	set filter_expr "COLUMN_INDEX==1 && ROW_INDEX>=$center_clk_row_idx"
	set cr_top_right [get_clock_regions -filter $filter_expr] 
	set filter_expr "COLUMN_INDEX==1 && ROW_INDEX<$center_clk_row_idx" 
	set cr_bottom_right [get_clock_regions -filter $filter_expr]
	set filter_expr "COLUMN_INDEX==0 && ROW_INDEX>=$center_clk_row_idx"
	set cr_top_left  [get_clock_regions -filter $filter_expr] 	
	set filter_expr "COLUMN_INDEX==0 && ROW_INDEX<$center_clk_row_idx"
	set cr_bottom_left [get_clock_regions -filter $filter_expr]	
	 
 	
	 ##reset clk partition_pins	 
	 for {set x 0} {$x<[llength $black_box_list]} {incr x} {
		set rp_pins [get_pins -of_objects [get_cells [lindex $black_box_list $x]]]
		
		for {set y 0} {$y<[llength $rp_pins]} {incr y} {
			set net_type [get_property TYPE [get_nets -of_objects [get_pins [lindex $rp_pins $y]]]]
			
			if {$net_type=="GLOBAL_CLOCK" || $net_type=="REGIONAL_CLOCK" || $net_type=="LOCAL_CLOCK"} {
				reset_property HD.PARTPIN_LOCS [get_pins [lindex $rp_pins $y]]
			}
		}
	 }
	 
	### relative coordinates of the reference HCLK Tile used

	
	
	###route the partially clk_nets 
	
	for {set w 0} {$w<[llength $all_clk_nodes]} {incr w} {
		set clk_nodes [lindex $all_clk_nodes $w]
		set first_node 0
		set ref_hclk_tile [lindex [split [lindex $clk_nodes 3] /] 0]
		set tile_in_cr [get_clock_regions -of_objects [get_tiles $ref_hclk_tile] -filter {COLUMN_INDEX==1}]
		set tile_in_cr [join [get_clk_region_coordinates -clk_regions $tile_in_cr]]
		set tile_row [get_property ROW [get_tiles $ref_hclk_tile]]
		set tile_column [get_property COLUMN [get_tiles $ref_hclk_tile]]
		set y_rel_right [expr {[lindex $tile_in_cr 2] - $tile_row}] 
		set x_rel_right [expr {[lindex $tile_in_cr 1] - $tile_column}]
		set first_node_from_bufg_routed 0
		
		for {set x 0} {$x<[expr {[llength $cr_top_right] + [llength $cr_bottom_right]}]} {incr x} {
			set horizontal_pb_in_cr {}
			##entscheiden ob im Top Design oder im Botton Design vom Floorplanning die CR Regionen anwählen
			if {$x>=[llength $cr_top_right]} {
				##cr regionen für bottom floorplan
				set new_x [expr {$x - [llength $cr_top_right]}]
				set cr_right [lindex $cr_bottom_right $new_x]
				set cr_left  [lindex $cr_bottom_left  $new_x]
				set first_node 0
			} else {
				##cr regionen für top floorplan
				set cr_right [lindex $cr_top_right $x]
				set cr_left  [lindex $cr_top_left  $x]		
			}
			
			##herausfinden welche Pblöcke in der gleichen clock Reihe liegen
			for {set z 0} {$z<[llength $pblock_in_cr]} {incr z} {
				set rp_cr [lindex $pblock_in_cr $z]
				if {[lsearch -exact $rp_cr $cr_right]!=-1 || [lsearch -exact $rp_cr $cr_left]!=-1} {
					set horizontal_pb_in_cr [linsert $horizontal_pb_in_cr [llength $horizontal_pb_in_cr] [lindex $rp_cr 0]]
				}
			}
			
			for {set y 0} {$y<[llength $horizontal_pb_in_cr]} {incr y} {
				 
				set rp_cr [lindex $horizontal_pb_in_cr $y]
				set rp_cr [join [pblock_in_clk_region -pblocks $rp_cr]]
				set filter_expr "REF_PIN_NAME==[lindex $clk_nodes 1]"
				set clk_net [get_nets -of_objects [get_pins -of_objects [get_cells -of_objects [get_pblocks [lindex $rp_cr 0]]] -filter $filter_expr]]		
				
				####für die ersten pblöcke durchlauf
				if {$first_node==0 && $first_node_from_bufg_routed==0} {
					set starting_node [lindex $clk_nodes 2]
					set first_node_from_bufg_routed 1
					set ending_node [split [lindex $clk_nodes 3] /]
					incr first_node
				}	elseif {$first_node==0 && $first_node_from_bufg_routed==1} {
					set fixed_nodes [get_ordered_net_nodes -net $clk_net]
					set starting_node [lindex $fixed_nodes 1]
					set ending_node [split [lindex $clk_nodes 3] /]
					incr first_node
				} 	else {
					set fixed_nodes [get_ordered_net_nodes -net $clk_net]
					set ending_tile [lindex [split $ending_node /] 0]
					set fnd_node_idx [lindex [lsearch -regexp -all $fixed_nodes $ending_tile.*] 0]
					set starting_node [lindex $fixed_nodes [expr {$fnd_node_idx -1}]]
					set ending_node [split [lindex $clk_nodes 3] /]
				}
				
				
				if {[lsearch -exact $rp_cr $cr_right]!=-1 || [lsearch -exact $rp_cr $cr_left]!=-1} {

					if {[lsearch -exact $rp_cr $cr_right]!=-1} {
						##in right side of cr
						set act_cr_coor [join [get_clk_region_coordinates -clk_regions $cr_right]]
						set y_val [expr {[lindex $act_cr_coor 2] - $y_rel_right}]
						set x_val [expr {[lindex $act_cr_coor 1] - $x_rel_right}]
					} else {
						##in left side of cr
						set act_cr_coor [join [get_clk_region_coordinates -clk_regions $cr_left]]
						set y_val [expr {[lindex $act_cr_coor 2] - $y_rel_right}]
						set x_val [expr {[lindex $act_cr_coor 3] + $x_rel_right}]
					}

					set filter_expr "COLUMN==$x_val && ROW==$y_val"
					set new_clk_tile [get_tiles -filter $filter_expr]
					set ending_clk_line [lindex $ending_node 1]				
					##differ in right r and left l clocklines of reference_clock_line
					set R_fnd [string last R $ending_clk_line]
					set L_fnd [string last L $ending_clk_line]
					if {$R_fnd>$L_fnd} {
						set idx_replace $R_fnd
					} else {
						set idx_replace $L_fnd
					}
					
					###routing the clock_lines
					if {[lsearch -exact $rp_cr $cr_right]!=-1} {
						set clock_line_side R
						set ending_clk_line [string replace $ending_clk_line $idx_replace $idx_replace $clock_line_side]
						set ending_node [join "$new_clk_tile $ending_clk_line" /]
						set routing_path [find_routing_path -from [get_nodes $starting_node] -to [get_nodes $ending_node]]
						set_property fixed_route $routing_path [get_nets $clk_net]
					} 
					
					if {[lsearch -exact $rp_cr $cr_left]!=-1} {
						set clock_line_side L
						set ending_clk_line [string replace $ending_clk_line $idx_replace $idx_replace $clock_line_side]
						set ending_node [join "$new_clk_tile $ending_clk_line" /]
						set routing_path [find_routing_path -from [get_nodes $starting_node] -to [get_nodes $ending_node]]
						set_property fixed_route $routing_path [get_nets $clk_net]					
					}	
				}
				
				
				
			}
		}
	}
}


proc get_StaticInstancePins {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments 
  #-----------------------------------------------------------------------------------------------------------------
 set net {}
 set static_instance {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -net {
			  set net [lshift args]
			  } -static_instance {
			  set static_instance [lshift args]
			  }
			  -help {
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
		return -code error {ERROR }
	  }
	  
	  if {[llength $net]==0} {
		return -code error {get_StaticInstancePins: No -net option is specified}
	  }
	  
	  if {[lsearch -regexp $net $static_instance.*]!=-1} {
		return -code error {get_StaticInstancePins: Only nets can be chosen which are connected to the static_instance not nets inside the static_region}
	  }
	  
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
			
			[-net  <net>]
			[-static_instance <static_instance>]
					
			Description: This procedure gives the static_instance_pin back which is connected to a rp_cell
						 					 
			Example:   get_StaticInstancePins -net  rp_net
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
	set end 0

	while {$end==0} {
		set pin [get_InstancePin -net $net -boundary_type upper]
		set net [get_nets -of_objects [get_pins $pin]]
		
		if {[llength [split $net /]]==2} {
			set end 1
			set top_net $net
			set connected_top_cell_pins [get_pins -of_objects [get_nets $top_net]]
		}
	} 
	set stat_idx [lsearch -regexp $connected_top_cell_pins $static_instance.*]
	set top_stat_cell_pin [lindex $connected_top_cell_pins $stat_idx]
	set connected_stat_net [get_nets -of_objects [get_pins $top_stat_cell_pin] -boundary_type lower]
	
	return $top_stat_cell_pin
}