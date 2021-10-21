
 ##Initializatioin of the developed DRC Function, so that these Function could be used in the Vivado Design Suite Enviroment
proc drc_init {} {
	delete_drc_check RLCPB-1 -quiet
	create_drc_check -name {RLCPB-1} -hiername {RLC.PBLOCK} -desc {PBlock Height check} -rule_body check_pblock_position -severity Error
    set_msg_config -id {RLCPB 1-1} -string "RLCPB" -new_severity "ERROR"
	set_msg_config -id {RLCPB 1-2} -string "RLCPB" -new_severity "ERROR"
	
	delete_drc_check RLCPB-2 -quiet
	create_drc_check -name {RLCPB-2} -hiername {RLC.PBLOCK} -desc {PBlock Placement check} -rule_body check_pblocks_size_compatibel_to_ibuf_location -severity Error
	set_msg_config -id {RLCPB 2-1} -string "RLCPB" -new_severity "ERROR"
	set_msg_config -id {RLCPB 2-2} -string "RLCPB" -new_severity "ERROR"
	
	delete_drc_check RLCPB-3 -quiet
	create_drc_check -name {RLCPB-3} -hiername {RLC.PBLOCK} -desc {Pblock Compatibility check} -rule_body check_pblock_compatibility -severity Error
	set_msg_config -id {RLCPB 3-1} -string "RLCPB" -new_severity "WARNING"
	
	delete_drc_check RLCIO-1 -quiet
	create_drc_check -name {RLCIO-1} -hiername {RLC.IO} -desc {IO number compatibility check} -rule_body check_io_number -severity Error
	set_msg_config -id {RLCIO 1-1} -string "RLCIO" -new_severity "ERROR"
	
	delete_drc_check RLCIO-2 -quiet
	create_drc_check -name {RLCIO-2} -hiername {RLC.IO} -desc {IO name compatibility check} -rule_body check_io_names -severity Error
	set_msg_config -id {RLCIO 2-1} -string "RLCIO" -new_severity "ERROR"	

	delete_drc_check RLCINF-1 -quiet
	create_drc_check -name {RLCINF-1} -hiername {RLC.INTERFACE} -desc {Relocation Interface  compatibility check of pblocks} -rule_body check_reloc_interface_compatibel -severity Error
	set_msg_config -id {RLCINF 1-1} -string "RLCINF" -new_severity "ERROR"	
	
}

 ##report all DRC Warnings and Errors depending on the DRC Funktion
proc report_reloc_drc {} {	
	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	
	##Implemented DRC--> Are referenced by an ID
	report_drc -check {RLCPB-1}
	report_drc -check {RLCPB-2}
	report_drc -check {RLCPB-3}
	report_drc -check {RLCIO-1}
	report_drc -check {RLCIO-2}
	report_drc -check {RLCINF-1}
}



 ##Check the height of the P-Blocks in the Floorplan
 proc check_pblock_position {} {
 	 ############################################################################################################
	 #																											#
	 ##Überprüfen ob alle pblocks die richtige Höhe haben --->nur auf größer 50 oder vielfache davon            #
	 #                                                                                      					#
	 ############################################################################################################
	
	global env	
	
	##loads the RelocSetup.tcl for defining FPGA Architectur
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}


	##determine all clock regions and there coordinates ->{X0Y0 0 155 85 105} {X1Y0 89 155 186 105} {X0Y1 0 103 85 53} {X1Y1 89 103 186 53} {X0Y2 0 51 85 1} {X1Y2 89 51 186 1}
	set clk_regions [get_clk_region_coordinates -all]
	set create_rect_clk_regions [get_clock_regions]


 ############CLK Regionen in one row
	 set clk_reg_nr {}
	 set expression {}
	 ##vios -->for violation
	 set vios {}
	 
	 ##determine the Cell indexes of the clock regions --> {X0Y0 0 0} {X0Y1 0 1} {X0Y2 0 2} {X1Y0 1 0} {X1Y1 1 1} {X1Y2 1 2}
	 for {set x 0} {$x<[llength $create_rect_clk_regions]} {incr x} {
		set expression "[lindex $create_rect_clk_regions $x] [get_name_coor [lindex $create_rect_clk_regions $x]]"
		set clk_reg_nr [linsert $clk_reg_nr $x $expression]		 
	 }
 
	set clk_reg_nr [lsort -integer -index 1 $clk_reg_nr]
	##determine highest clock row
	set clk_reg_row [expr {[lindex [lindex $clk_reg_nr [expr {[llength $clk_reg_nr] - 1}]] 1] - [lindex [lindex $clk_reg_nr 0] 1] + 1}]	
	##get all pblocks and there coordinates --> {pblock_1 138 51 147 1} {pblock_2 138 103 147 53}
	set all_pblocks [get_rect -pblocks [get_pblocks ] -exact]
 
	 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
		set block_range 0
		for {set y 0} {$y<[llength $clk_regions]} {incr y} {
			##check whether pblock has the same heigth of clock region
			if {[lindex [lindex $all_pblocks $x] 2]==[lindex [lindex $clk_regions $y] 2]} {
				incr block_range
			}
			if {[lindex [lindex $all_pblocks $x] 4]==[lindex [lindex $clk_regions $y] 4] } {
				incr block_range
			}
		}

		 if {$block_range<[expr {2*$clk_reg_row}]} {
		   ## create output violation in the console
			set error_detect "RLCPB 1-1: Pblock [lindex [lindex $all_pblocks $x] 0] of cell %ELG not fully allocate the needed height for reconfiguration blocks"
			set vio [ create_drc_violation -name {RLCPB-1} -msg $error_detect -severity ERROR [get_cells -of_objects [get_pblocks [lindex [lindex $all_pblocks $x] 0]]]]
			lappend vios $vio
		 }
	 }
	 
	 if {[llength $vios]>0} {
		##returns violations to the report_drc function of Vivado
		return -code error $vios
	 } else {
		return {}
	 }
 }
 
 ##check the compatibility of the footprint of the pblock
 proc check_pblock_compatibility {} {
	 ##############################################################################################################
	 #																						 					  #
	 ##Überprüfen ob pblöcke kompatibel zueinander -->abhängig von CLB anordnung innerhalb der Blöcke             #
	 #                                                                                     						  #
	 ##############################################################################################################
	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	 
	set all_pblocks {} 
	set vios {}
	set vios_error {}
	set fully_comp 0 
	
	 set all_pblocks [get_pblocks]
	 
	 ##get tiles inside the pblocks
	 set pblock_tiles_included [get_rect -pblocks [get_pblocks $all_pblocks] -included_tiles]
	 set pblock_compatibility_list {}
	 
	 ## "---------------------------------------------------------------COMPATIBILITY CHECK OF PBLOCKS------------------------------------------------------------"	
	 
	 ##each pblock is compared by his footprint 
	 for {set x 0} {$x<[llength $pblock_tiles_included]} {incr x} {
		set pb_act_name [lindex [lindex $pblock_tiles_included $x] 0]
		##actual pblock
		set act_pb $pb_act_name
		set pb_act [lindex $pblock_tiles_included $x]
		set pb_compared [lremove_element $pblock_tiles_included [search_part_list $pblock_tiles_included $pb_act_name]]
		
		for {set y 0} {$y<[llength $pb_compared]} {incr y} {
			set pb_act_compared [lindex $pb_compared $y]
			##compare pblock to compare with actual pblock
			set comp_pb [lindex [lindex $pb_compared $y] 0]
			
			if {[llength $pb_act_compared]<[llength $pb_act]} {
				set end_compare [llength $pb_act_compared]
			} else {
				set end_compare [llength $pb_act]
			}
			set compatibel 0
			set down_clb_type 0
			set up_clb_type 0 
			set logical_type 0
			
			
			for {set z 1} {$z<$end_compare} {incr z} {
				##check all tile types of the pblocks
				set act_tile [lindex $pb_act $z]
				set comp_tile [lindex $pb_act_compared $z]
				set is_count 0
				
				###Different Tiles which are compatibel
				if {$act_tile=="CLBLL_L"} {
					set act_tile_2 "CLBLM_L"
				} elseif {$act_tile=="CLBLM_L"} {
					set act_tile_2 "CLBLL_L"
				} elseif {$act_tile=="CLBLL_R"} {
					set act_tile_2 "CLBLM_R"
				} elseif {$act_tile=="CLBLM_R"} {
					set act_tile_2 "CLBLL_R"
				} elseif {$act_tile=="DSP_L"} {
					set act_tile_2 "BRAM_L"
				} elseif {$act_tile=="DSP_R"} {
					set act_tile_2 "BRAM_R"
				} elseif {$act_tile=="BRAM_R"} {
					set act_tile_2 "DSP_R"
				} elseif {$act_tile=="BRAM_L"} {
					set act_tile_2 "DSP_L"
				} elseif {$act_tile=="BRAM_INT_INTERFACE_L"} {
					set act_tile_2 "INT_INTERFACE_L"
				} elseif {$act_tile=="BRAM_INT_INTERFACE_R"} {
					set act_tile_2 "INT_INTERFACE_R"
				} elseif {$act_tile=="INT_INTERFACE_R"} {
					set act_tile_2 "BRAM_INT_INTERFACE_R"
				} elseif {$act_tile=="INT_INTERFACE_L"} {
					set act_tile_2 "BRAM_INT_INTERFACE_L"
				}  else {
					set act_tile_2 " "
				}
								
				if {$comp_tile==$act_tile} {
					incr compatibel
					incr is_count 
				}
				##check for compatibility
				if {$act_tile=="BRAM_INT_INTERFACE_L" || $act_tile=="BRAM_INT_INTERFACE_R" || $act_tile=="INT_INTERFACE_R" || $act_tile=="INT_INTERFACE_L"} {
					if {$is_count==0} {
						incr compatibel
					}
				}
					
				if {$act_tile=="CLBLL_L" || $act_tile=="CLBLM_L" || $act_tile=="CLBLL_R" || $act_tile=="CLBLM_R"} {
					##check whether compared tile is logical compatibel with actual tile
					if {$comp_tile==$act_tile_2} {
						if {$is_count==0} {
							incr compatibel
						} 
						
						if {$comp_tile=="CLBLM_L" || $comp_tile=="CLBLM_R"} {
							##check downwards compatibility
							incr down_clb_type
						} else {
							##check upward compatibility
							incr up_clb_type
						}
					}
				}
				
				##check compatibility of DSP and BRAM Ressources whether on same location
				if {$act_tile=="DSP_R" || $act_tile=="DSP_L" || $act_tile=="BRAM_L" || $act_tile=="BRAM_R"} {
					if {$is_count==0} {
						incr compatibel
					}
					
					if {$comp_tile==$act_tile_2} {
						incr logical_type
					}
				}

				
			}

				##return of the violations and compatibility list for the output message in the console
			if {$compatibel==[expr {$end_compare - 1}] && [llength $pb_act]<=[llength $pb_act_compared] && $down_clb_type==0 && $up_clb_type==0 && $logical_type==0} {
				puts "															$act_pb fully compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) fully compatibel with $comp_pb (%ELG)"
				incr fully_comp
			} elseif {$compatibel==[expr {$end_compare - 1}] && [llength $pb_act]<=[llength $pb_act_compared] && $up_clb_type!=0 && $down_clb_type==0 && $logical_type==0} {
				puts "----------------------------------------------------------->upward compatibel"
				#puts "															$act_pb not compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) not compatibel with $comp_pb (%ELG)"
			} elseif {$compatibel==[expr {$end_compare - 1}] && [llength $pb_act]<=[llength $pb_act_compared] && $down_clb_type!=0 && $up_clb_type!=0 && $logical_type==0} {
				puts "															$act_pb downward compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) downward compatibel with $comp_pb (%ELG)"
			} elseif {$compatibel==[expr {$end_compare - 1}] && [llength $pb_act]<=[llength $pb_act_compared] && $down_clb_type==0 && $up_clb_type==0 && $logical_type!=0} {
				puts "															$act_pb logical compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) logical compatibel with $comp_pb (%ELG)"
			} elseif {$compatibel==[expr {$end_compare - 1}] && [llength $pb_act]<=[llength $pb_act_compared] && $down_clb_type!=0 && $up_clb_type==0 && $logical_type!=0} {
				puts "															$act_pb logical downward compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) logical downward compatibel with $comp_pb (%ELG)"
			} else {
				puts "															$act_pb not compatibel with $comp_pb"
				set comp_result_vio "RLCPB 3-1: $act_pb (Cell: [get_cells -of_objects [get_pblocks $act_pb] -quiet]) not compatibel with $comp_pb (%ELG)"
				set vio [ create_drc_violation -name {RLCPB-3} -msg $comp_result_vio -severity Error [get_cells -of_objects [get_pblocks $comp_pb] -quiet]]
				lappend vios_error $vio
			}
			
			#set pblock_compatibility_list [linsert $pblock_compatibility_list [llength $pblock_compatibility_list] $comp_result]
				set vio [ create_drc_violation -name {RLCPB-3} -msg $comp_result_vio -severity Warning [get_cells -of_objects [get_pblocks $comp_pb] -quiet]]
				lappend vios $vio
		}
	 }


	##determine whether the messages are violations or warnings
	if {[llength $vios_error]>0 && [llength $vios_error]==[llength $all_pblocks] && $fully_comp!=[llength $all_pblocks]} {
		reset_msg_config -id {RLCPB 3-1} -string "RLCPB" -default_severity -quiet
		set_msg_config -id {RLCPB 3-1} -string "RLCPB" -new_severity "ERROR" 
		return -code error $vios_error
	} elseif {[llength $vios]>0 && [llength $vios_error]<[llength $all_pblocks] && $fully_comp!=[llength $all_pblocks]} {
		reset_msg_config -id {RLCPB 3-1} -string "RLCPB" -default_severity -quiet
		set_msg_config -id {RLCPB 3-1} -string "RLCPB" -new_severity "WARNING" 
		return -code error $vios
	}  else {
		return {}
	}
 }

 ##determine when io-buffers are in the design, if pblocks have certain distance to them
 ## because LUT cells have to be place besides the io-pad to avoid feed-throughs
 proc check_pblocks_size_compatibel_to_ibuf_location {} {
 
 	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	 #############################################################################################################################################################
	 #																						 					  												 #
	 ##Überprüfen ob es Leitungen gibt die außerhalb des Zynq Signalverknüpfungen mit dem Design existieren   und daraufhin pblocks richtig positioniert sind    #
	 #                                                                                     						  												 #
	 ############################################################################################################################################################# 
	 
	set all_pblocks [get_pblocks ]
	set all_rp_cells [get_cells -hierarchical -filter {BLACK_BOX==TRUE}]
	##determine all pins
	set all_pins [llength [get_pins -of_objects [get_cells $all_rp_cells]]]
	 
	##get clk region coordinate of one clock region -->{X0Y0 0 155 85 105}
	set clk_regions [lindex [get_clk_region_coordinates -all] 0]
	set slice_position [get_slices -side RIGHT -start 0 -search_in_row 1 -slice_column]
	set filter_expr "COLUMN==$slice_position && ROW>=[lindex $clk_regions 4] && ROW<=[lindex $clk_regions 2] && TYPE=~CLB*"
	set slices_nr_column [expr {[llength $GLOBAL_PBLOCK::slice_lut] * [llength [get_sites -of_objects [get_tiles -filter $filter_expr]]]}]
	 
	set multiple_clbs [expr {round (double ($all_pins/$slices_nr_column))}]	
	
	
	
	set pblock_fences_all {}

	 set rect_all_pblocks [get_rect -pblocks $all_pblocks -exact]
	 set ibuf_cells [get_cells -hierarchical -filter {primitive_subgroup==ibuf}]
	 set false_placement_pblock_list {}
	 set vio {}
	 set vios {}
	 
	 if {[llength $ibuf_cells]!=0} {
		 ##get the buffer location of input buffer  through the LOC property-->ibuffer are fixed placed in the io-pad tile
		 set ibuf_locs  [get_property LOC [get_cells $ibuf_cells]]
		 set column_ibuf_locs [get_property COLUMN [get_tiles -of_objects [get_sites $ibuf_locs]]]
		 
		 set ibuf_position_column {}
		 
		 for {set x 0} {$x<[llength $column_ibuf_locs]} {incr x} {
			if {[search_String $ibuf_position_column [lindex $column_ibuf_locs $x] 1]==-1} {
				set ibuf_position_column [linsert $ibuf_position_column [llength $ibuf_position_column] [lindex $column_ibuf_locs $x]]
			}
		 }
		 
		 set ibuf_in_static_region {}
		 set ibuf_position {}
		 
		 ###get minimum distance from global ibuf cells depending on the sight where they placed in the floorplan (which io bank)
		 for {set x 0} {$x<[llength $ibuf_position_column]} {incr x} {
			##determines ibuf_position to control the associated interface tiles
			if {[lindex $ibuf_position_column $x]==[lindex $GLOBAL_PBLOCK::x_range 1]} {
				set side LEFT
				set ibuf_in_static_region [linsert $ibuf_in_static_region [llength $ibuf_in_static_region] RIGHT]
				set ibuf_position [linsert $ibuf_position [llength $ibuf_position] RIGHT]
				set add  1
			} else {
				set side RIGHT
				set ibuf_in_static_region [linsert $ibuf_in_static_region [llength $ibuf_in_static_region] LEFT]
				set ibuf_position [linsert $ibuf_position [llength $ibuf_position] LEFT]
				set add  -1
			}
			set clb_for_ibuf_glob_cells [get_slices -side $side -start [lindex $ibuf_position_column $x] -search_in_row [lindex $GLOBAL_PBLOCK::y_range 1] -slice_column]
			set ibuf_position [linsert $ibuf_position [llength $ibuf_position] $clb_for_ibuf_glob_cells]
			##determines where the LUT cells for the io nets have to be placed 
			set minimum_fence [get_slices -side $side -start [expr {$clb_for_ibuf_glob_cells - $add}] -search_in_row [lindex $GLOBAL_PBLOCK::y_range 1] -slice_column]
			set ibuf_in_static_region [linsert $ibuf_in_static_region [llength $ibuf_in_static_region] $minimum_fence]	
		 }
		 
	    set clb_cnt 0 
		 
		for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
			set act_pb [get_rect -pblocks [lindex $all_pblocks $x] -exact]
			
			##determine which interface side could be used			
				
			if {[lsearch -exact $ibuf_position LEFT]!=-1} {
				##emulate interface position of the pblock 
				set left_occupied_column [lindex $ibuf_position [expr {[lsearch -exact $ibuf_position LEFT] + 1}]]
				set left_fence_column  [search_fence -pblock $act_pb -side LEFT -return_fence_column]
				
				set static_cell_position_column_left $left_fence_column
				while {$clb_cnt!=[expr {$multiple_clbs+2}]} {
					set static_cell_position_column_left [get_slices -side LEFT -start [expr {$static_cell_position_column_left - 1}] -search_in_row [lindex $GLOBAL_PBLOCK::y_range 1] -slice_column]
					incr clb_cnt
				}
				
				##determeine whether position of ibuf has same position like the found second clb type for the interface side
				if {$static_cell_position_column_left<=$left_occupied_column} {
					set error_detect "RLCPB 2-2: Left Pblock side of pblock [lindex [lindex $all_pblocks $x] 0] of cell %ELG has to be moved to the right side "			
				}
			}

			if {[lsearch -exact $ibuf_position RIGHT]!=-1} {
			    ##emulate interface position of the pblock 
				set right_occupied_column [lindex $ibuf_position [expr {[lsearch -exact $ibuf_position RIGHT] + 1}]]
				set right_fence_column [search_fence -pblock $act_pb -side RIGHT -return_fence_column]
				
				set static_cell_position_column_right $right_fence_column
				while {$clb_cnt!=[expr {$multiple_clbs+2}]} {
					set static_cell_position_column_right [get_slices -side RIGHT -start [expr {$static_cell_position_column_right + 1}] -search_in_row [lindex $GLOBAL_PBLOCK::y_range 1] -slice_column]
					incr clb_cnt
				}
				##determeine whether position of ibuf has same position like the found second clb type for the interface side
				if {$static_cell_position_column_right>=$right_occupied_column} {
					set error_detect "RLCPB 2-2: Right Pblock side of pblock [lindex [lindex $all_pblocks $x] 0] of cell %ELG has to be moved to the left side "			
				}			
			}	
		}		 
	
		 
		 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
			set rect_pblock [lindex $rect_all_pblocks $x]
			set pblock_fence {}
			set pblock_fence [linsert $pblock_fence 0 [lindex $rect_pblock 0]]
					
			for {set y 0} {$y<2} {incr y} {
				if {$y==0} {
					set side LEFT
				} else {
					set side RIGHT
				}
				set pblock_fence [linsert $pblock_fence [llength $pblock_fence] $side]
				
				set fence 1
				set i 1				
				while {$fence} {
					if {$y==0} {
						set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {[lindex $rect_pblock 1] - $i}] && TILE_TYPE!=NULL"
						if {[expr {[lindex $rect_pblock 1] - $i}]<[lindex $GLOBAL_PBLOCK::x_range 0]} {
							set fence 0
							set fence_column [lindex $GLOBAL_PBLOCK::x_range 0]
							break
						}
					} else {
						set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {[lindex $rect_pblock 3] + $i}] && TILE_TYPE!=NULL"	
						if {[expr {[lindex $rect_pblock 3] + $i}]>[lindex $GLOBAL_PBLOCK::x_range 1]} {
							set fence 0
							set fence_column [lindex $GLOBAL_PBLOCK::x_range 1]
							break
						}						
					}

					if {$fence!=0} {
						set act_tile_type [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr]] 0]
					}
					if {[search_String $GLOBAL_PBLOCK::iso_fence_types  $act_tile_type 1]!=-1 && $fence!=0} {
						if {$side=="LEFT"} {
							set fence_column [expr {[lindex $rect_pblock 1] - $i}]			
						} else {
							set fence_column [expr {[lindex $rect_pblock 3] + $i}]				
						}

						set fence 0			
					}
						incr i			
				}	
				set pblock_fence [linsert $pblock_fence [llength $pblock_fence] $fence_column]
			}
		set pblock_fences_all [linsert $pblock_fences_all [llength $pblock_fences_all] $pblock_fence]
			
		 }
		 
		###now check that fence borders of pblock are smaller then minimum fence distance from global ibuf cells
		set no_left_border 0 
		set no_right_border 0

		
		if {[search_String $ibuf_in_static_region LEFT 1]!=-1} {
			set left_ibuf_border [[lindex $ibuf_in_static_region [expr {[search_String $ibuf_in_static_region LEFT 1] + 1}]]
		} else {
			set no_left_border 1
		}
		
		if {[search_String $ibuf_in_static_region RIGHT 1]!=-1} {
			set right_ibuf_border [lindex $ibuf_in_static_region [expr {[search_String $ibuf_in_static_region RIGHT 1] + 1}]]
		} else {
			set no_right_border 1
		}
		
		##check the x coordinates of emulated tile to place LUT STAT cells and the x coordinates of lut cells of the io-nets
		for {set x 0} {$x<[llength $pblock_fences_all]} {incr x} {	
			set left_incompatibel 0 
			set right_incompatibel 0
			set  act_pb_fences [lindex $pblock_fences_all $x]
			##check left side
			if {$no_left_border==0} {
				set left_pb_fence [lindex $act_pb_fences [expr {[search_String $act_pb_fences LEFT 1] + 1}]]
				if {$left_pb_fence<=$left_ibuf_border || $left_ibuf_border==-1} {
					incr left_incompatibel
				}
				
			}
			##check right side
			if {$no_right_border==0} {
				set right_pb_fence [lindex $act_pb_fences [expr {[search_String $act_pb_fences RIGHT 1] + 1}]]
				if {$right_pb_fence>=$right_ibuf_border || $right_ibuf_border==-1} {
					incr right_incompatibel
				}
			}
			
			##generate ouput messages for the console when violation are present
			if {$left_incompatibel!=0} {
				set left_incomp_result "RLCPB 2-1: Left pblock side of [lindex $act_pb_fences 0] (CELL: %ELG) is not properly fixed. Move left edge of pblock [lindex $act_pb_fences 0] in right direction for consistent Fence"
				set vio [ create_drc_violation -name {RLCPB-2} -msg $left_incomp_result -severity ERROR [get_cells -of_objects [get_pblocks [lindex $all_pblocks $x]] -quiet]]
				lappend vios $vio
			}

			if {$right_incompatibel!=0} {
				set right_incomp_result "RLCPB 2-1: Right pblock side of [lindex $act_pb_fences 0] (CELL: %ELG)  is not properly fixed. Move right edge of pblock [lindex $act_pb_fences 0] in left direction for consistent Fence"
				set vio [ create_drc_violation -name {RLCPB-2} -msg $right_incomp_result -severity ERROR [get_cells -of_objects [get_pblocks [lindex $all_pblocks $x]] -quiet]]
				lappend vios $vio
			}			
		}	 
	 } else {
		return {}
	 }
	 puts "vios: $vios"
	 if {[llength $vios]>0} {
		return -code error $vios
	 } else {
		return {}
	 }
 }
 
 ##check the number of the ios of reconfigurable hardware modules
 proc check_io_number {} {
 	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	
	 set all_pblocks [get_pblocks]
	 set all_rp_cells [get_cells -hierarchical -filter {BLACK_BOX==TRUE}]
	 set all_rp_ios {}
	 
	 ##for violation
	 set vio {}
	 set vios {}
	 
	 for {set x 0} {$x<[llength $all_rp_cells]} {incr x} {
		set rp_ios     [get_pins  -of_objects [get_cells [lindex $all_rp_cells $x]]]
		set rp_pb_name [get_property PBLOCK [get_cells [lindex $all_rp_cells $x]]]
		set rp_ios [linsert $rp_ios 0 $rp_pb_name]
		set rp_ios [linsert $rp_ios 1 [lindex $all_rp_cells $x]]
		set rp_ios [join $rp_ios " "]
		set all_rp_ios [linsert $all_rp_ios [llength $all_rp_ios] $rp_ios]
	 }
	 
	 ##check if same amount of ios on all pblocks
	 
	 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
		set act_pb_length [expr {[llength [lindex $all_rp_ios $x]] - 2}]
		set comp_pb $all_rp_ios
		for {set y 0} {$y<[llength $all_pblocks]} {incr y} {
			set comp_pb_length [expr {[llength [lindex $all_rp_ios $y]] - 2}]
			if {$act_pb_length!=$comp_pb_length} {
				#puts "IO number of cell [lindex [lindex $all_rp_ios $x] 1] and [lindex [lindex $all_rp_ios $y] 1] are not the same"
				set  io_nr_incomp_vios "RLCIO 1-1: IO NUMBER INCOMPATIBEL: IO number of cell [lindex [lindex $all_rp_ios $x] 1] and  %ELG are not the same"
				set vio [ create_drc_violation -name {RLCIO-1} -msg $io_nr_incomp_vios -severity ERROR [lindex [lindex $all_rp_ios $y] 1]]
				lappend vios $vio
			}
			
		}
	 } 
	 
	 if {[llength $vios]>0} {
		return -code error $vios
	 } else {
		return 0
	 }
 }
 
 ##check that reconfigurabel hardware modules have same io names
 proc check_io_names {} {
 	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	
 	 set all_pblocks [get_pblocks]
	 set all_rp_cells [get_cells -hierarchical -filter {BLACK_BOX==TRUE}]
	 set all_rp_ios {}
	 set vio {}
	 set vios {}
	 
	 ##for violation
	 set io_nr_incompatibel {}
	 set io_names_incompatibel {}
	 set interface_incompatibel {}
	 set all_interface_incompatibel {}
	 set interface_incompatibel_full {}
	 
	 
	 for {set x 0} {$x<[llength $all_rp_cells]} {incr x} {
		set rp_ios     [get_pins  -of_objects [get_cells [lindex $all_rp_cells $x]]]
		set rp_pb_name [get_property PBLOCK [get_cells [lindex $all_rp_cells $x]]]
		set rp_ios [linsert $rp_ios 0 $rp_pb_name]
		set rp_ios [linsert $rp_ios 1 [lindex $all_rp_cells $x]]
		set rp_ios [join $rp_ios " "]
		set all_rp_ios [linsert $all_rp_ios [llength $all_rp_ios] $rp_ios]
	 }
	 
	 ##check if same io names ------>needed for relocation
	 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
		set act_pb_length [expr {[llength [lindex $all_rp_ios $x]] - 2}]
		set comp_pb $all_rp_ios
		for {set y 0} {$y<[llength $all_pblocks]} {incr y} {
			set comp_pb_length [expr {[llength [lindex $all_rp_ios $y]] - 2}]
			for {set z 2} {$z<[expr {[llength [lindex $all_rp_ios $x]] - 2}]} {incr z} {
				set act_pb_io_name [get_property REF_PIN_NAME [get_pins [lindex [lindex $all_rp_ios $x] $z]]]
				set comp_pb_io_name [get_property REF_PIN_NAME [get_pins [lindex [lindex $all_rp_ios $y] $z]]]
				if {$act_pb_io_name!=$comp_pb_io_name} {
					#puts "IOs of cell [lindex [lindex $all_rp_ios $x] 1] and [lindex [lindex $all_rp_ios $y] 1] have different PIN Names"
					set io_names_vios "RLCIO 2-1: IO NAMES INCOMPATIBEL: IOs of cell [lindex [lindex $all_rp_ios $x] 1] and %ELG have different PIN Names"
					set vio [ create_drc_violation -name {RLCIO-2} -msg $io_names_vios -severity ERROR [lindex [lindex $all_rp_ios $y] 1]]
					lappend vios $vio
				}
			}
			
		}
	 }
	 
	 if {[llength $vios]>0} {
		return -code error $vios
	 } else {
		return {}
	 }
 }
  
 ##check the compatibility of the interface sides of the partitions 
 proc check_reloc_interface_compatibel {} {
 	global env	
	
	if {$GLOBAL_RELOC_STATE::sourced_RelocSetup==0} {
		source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
		set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	}
	 ###############################################################################################################################
	 #																						 					                   #
	 ##Überprüfen ob pblöcke kompatibel dafür sind um einheitliche Schnittstellen für die Rellocation zu gewährleisten            #
	 #                                                                                     						                   #
	 ############################################################################################################################### 
	 
	 set all_pblocks [get_pblocks]
	 set all_rp_cells [get_cells -hierarchical -filter {BLACK_BOX==TRUE}]
	 ##determine all pins
	 set all_pins [llength [get_pins -of_objects [get_cells $all_rp_cells]]]
	 
	 ##get clk region coordinate of one clock region -->{X0Y0 0 155 85 105}
	 set clk_regions [lindex [get_clk_region_coordinates -all] 0]
	 set slice_position [get_slices -side RIGHT -start 0 -search_in_row 1 -slice_column]
	 set filter_expr "COLUMN==$slice_position && ROW>=[lindex $clk_regions 4] && ROW<=[lindex $clk_regions 2] && TYPE=~CLB*"
	 set slices_nr_column [expr {[llength $GLOBAL_PBLOCK::slice_lut] * [llength [get_sites -of_objects [get_tiles -filter $filter_expr]]]}]
	 
	 set multiple_clbs [expr {round (double ($all_pins/$slices_nr_column))}]
	 
	 set pin_cnt [llength $all_pins]
	 set vio {}
	 set vios {}
	 set placement_vios 0
	 set inf_incompatibel 0
	 #set all_rp_ios {}
	 
	 set interface_incompatibel {}
	 set all_interface_incompatibel {}
	 set interface_incompatibel_full {}
	 
	 
	 ##check pblock left and right edge compatibility

	 set pb_coor_all [get_rect -pblocks $all_pblocks -exact -tile_type_borders]
	 set left_interface_tiles {}
	 set right_interface_tiles {}
	 set pblock_tile_types {}
	 set left_already_checked_interfaces {}
	 set right_already_checked_interfaces {}
	 
	 
	 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
		set border_tiles [lindex [lindex $pb_coor_all $x] 0]
		set rect_pblock [lindex $pb_coor_all $x]
		##search fence tiles
		set left_fence_tiles  [search_fence -pblock [lindex $pb_coor_all $x] -side LEFT -return_all]
		set right_fence_tiles [search_fence -pblock [lindex $pb_coor_all $x] -side RIGHT -return_all]
		
		set border_tile_left   [lindex $left_fence_tiles [expr {[llength $left_fence_tiles] - 1}]]
		set border_tile_right  [lindex $right_fence_tiles [expr {[llength $right_fence_tiles] - 1}]]
		
		
		for {set y 0} {$y<2} {incr y} {
		
			if {$y==0} {
				set side LEFT
			} else {
				set side RIGHT
			}
		
			set clb_cnt 0
			set i 1 
			set tile_type {}
			set tiles_order_from_pb_border {}
			
			##get clb column of stat lut-placement depending of the number of io-pins
			while {$clb_cnt!=[expr {$multiple_clbs+2}]} {
				if {$side=="LEFT"} {
					set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {[lindex $left_fence_tiles 1] - $i}] && TILE_TYPE!=NULL"	
					if {[expr {[lindex $left_fence_tiles 1] - $i}]<[lindex $GLOBAL_PBLOCK::x_range 0]} {
						set clb_cnt 2
						set fence_column [lindex $GLOBAL_PBLOCK::x_range 0]						
						break
					}
				} else {
					set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {[lindex $right_fence_tiles 1] + $i}] && TILE_TYPE!=NULL"				
					if {[expr {[lindex $right_fence_tiles 1] + $i}]>[lindex $GLOBAL_PBLOCK::x_range 1]} {
						set clb_cnt 2 
						set fence_column [lindex $GLOBAL_PBLOCK::x_range 1]
						break
					}					
				}
				
				##second clb found 
				if {$clb_cnt!=2} {
					##get tiles from fence to found clb
					set tile_type [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr]] 0]
					set tiles_order_from_pb_border [linsert $tiles_order_from_pb_border [llength $tiles_order_from_pb_border] $tile_type] 
				}
				for {set comp 0} {$comp<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr comp} {
					set clb_comp_list [lindex $GLOBAL_PBLOCK::compatibel_clbs $comp]
					if {[search_String $clb_comp_list [lindex $tile_type 0] 1]!=-1 && $clb_cnt!=2} {
						if {$side=="LEFT"} {
							set fence_column [expr {[lindex $rect_pblock 1] - $i}]			
						} else {
							set fence_column [expr {[lindex $rect_pblock 3] + $i}]				
						}
						incr clb_cnt			
					}	
				}
				incr i
			}
			
			##get tile types of the interfaces of the pblock 
			if {$side=="LEFT"} {
				for {set pb 0} {$pb<[llength $tiles_order_from_pb_border]} {incr pb} {
				set tile_pb_border [lindex $tiles_order_from_pb_border $pb]
				if {[search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] $tile_pb_border 1]!=-1 || [search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] $tile_pb_border 1]!=-1} {
					set border_tile_left [linsert $border_tile_left [llength $border_tile_left] $tile_pb_border]
					set border_tile_left [join $border_tile_left " "]
				}
				}
			} else {
				for {set pb 0} {$pb<[llength $tiles_order_from_pb_border]} {incr pb} {
				set tile_pb_border [lindex $tiles_order_from_pb_border $pb]
				if {[search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] $tile_pb_border 1]!=-1 || [search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] $tile_pb_border 1]!=-1} {
				set border_tile_right [linsert $border_tile_right [llength $border_tile_right] $tile_pb_border]
				set border_tile_right [join $border_tile_right " "]
				}
				}
			}
			
		}
		
		set border_tiles [linsert $border_tiles [llength $border_tiles] $border_tile_left]
		set border_tiles [linsert $border_tiles [llength $border_tiles] $border_tile_right]
		
		set pblock_tile_types [linsert $pblock_tile_types [llength $pblock_tile_types] $border_tiles]
		
	 }
	 ##interface tile types left and right of pblocks --> {pblock_1 {CLBLL_R CLBLM_L CLBLL_R} {CLBLM_L CLBLM_R CLBLM_L}} {pblock_2 {CLBLL_R CLBLM_L CLBLL_R} {CLBLM_L CLBLM_R CLBLM_L}}
	 set pblock_tile_types_compare $pblock_tile_types
	 set inf_left_placement_not_possible 0
	 set inf_right_placement_not_possible 0
	 ##check left and right interface tile types of pblock of all pblocks 
	 for {set side 1} {$side<3} {incr side} {
		 
		 for {set x 0} {$x<[llength $all_pblocks]} {incr x} {
		  set pblock_act_tile [lindex [lindex $pblock_tile_types $x] 0]
		  set pblock_act_tile_types [lindex [lindex $pblock_tile_types $x] $side]
		  set pblock_act_clb_idx  [lsearch -all $pblock_act_tile_types CLB*]
		  
		  ##minimum tile types into interface side is 2
		  if {[llength $pblock_act_clb_idx]>=2} {
		  set pblock_act_clb_tile_types {}
		  
		  ##get clb tile types
		  for {set idx_clb 0} {$idx_clb<[llength $pblock_act_clb_idx]} {incr idx_clb} {
			set pblock_act_clb_tile_types [linsert $pblock_act_clb_tile_types [llength $pblock_act_clb_tile_types] [lindex $pblock_act_tile_types [lindex $pblock_act_clb_idx $idx_clb]]]
		  }
		  set pblock_act_tile [linsert $pblock_act_tile 1 $pblock_act_clb_tile_types]
		  
		 # puts "pblock_act_tile: $pblock_act_tile"
		  
		  ###compare interface side of block with other pblock interface sides
		  for {set y 0} {$y<[llength $all_pblocks]}	{incr y} {
			set pblock_comp_tile [lindex [lindex $pblock_tile_types_compare $y] 0]
		    set pblock_comp_tile_types [lindex [lindex $pblock_tile_types_compare $y] $side]
		    set pblock_comp_clb_idx  [lsearch -all $pblock_comp_tile_types CLB*]
			set already_incompatibel 0
			
			##minimum tile types in interface side is 2
			if {[llength $pblock_comp_clb_idx]>=2} {
				set pblock_comp_clb_tile_types {}
			  
			  ##get clb tile types
				for {set idx_clb 0} {$idx_clb<[llength $pblock_comp_clb_idx]} {incr idx_clb} {
				  set pblock_comp_clb_tile_types [linsert $pblock_comp_clb_tile_types [llength $pblock_comp_clb_tile_types] [lindex $pblock_comp_tile_types [lindex $pblock_comp_clb_idx $idx_clb]]]
				}
				set pblock_comp_tile [linsert $pblock_comp_tile 1 $pblock_comp_clb_tile_types]	
				#puts "pblock_comp_tile: $pblock_comp_tile"
				
				##compare tile types are identical of clb types-->important for same interface side
				for {set z 0} {$z<[llength [lindex [lindex $pblock_tile_types $x] 1]]} {incr z} {
					set act_tile [lindex [lindex $pblock_act_tile 1] $z] 
					set comp_tile [lindex [lindex $pblock_comp_tile 1] $z]
					set fnd -1 
					
					for {set comp 0} {$comp<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr comp} {
						if {[search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs $comp] $act_tile 1]!=-1} {
								set fnd $comp
								break
						}
					}
					
					if {$fnd!=-1} {
						if {[search_String [lindex $GLOBAL_PBLOCK::compatibel_clbs $fnd] $comp_tile 1]==-1} {
							if {$already_incompatibel==0} {
								if {$side==1} {
									set interface_vios "RLCINF 1-1: LEFT INTERFACE SIDE INCOMPATIBEL: of pblock [lindex [lindex $pblock_tile_types $x] 0] (CELL: [get_cells -of_objects [get_pblocks [lindex [lindex $pblock_tile_types $x] 0]]  -quiet]) and pblock [lindex [lindex $pblock_tile_types_compare $y] 0] (CELL: %ELG)"
								} else {
									set interface_vios "RLCINF 1-1: RIGHT INTERFACE SIDE INCOMPATIBEL: of pblock [lindex [lindex $pblock_tile_types $x] 0] (CELL: [get_cells -of_objects [get_pblocks [lindex [lindex $pblock_tile_types $x] 0]] -quiet]) and pblock [lindex [lindex $pblock_tile_types_compare $y] 0] (CELL: %ELG)"
								}
								set vio [ create_drc_violation -name {RLCINF-1} -msg $interface_vios -severity ERROR [get_cells -of_objects [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]] -quiet]]
								lappend vios $vio 
								incr already_incompatibel 
								incr inf_incompatibel
							}
						}
					}
				}
			  
			} else {
			
				if {$side==1} {
					incr inf_left_placement_not_possible
					set left_already_checked_interfaces [linsert $left_already_checked_interfaces [llength $left_already_checked_interfaces] [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]]]
					set side_name LEFT
				} else {
					incr inf_right_placement_not_possible
					set right_already_checked_interfaces [linsert $right_already_checked_interfaces [llength $right_already_checked_interfaces] [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]]]
					set side_name RIGHT					
				}
				if {[llength [lsearch -all -exact $right_already_checked_interfaces [lindex [lindex $pblock_tile_types_compare $y] 0]]]==1 || [llength [lsearch -all -exact $left_already_checked_interfaces [lindex [lindex $pblock_tile_types_compare $y] 0]]]==1} {
					set interface_vios "RLCINF 1-2: $side_name INTERFACE SIDE INCOMPATIBEL: No placement of $side_name interface of pblock [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]] (CELL: %ELG) possible"
					set right_already_checked_interfaces [linsert $right_already_checked_interfaces [llength $right_already_checked_interfaces] [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]]]
					set vio [ create_drc_violation -name {RLCINF-1} -msg $interface_vios -severity ERROR [get_cells -of_objects [get_pblocks [get_pblocks [lindex [lindex $pblock_tile_types_compare $y] 0]] -quiet]]]
					lappend vios $vio 	
				}
			}	  
		  } 
		 } else {
			if {$side==1} {
				incr inf_left_placement_not_possible
				set left_already_checked_interfaces [linsert $left_already_checked_interfaces [llength $left_already_checked_interfaces] [get_pblocks [lindex $all_pblocks $x]]]
				set side_name LEFT
			} else {
				incr inf_right_placement_not_possible
				set right_already_checked_interfaces [linsert $right_already_checked_interfaces [llength $right_already_checked_interfaces] [get_pblocks [lindex $all_pblocks $x]]]
				set side_name RIGHT				
			}  
			if {[llength [lsearch -all -exact $right_already_checked_interfaces [lindex $all_pblocks $x]]]==1 || [llength [lsearch -all -exact $left_already_checked_interfaces [lindex $all_pblocks $x]]]==1} {
				set interface_vios "RLCINF 1-2: $side_name INTERFACE SIDE INCOMPATIBEL: No placement of $side_name interface of pblock [lindex $all_pblocks $x] (CELL: %ELG) possible"
				set vio [ create_drc_violation -name {RLCINF-1} -msg $interface_vios -severity ERROR [get_cells -of_objects [get_pblocks [lindex $all_pblocks $x]]]]
				lappend vios $vio 
			}
		 }
		}
	 }
	
	##create the console outputs depending on interface compatibility
	if {$inf_left_placement_not_possible <= [llength $all_pblocks] && $inf_right_placement_not_possible <= [llength $all_pblocks] && $inf_right_placement_not_possible!=0 && $inf_left_placement_not_possible!=0} {
		reset_msg_config -id {RLCINF 1-2} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-2} -string "RLCINF" -new_severity "Error" 
		incr placement_vios
	} elseif {$inf_left_placement_not_possible!=0 && $inf_left_placement_not_possible<=[llength $all_pblocks] && $inf_right_placement_not_possible == 0} {
		reset_msg_config -id {RLCINF 1-2} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-2} -string "RLCINF" -new_severity "Warning" 
	} elseif {$inf_right_placement_not_possible!=0 && $inf_right_placement_not_possible<=[llength $all_pblocks] && $inf_left_placement_not_possible == 0} {
		reset_msg_config -id {RLCINF 1-2} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-2} -string "RLCINF" -new_severity "Warning" 		
	}

	if {$inf_left_placement_not_possible == 0 && $inf_right_placement_not_possible == 0  && [llength $vios]>=[expr {2*[llength $all_pblocks] }]} {
		reset_msg_config -id {RLCINF 1-1} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-1} -string "RLCINF" -new_severity "Error"
		reset_msg_config -id {RLCINF 1-2} -string "RLCINF" -default_severity -quiet		
		set_msg_config -id {RLCINF 1-2} -string "RLCINF" -new_severity "Error"
		return -code error $vios 
	} elseif {[llength $vios]>0 && $placement_vios==0} {
		reset_msg_config -id {RLCINF 1-1} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-1} -string "RLCINF" -new_severity "Warning"
		reset_msg_config -id {RLCINF 1-2} -string "RLCINF" -default_severity -quiet		
		set_msg_config -id {RLCINF 1-2} -string "RLCINF" -new_severity "Warning"
		return -code error $vios 	
	} elseif {$placement_vios!=0} {
		reset_msg_config -id {RLCINF 1-1} -string "RLCINF" -default_severity -quiet
		set_msg_config -id {RLCINF 1-1} -string "RLCINF" -new_severity "Error"
		return -code error $vios
	} else {
		return {}
	}
	 
 }
 


 



