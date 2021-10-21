	#SOURCE
source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/StringLib.tcl


	## Get only site types
	##input: List of tiles, example : list {SLICE_X58Y59 RAMB36_X45Y34}, returned list {SLICE RAMB36}
proc pBlock_TileContent {list} {
	set grid_types_list_derived [set list]
	set length_derived_list [llength $grid_types_list_derived]
	#puts $length_derived_list
	set derived_tiles {}
	for {set x 0} {$x<$length_derived_list} {incr x} {
		set derived_help      [lindex $list $x]
		set str_end [string first _ $derived_help 0]
		set derived_tile_name [cutString $derived_help 0 $str_end]
		set derived_tiles [linsert $derived_tiles 1 $derived_tile_name] 
	}
return $derived_tiles
}	

proc pBlock_TileContent2 {list} {
	set grid_types_list_derived [set list]
	set length_derived_list [llength $grid_types_list_derived]
	#puts $length_derived_list
	set derived_tiles {}
	for {set x 0} {$x<$length_derived_list} {incr x} {
		set derived_help      [lindex $list $x]
		set str_end [string last X $derived_help [string length $derived_help]]
		set derived_tile_name [cutString $derived_help 0 [expr {$str_end - 1}]]
		set derived_tiles [linsert $derived_tiles 1 $derived_tile_name] 
	}
	##puts $derived_tiles
return $derived_tiles
}	

	################################Get X and Y COORDINATES out of Names of Sites/Tiles  LIKE DSP48_X14Y20
	#####################################################################################     returns     {14 20}   #####################################################
	#####################################################################################                   ^  ^     ###################################################
	#####################        																			|  |     ################################################
	###################																						x  y      ###################################################
proc get_name_coor { string } {
	
		set str_start [string last X $string [string length $string]]
		set str_end   [string length $string]
		set x_coor {}
		set y_coor {}
		
		#####GET X COORDINATES
		set x_start   [string last X $string [string length $string]]
		set y_start   [string first Y $string $str_start]
		
		set x_coor [cutString $string [expr {$x_start + 1}] $y_start]
		set y_coor [cutString $string [expr {$y_start + 1}] $str_end]
		
		set coor_list $x_coor
		set coor_list [linsert $coor_list 1 $y_coor]
		
		return $coor_list

}
		
	##Determine Min value 
proc min_value {a b} {
	if {$a<$b} {
		return $a;
	} else {
		return $b;
	}
}
	##Determine Max value
proc max_value {a b} {
	if {$a>$b} {
		return $a;
	} else {
		return $b;
	}
}

   ######################get_clock_regions_coordinates
  ######################OUTPUT {      X0Y0         0  155   85  105 } {X1Y0 89 155 186 105}   {     X0Y1         0   103  85    53 } {X1Y1 89 103 186 53} {X0Y2 0 51 85 1} {X1Y2 89 51 186 1}
  #############################{CLOCKREGION_NAME x_ll y_ll x_ur y_ur}.........................{CLOCKREGION_NAME x_ll y_ll x_ur y_ur}
  
  ##############-----------------> erweiterbar auch einzelne Clk regions Coordinaten zu erhalten
  
 proc get_clk_region_coordinates {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set clk_regions_list {}
 set error 0
 set help 0
 set all 0 
 set all_rect_points 0
 set clk_reg_cnt 0
 set name_indices 0 
 
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -clk_regions { 
				set clk_regions_list [lshift args]
				incr clk_reg_cnt
			  }
			  -all {
				incr all
			  }
			  -all_rect_points {
				incr all_rect_points
			  }
			  -name_indices {
				incr name_indices
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
						[-all  <>]
                        [-clk_regions <list {X0Y0 X1Y1}>] 
						[-all_rect_points <>]
						[-name_indices <>]
						
			Description: Returns the Corner Coordinates of the clock region based on tiles in the corners.
						 Returns a list like {X0Y0 0 155 85 105} {X1Y0 89 155 186 105} 
						 Index 0: NAME
						 Index 1: X coordinate of the lower left corner
						 Index 2: Y coordinate of the lower left corner
						 Index 3: X coordinate of the upper right corner
						 Index 4: Y coordinate of the upper right corner
						 
						 If -all_rect_points option is set, then all corner coordinates of the rectangular clockregion are returned
						 
						 Index 0: NAME
						 Index 1: X coordinate of the upper left corner
						 Index 2: Y coordinate of the upper left corner
						 Index 3: X coordinate of the upper right corner
						 Index 4: Y coordinate of the upper right corner						 
						 Index 5: X coordinate of the lower left corner
						 Index 6: Y coordinate of the lower left corner
						 Index 7: X coordinate of the lower right corner
						 Index 8: Y coordinate of the lower right corner	

						If -name_indices is chosen the last indexes of the returned list are the indices information out of the clock region name
						Index 0: NAME
						Index 1: Indice from X
						Index 2: Indice from Y
						 
			Example:    get_clk_region_coordinates -clk_regions {X0Y0 X1Y1} -all_rect_points or get_clk_region_coordinates -clk_regions {X0Y0 X1Y1} -name_indices
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {$all==1 && $clk_reg_cnt==1} {
		return -code error {In get_clk_region_coordinates procedure you can only choose -all or -clk_regions, not both}
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------	
 set clock_regions_coordinates_list {}
  
 if {$all} {
	set clock_regions [get_clock_regions]
 }
 
 if {[llength $clk_regions_list]!=0} {
	set clock_regions $clk_regions_list
 }
 
 if {$name_indices} {
	 for {set x 0} {$x<[llength $clock_regions]} {incr x} {
		 set coor [get_name_coor [lindex $clock_regions $x]]		 
		 set return_list "[lindex $clock_regions $x] [lindex $coor 0] [lindex $coor 1]" 
		 set clock_regions_coordinates_list [linsert $clock_regions_coordinates_list $x $return_list]			 
		}
 } else {
 
	 for {set x 0} {$x<[llength $clock_regions]} {incr x} {
		  set clk_region [lindex $clock_regions $x]
		  ##get the tiles in tiles in corners of the clock_region--> Then get x and y coordinates with the COLUMN and ROW Properties of the tiles
		  set clk_region_tile_lside [get_property TOP_LEFT_TILE [get_clock_regions $clk_region]]
		  set x_ll [get_property COLUMN [get_tiles $clk_region_tile_lside]]
		  set y_ur [get_property ROW [get_tiles $clk_region_tile_lside]]
		  
		  set clk_region_tile_rside [get_property BOTTOM_RIGHT_TILE [get_clock_regions $clk_region]]
		  set x_ur [get_property COLUMN [get_tiles $clk_region_tile_rside]]
		  set y_ll [get_property ROW [get_tiles $clk_region_tile_rside]]
		  
		   if {$all_rect_points} {
			   set x_ul $x_ll
			   set y_ul $y_ur
			   set x_lr $x_ur
			   set y_lr $y_ll
			   
			   set one_clk_region_coor "[lindex $clock_regions $x] $x_ul $y_ul $x_ur $y_ur $x_ll $y_ll $x_lr $y_lr"		   
			} else {
			   set one_clk_region_coor "[lindex $clock_regions $x] $x_ll $y_ll $x_ur $y_ur"		
			}

		  set clock_regions_coordinates_list [linsert $clock_regions_coordinates_list $x $one_clk_region_coor]	  
	 }
   }

 
 return $clock_regions_coordinates_list 
 }
 


  	###################################################################################################
	#
	#										get_fpga_size
	#
	#                    returns list {FPGA_SIZE_NAME x_ll y_ll x_ur y_ur}
	#								  {   FPGA_SIZE     0   155  186   1 }
	#
	#####################################################################################################
 
 proc get_fpga_size {} {
 
 set clk_regions_list [lsort -integer -increasing -index 1 [get_clk_region_coordinates -all]]
  
 set x_ll [lindex [lindex $clk_regions_list 0] 1]
 set y_ll [lindex [lindex $clk_regions_list 0] 2]
 
 set x_ur [lindex [lindex $clk_regions_list [expr {[llength $clk_regions_list] - 1}]] 3]
 set y_ur [lindex [lindex $clk_regions_list [expr {[llength $clk_regions_list] - 1}]] 4]
 
 set fpga_size "FPGA_SIZE $x_ll $y_ll $x_ur $y_ur"
 
 return $fpga_size
 }
 
 
 

 
 proc get_rect { args } { 
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock_list {}
 set included_tiles 0
 set tile_type_borders 0
 set error 0
 set help 0
 set exact 0 
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblocks { 
				set pblock_list [lshift args]
			  }
			  -exact {
				incr exact
			  }
			  -included_tiles {
				incr included_tiles
			  }			  
			  -tile_type_borders {
				incr tile_type_borders
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
						[-pblocks <pblocks_list>]
                        [-exact <>] [optional]
						[-tile_type_borders <>] [optional]
						[-included_tiles <>] [optional]
						
			Description: Returns the Corner Coordinates of the pblock region based on tiles in the corner.
						 If the option -exact is chosen the exact coordinates of the corners not based on tiles are returned.
						 Returns a list like {pblock_led_0 12 13 20 35} 
						 Index 0: NAME
						 Index 1: X coordinate of the lower left corner
						 Index 2: Y coordinate of the lower left corner
						 Index 3: X coordinate of the upper right corner
						 Index 4: Y coordinate of the upper right corner
						 
						 If -tile_type_borders is chosen than it returns included tiles in left corner and included tiles in right corner
						 Index 0: NAME
						 Index 1: X coordinate of the lower left corner
						 Index 2: Y coordinate of the lower left corner
						 Index 3: X coordinate of the upper right corner
						 Index 4: Y coordinate of the upper right corner
						 Index 5: TILE_TYPE on left side
						 Index 6: TILE_TYPE on right side
						 
			Example:    get_rect -pblocks {pblock_led_0 pblock_led_1} -exact
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------

set coor_pBlock_list {}
set pBlock_list_return {}
set crl 0	
set clb_in 0

if {$included_tiles} {
	incr exact
}

for {set nr 0} {$nr<[llength $pblock_list]} {incr nr} {
	#set_property SNAPPING_MODE ON [get_pblocks [lindex $pblock_list $nr]]
	##get all tile types in the pblock through GRID_RANGES AND GRIDTYPE Properties of the pblock
	set grid_list [get_property -quiet GRID_RANGES [get_pblocks [lindex $pblock_list $nr]]]
	##Site Types inside the pblock
	set grid_types_list [get_property -quiet GRIDTYPES [get_pblocks [lindex $pblock_list $nr]]]
	
	set pBlock_coor_l {}
	set pBlock_coor_r {}	
	
	##iterate about grid_list of the pblocks
	for {set name 0} {$name<[llength $grid_list]} {incr name} {
		
		##get_slices out of defined gridtypes
		set str_middle [string first : [lindex $grid_list $name] 0]
		set str_end    [string length  [lindex $grid_list $name]]
		
		set grid_type_left_corner [cutString [lindex $grid_list $name] 0 $str_middle]
		set grid_type_right_corner [cutString [lindex $grid_list $name] [expr $str_middle+1] $str_end]
		
		set site_left [get_sites $grid_type_left_corner -quiet]
		set site_right   [get_sites $grid_type_right_corner -quiet]
		
		if {[llength $site_left]!=0 && [llength $site_right]!=0} {
		
		##get x and y coordinates of sites of the gridtypes
		set x_coor_l [get_property -quiet COLUMN [get_tiles -quiet -of_objects $site_left]]
		set y_coor_l [get_property -quiet ROW [get_tiles -quiet -of_objects $site_left]]
		set tile_type_l [get_property TILE_TYPE [get_tiles -quiet  -of_objects $site_left]]
		
		set xy_tile_l "$tile_type_l $x_coor_l $y_coor_l"

		set x_coor_r [get_property -quiet COLUMN [get_tiles -quiet -of_objects $site_right]]
		set y_coor_r [get_property -quiet ROW [get_tiles -quiet -of_objects $site_right]]

		set tile_type_r [get_property TILE_TYPE [get_tiles -quiet  -of_objects $site_right]]

		set xy_tile_r "$tile_type_r $x_coor_r $y_coor_r"
		
		##get_tiles for left and right positions of the grid_types-->smalles and highest Tiles
		set pBlock_coor_l [linsert $pBlock_coor_l $nr $xy_tile_l]
		set pBlock_coor_r [linsert $pBlock_coor_r $nr $xy_tile_r]
		
		}
					
		}

	
	set tile_last [llength $pBlock_coor_r]	
	set pBlock_coor_l [lsort -integer -index 1 $pBlock_coor_l]
	set pBlock_coor_r [lsort -integer -index 2 $pBlock_coor_r]	

	##determine exact coordinates of pblock with the help of the clb tiles inside of the pblock
	if {$exact} { 
		 set tile_type_ll  [lindex [lindex [lsort -integer -index 1 $pBlock_coor_l] 0] 0]

		set index_l [search_String $pBlock_coor_l CLB 0]
		set index_r [search_String $pBlock_coor_r CLB 0]
		
		if {$index_l==-1 || $index_r==-1} {
			return -code error {No CLB's in Pblock, so no correct rect coordinates are the result}
		} else {
			set pBlock_coor_y_ll [lindex [lindex $pBlock_coor_l [lindex $index_l 0]] 2]
			set pBlock_coor_y_ur [lindex [lindex $pBlock_coor_r [lindex $index_r 0]] 2]			
		}
		
		 for {set x 0} {$x<[llength $pBlock_coor_l]} {incr x} {
		 
			if {[search_String [lindex $pBlock_coor_l $x] CLB 0]!=-1} {

				incr clb_in
			}
		}
		 set tile_type_ur  [lindex [lindex [lsort -integer -index 1 $pBlock_coor_r] [expr {$tile_last - 1}]] 0]  
	
	} else {
			set pBlock_coor_y_ll [lindex [lindex [lsort -integer -index 1 $pBlock_coor_l] 0] 2]
			set pBlock_coor_y_ur [lindex [lindex [lsort -integer -index 1 $pBlock_coor_r] [expr {$tile_last - 1}]] 2]				
	}

	
	set crl 0
	set coor_pBlock_list {}
	
	##return values
	set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl}] [lindex $pblock_list $nr]]
	set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+1}] [lindex [lindex [lsort -integer -index 1 $pBlock_coor_l] 0] 1]]
	set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+2}] $pBlock_coor_y_ll]
	set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+3}] [lindex [lindex [lsort -integer -index 1 $pBlock_coor_r] [expr {$tile_last - 1}]] 1]]
	set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+4}] $pBlock_coor_y_ur]
	
	if {$tile_type_borders} {
		set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+5}] $tile_type_ll]
		set coor_pBlock_list [linsert $coor_pBlock_list [expr {$crl+6}] $tile_type_ur]	
	} 
	
	set pBlock_list_return [linsert $pBlock_list_return $nr $coor_pBlock_list] 

}

 set all_tiles {}
 if {$included_tiles} {
	for {set x 0} {$x<[llength $pBlock_list_return]} {incr x} {
		set pblock_tile_types {}
		set pblock_tile_types [linsert $pblock_tile_types 0 [lindex [lindex $pBlock_list_return $x] 0]]
		for {set y [lindex [lindex $pBlock_list_return $x] 1]} {$y<=[lindex [lindex $pBlock_list_return $x] 3]} {incr y} {
			set filter_expr "ROW==[lindex [lindex $pBlock_list_return $x] 2] && COLUMN==$y"
			set tile_type_included [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
			#set tile_type_included  [get_tiles -filter $filter $filter_expr]
			set pblock_tile_types [linsert $pblock_tile_types [llength $pblock_tile_types] $tile_type_included]
		}
	set all_tiles [linsert $all_tiles [llength $all_tiles] $pblock_tile_types]
	}
 }

 if {$included_tiles} {
	return $all_tiles
 } else {
	return $pBlock_list_return
}

 }

 #########
 #######################################################################################
 #
 #											draw_rect
 #
 #######################################################################################
  
 proc draw_rect {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments x_ll y_ll x_ur y_ur pBlock_name
  #-----------------------------------------------------------------------------------------------------------------
 set x_ll 0
 set y_ll 0
 set x_ur 0 
 set y_ur 0 
 set create 0
 set add 0
 set remove 0 
 set pBlock_name {}
 
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -create { 
				incr create
			  }
			  -add {
				incr add
			  }
			  -remove { 
				incr remove
			  }
			  -x_ll { 
				set x_ll [lshift args]
			  }
			  -y_ll {
				set y_ll [lshift args]
			  }
			  -x_ur { 
				set x_ur [lshift args]
			  }
			  -y_ur {
				set y_ur [lshift args]
			  }		
			  -name {
			   set pBlock_name [lshift args]
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
						[-create  <>]
						[-remove  <>]		   
						[-x_ll  <INT>]
						[-y_ll  <INT>]
						[-x_ur  <INT>]
						[-y_ur  <INT>] 
						[-name <NAME>]
						
			Description: Creates a Pblock automatically only with the Information of coordinates. 
						 Corner values which lay onto INT_... TILES are not allowed. Vivado doesn't draw pblocks
						 to thies corner values.
						 
			Procedure Info: In procedure draw_rect there are tile sizes used out of the GLOBAL_PBLOCK namespace.
							This sizes were manually listed. For other FPGA Types the list have to be updated in 
							matters of tile sizes.
						 
			Example:    draw_rect -create -x_ll 0 -y_ll 155 -x_ur 30 -y_ur 140 -name test_pblock
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {$create==0 && $remove==0 && $add==0} {
		return -code error {In draw_rect procedure must be option -create or -remove set}
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------	
 set pBlock_width [expr {$x_ur + 1 }]
 set pBlock_length [expr {$y_ll+ 1 }]
 set all_lower_tiles_list {}
 set inside0 -1
 
 set upper_dist_list {}
 set lower_dist_list {} 
 set list_cnt 1 
 set list_start 0
 set end 0
 
 ##get the maximum distance of the tiles in the fpga design
 while {$end!=1} {
	set upper_dist_list [linsert $upper_dist_list $list_start [lindex $GLOBAL_PBLOCK::tile_length_list $list_cnt]]
	set lower_dist_list [linsert $lower_dist_list  $list_start [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$list_cnt + 1}]]]
	set list_cnt [expr {$list_cnt + 3}]
	incr list_start
	
	if {$list_cnt>=[llength $GLOBAL_PBLOCK::tile_length_list]} {
		set end 1
	}
 }
 ##helping coordinates to determine whether tile is fully inside the pblock range or outside
 set highest_dist [lindex [lsort -integer $upper_dist_list] [expr {[llength $upper_dist_list] - 1}]]
 set lowest_dist  [lindex [lsort -integer $lower_dist_list] [expr {[llength $lower_dist_list] - 1}]]
 
 ##determine whether pblock is existing and to add a ressources or to create a new one
 if {$create==1 && $add==0} {
	create_pblock $pBlock_name
	}
	
 ##iterate from x_ll to x_ur which are defined by the user
 ##analize tile types in each column "x" which tile types and site types has to be added or removed
 for {set x $x_ll} {$x<$pBlock_width} {incr x} {

	set index 0				
	set tile_filter "COLUMN==$x && ROW>=$y_ur && ROW<=$y_ll && TILE_TYPE!=NULL"	
	set tiles_in_column [get_tiles -filter $tile_filter]
	
	set part_name_tiles [pBlock_TileContent2 $tiles_in_column]	
	set new_part_name_tiles {}	
	
		##############################look wheter sites are duplicated in the list-----------------> part_name_site = {DSP48 TIEOFF DSP48} -->man will nur liste = {DSP48 TIEOFF}
	for {set z 0} {$z<[llength $part_name_tiles]} {incr z} {
		set looked_for [lsearch  $new_part_name_tiles [lindex $part_name_tiles $z]]
		if {$looked_for==-1} {
			set new_part_name_tiles [linsert $new_part_name_tiles 1 [lindex $part_name_tiles $z]]
		}
	}	
	

	########################################################################################################################
	#
	#
    #										FILTERING OF TILES FOR THE PBLOCK
	#
	#########################################################################################################################
	set max_length 0
	set max_list {}
	set index_help 0	

	##determine the biggest tiles in the column
	for {set a 0} {$a<[llength $new_part_name_tiles]} {incr a} {
		set length_index [search_String $GLOBAL_PBLOCK::tile_length_list [lindex $new_part_name_tiles $a] 1]
		set length_index_up [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$length_index + 1}]]
		set length_index_down [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$length_index + 2}]]
		
			
		if {[search_String $max_list $length_index_up 1]==-1 || [search_String $max_list $length_index_down 1]} {
		    set max_list [linsert $max_list $max_length [lindex $new_part_name_tiles $a]]
			incr max_length
			set derived_length_up $length_index_up
			set derived_length_down $length_index_down
		}		
	}

	##get tile types which are fully inside the COLUMN between y_ll and y_ur		
	if {$max_length==1} {
		set tile_filter "COLUMN==$x && ROW>=[expr {$y_ur + $derived_length_up}] && ROW<=[expr {$y_ll - $derived_length_down}] && TILE_TYPE!=NULL"
		set tiles_in_column [get_tiles -filter $tile_filter]
	}
	set biggest_tile {}
	#################wenn es mehrere größere Tiles gibt------->dann suche nach dem obersten um die höchste Grenze zur Filterung zu finden	
	if {$max_length>1} {
		set all_val_coor_list {}
		
		set biggest_tile $tiles_in_column
		set tile_types [get_property TILE_TYPE [get_tiles $biggest_tile]] 
		set y_coor [get_property ROW [get_tiles $biggest_tile]]
		
		for {set m 0} {$m<[llength $biggest_tile]} {incr m} {	
			set length_index [search_String $GLOBAL_PBLOCK::tile_length_list [lindex $tile_types $m] 1]
			set length_index_up [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$length_index + 1}]]
			set length_index_down [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$length_index + 2}]]			
			
		    set val_coor_list {}
			set val_coor_list [linsert $val_coor_list 0 [lindex $biggest_tile $m]]
			set val_coor_list [linsert $val_coor_list 1 [lindex $y_coor $m]]
			set val_coor_list [linsert $val_coor_list 2 $length_index_up]
			set val_coor_list [linsert $val_coor_list 3 $length_index_down]
			set all_val_coor_list [linsert $all_val_coor_list $m $val_coor_list]			
		}
		set sorted_biggest_tiles [lsort -integer -index 1 $all_val_coor_list]	
		set length_sorted_list [llength $sorted_biggest_tiles]
        set derived_length_up [lindex [lindex $sorted_biggest_tiles 0] 2]	
		set derived_length_down [lindex [lindex $sorted_biggest_tiles [expr {$length_sorted_list - 1}]] 3]
		
		set tile_filter "COLUMN==$x && ROW>=[expr {$y_ur + $derived_length_up}] && ROW<=[expr {$y_ll - $derived_length_down}] && TILE_TYPE!=NULL"
		set tiles_in_column [get_tiles -filter $tile_filter]			
	}

	set y_up_list {}
	set y_down_list {}

	##if ressources have to be removed from pblock --> check which are the highest and lowest tiles
	if {$remove} {
			
			if {$y_ur==[lindex $GLOBAL_PBLOCK::y_range 0]} {
				set highest_dist 0
			} elseif {$y_ll==[lindex $GLOBAL_PBLOCK::y_range 1]} {
				set lowest_dist 0
			}
		
			set filter_expr_upper "ROW>=[expr {$y_ur - $highest_dist}] && ROW<=$y_ur  && COLUMN==$x && TILE_TYPE!=NULL"
			set filter_expr_lower "ROW<=[expr {$y_ll + $lowest_dist}]  && ROW>=$y_ll && COLUMN==$x && TILE_TYPE!=NULL"
			set tile_name_up [get_tiles -filter $filter_expr_upper]
	
			if {[llength $tile_name_up]!=0} {
			    set y_coor_up [get_property ROW [get_tiles $tile_name_up]]			
				for {set y 0} {$y<[llength $tile_name_up]} {incr y} {
					set tile_y_val "[lindex $tile_name_up $y] [lindex $y_coor_up $y]"
					set y_up_list [linsert $y_up_list $y $tile_y_val]
				}
				set y_up_list [lsort -integer -index 1 $y_up_list]				
				set tile_index [search_String $GLOBAL_PBLOCK::tile_length_list [pBlock_TileContent2 [lindex [lindex $y_up_list 0] 0]] 1]			
				set y_tile_dist_down [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$tile_index + 2}]]			
				if {[expr {[lindex [lindex $y_up_list [expr {[llength $y_up_list] - 1}]] 1] + $y_tile_dist_down}]>=$y_ur} {
					set tiles_in_column [linsert $tiles_in_column [llength $tiles_in_column] [lindex [lindex $y_up_list [expr {[llength $y_up_list] - 1}]] 0]]
				}
			}
	###############################		
			set tile_name_down [get_tiles -filter $filter_expr_lower]
	
			if {[llength $tile_name_down]!=0} {		
				set y_coor_down [get_property ROW [get_tiles $tile_name_down]]			
				for {set y 0} {$y<[llength $tile_name_down]} {incr y} {

					set tile_y_val "[lindex $tile_name_down $y] [lindex $y_coor_down $y]"
					set y_down_list [linsert $y_down_list $y $tile_y_val]
				}
				set y_down_list [lsort -integer -index 1 $y_down_list]			
				set tile_index [search_String $GLOBAL_PBLOCK::tile_length_list [pBlock_TileContent2 [lindex [lindex $y_down_list [expr {[llength $y_down_list] - 1}]] 0]] 1]
				set y_tile_dist_up [lindex $GLOBAL_PBLOCK::tile_length_list [expr {$tile_index + 1}]]
							
				if {[expr {[lindex [lindex $y_down_list 0] 1] - $y_tile_dist_up}]<=$y_ll} {
					set tiles_in_column [linsert $tiles_in_column [llength $tiles_in_column] [lindex [lindex $y_down_list 0] 0]]
				}	

				set part_name_tiles [pBlock_TileContent2 $tiles_in_column]	
				set new_part_name_tiles {}	
				
					##############################schauen ob sites doppelt vorhanden-----------------> part_name_site = {DSP48 TIEOFF DSP48} -->man will nur liste = {DSP48 TIEOFF}
				for {set z 0} {$z<[llength $part_name_tiles]} {incr z} {
					set looked_for [lsearch  $new_part_name_tiles [lindex $part_name_tiles $z]]
					if {$looked_for==-1} {
						set new_part_name_tiles [linsert $new_part_name_tiles 1 [lindex $part_name_tiles $z]]
					}
				}
			}	
	
	}
 ########################################################################################################
 #
 #
 #											GET MINIMUM AND MAXIMUM TILES
 #
 #
 ########################################################################################################

  ##get tiles minimum and maximum of valid tile list "ne_part_name_tiles"
 		set min_tiles {}
		set max_tiles {}
		set list_nr {}

	
		for {set z 0} {$z<[llength $new_part_name_tiles]} {incr z} {
		
			set list_nr [search_String  $tiles_in_column [lindex $new_part_name_tiles $z] 0]
			set all_val_coor_list {}
			
					for {set l 0} {$l<[llength $list_nr]} {incr l} {
						set min_value [lindex $tiles_in_column [lindex $list_nr $l]]	
						set y_coor [lindex [get_name_coor $min_value] 1]
						
						if {[llength $min_value]!=0 && [llength $y_coor]!=0} {
							set val_coor_list {}
							set val_coor_list [linsert $val_coor_list 0 $min_value]
							set val_coor_list [linsert $val_coor_list 1 $y_coor]
							set all_val_coor_list [linsert $all_val_coor_list $l $val_coor_list]
						}
					}	

 #####################% lsort -index 1 {{a 5} { c 3} {b 4} {e 1} {d 2}}
 #####################  {e 1} {d 2} { c 3} {b 4} {a 5}				
 
			set sorted_tiles [lsort -integer -index 1 $all_val_coor_list]
			set length_sorted_tiles [llength $sorted_tiles]
			
			set min_tiles [linsert $min_tiles $z [lindex [lindex $sorted_tiles 0] 0]]
			set max_tiles [linsert $max_tiles $z [lindex [lindex $sorted_tiles [expr {$length_sorted_tiles-1}]] 0]]			
		}
		
  #######################################################################################################
  #
  #
  #										GET MINIMUM SITES AND MAXIMUM SITES
  #
  #
  #######################################################################################################
 
 for {set r 0} {$r<[llength $min_tiles]} {incr r} {
	#set tile [lindex $min_tiles $r]
	set site_min [get_sites -of_objects [get_tiles [lindex $min_tiles $r]]]
	set site_max [get_sites -of_objects [get_tiles [lindex $max_tiles $r]]]
		
	if {[llength $site_min]!=0 && [llength $site_max]!=0} {
	
		set part_name_sites_min [pBlock_TileContent2 $site_min]
		set new_part_name_sites_min {}
		
		set part_name_sites_max [pBlock_TileContent2 $site_max]
		set new_part_name_sites_max {}
		
		
		for {set z 0} {$z<[llength $site_min]} {incr z} {
			set looked_for [search_String  $new_part_name_sites_min [lindex $part_name_sites_min $z] 0]
			if {$looked_for==-1} {
				set new_part_name_sites_min [linsert $new_part_name_sites_min 1 [lindex $part_name_sites_min $z]]
			}
		}
		
		
		for {set z 0} {$z<[llength $site_max]} {incr z} {
			set looked_for [search_String  $new_part_name_sites_max [lindex $part_name_sites_max $z] 0]
			if {$looked_for==-1} {
				set new_part_name_sites_max [linsert $new_part_name_sites_max 1 [lindex $part_name_sites_max $z]]
			}
		}		
		
		if {[llength $new_part_name_sites_max]==[llength $new_part_name_sites_min]} {
			set new_part_name_sites $new_part_name_sites_max
			
 ########################################################################################################
 #
 #
 #											GET MINIMUM AND MAXIMUM SITES
 #                         Innerhalb der Tiles können auch mehrere SITES auftreten, deswegen komplexer
 #
 #
 ########################################################################################################		
			set min_sites {}
			set max_sites {}
			set list_nr {}
			set index 0
	
			for {set z 0} {$z<[llength $new_part_name_sites]} {incr z} {
			
				set list_nr_min [search_String $site_min [lindex $new_part_name_sites $z] 0]
				set list_nr_max [search_String $site_max [lindex $new_part_name_sites $z] 0]
			    set all_val_coor_list_min {}
			    set all_val_coor_list_max {}
				
					for {set l 0} {$l<[llength $list_nr_min]} {incr l} {	
						set site_name_min [lindex $site_min [lindex $list_nr_min $l]]	

						set y_coor_min [lindex [get_name_coor $site_name_min] 1]
						set x_coor_min [lindex [get_name_coor $site_name_min] 0]	

						
						if {[llength $site_name_min]!=0 && [llength $y_coor_min]!=0 && [llength $x_coor_min]!=0} {
		                set val_coor_list_min {}
						set val_coor_list_min [linsert $val_coor_list_min 0 $site_name_min]
						set val_coor_list_min [linsert $val_coor_list_min 1 $x_coor_min]
						set val_coor_list_min [linsert $val_coor_list_min 2 $y_coor_min]
							

						set all_val_coor_list_min [linsert $all_val_coor_list_min $l $val_coor_list_min]
						}

					}	
	
					
					for {set l 0} {$l<[llength $list_nr_max]} {incr l} {					
						set site_name_max [lindex $site_max [lindex $list_nr_max $l]]			
						set y_coor_max [lindex [get_name_coor $site_name_max] 1]
						set x_coor_max [lindex [get_name_coor $site_name_max] 0]					
						
						if {[llength $site_name_max]!=0 && [llength $y_coor_max]!=0 && [llength $x_coor_max]!=0} {
		                set val_coor_list_max {}
						set val_coor_list_max [linsert $val_coor_list_max 0 $site_name_max]
						set val_coor_list_max [linsert $val_coor_list_max 1 $x_coor_max]
						set val_coor_list_max [linsert $val_coor_list_max 2 $y_coor_max]
							

							set all_val_coor_list_max [linsert $all_val_coor_list_max $l $val_coor_list_max]
						}	
					}			
 
					######erst nach x sortieren und dann nach y sortieren
					set sorted_sites_max [lsort -integer -index 2 [lsort -integer -index 1 $all_val_coor_list_max]]
					set length_sorted_sites_max [llength $sorted_sites_max]
					
					set sorted_sites_min [lsort -integer -index 2 [lsort -integer -index 1 $all_val_coor_list_min]]
					set length_sorted_sites_min [llength $sorted_sites_min]	
					
					set min_sites [linsert $min_sites $z [lindex [lindex $sorted_sites_min 0] 0]]
					set max_sites [linsert $max_sites $z [lindex [lindex $sorted_sites_max [expr {$length_sorted_sites_max-1}]] 0]]		
			
			}
		}
  ########################################################################################################
  #
  #
  #						ADDING SITE RANGES FROM MINIMUM TO MAXIMUM SITE TO PBLOCK
  #
  #
  #######################################################################################################				
			
			for {set k 0} {$k<[llength $max_sites]} {incr k} {
			
				set add_sites_list {}
			
				set min_pos_in_list     [search_String $min_sites [lindex $new_part_name_sites_min $k] 0]
				set max_pos_in_list     [search_String $max_sites [lindex $new_part_name_sites_max $k] 0]
						
				##-->TIEOFF SITE kann nicht zu PBLOCKs hinzugefügt werden
				set inside0 [search_String [lindex $new_part_name_sites_min $k] TIEOFF 0]
	
				if {$inside0==-1} {			
					set min_max_corner "[lindex $min_sites $min_pos_in_list]:[lindex $max_sites $max_pos_in_list]"
					set add_sites_list [linsert $add_sites_list 1 $min_max_corner]
			
			    if {$create==1 || $add==1} {
					puts "ADDED SITES: $add_sites_list"
					resize_pblock $pBlock_name -add $add_sites_list	
				}
				
				if {$remove==1} {
					puts "DELETED SITES: $add_sites_list"
					resize_pblock $pBlock_name -remove $add_sites_list					
				}
				
				}
			}			
		
	}		
 }
 }

 }

 #######################################################################################
 #
 #								pblock_in_clk_region
 #
 #######################################################################################
  proc pblock_in_clk_region {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock_list {}
 set error 0
 set help 0
 set exact 0 
 
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblocks { 
				set pblock_list [lshift args]
				incr clk_reg_cnt
			  }
			  -exact {
				incr exact
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
						[-pblocks  <PBLOCK_LIST>]
                        [-exact <>] [optional]

						
			Description: Returns the Clockregions in which the pblock is located.
						 Returns a list like {pblock_1 X0Y0 X1Y0} 
						 Index 0: NAME
						 Index n+1: The Clockregions in which the pblock is located

						 
						 If -exact option is set, then all corner coordinates of the rectangular clockregion are returned
						 DEFINITION OF RECT CORNERS: 0=upper left corner, 1=upper right corner, 2=lower left corner, 3=lower right corner
						 
						 Return list example: {pblock_1 2 X0Y0 3 X1Y0 0 X0Y1 1 X1Y1}
						 Index 0: NAME
						 Index 1: corner 
						 Index 2: Clockregion of corner in Index 1
						 Index 3: corner 
						 Index 4: Clockregion of corner in Index 3
						 Index 5: corner 
						 Index 6: Clockregion of corner in Index 5
						 Index 7: corner 
						 Index 8: Clockregion of corner in Index 7
						 
			Example:    pblock_in_clk_region -pblocks pblock_1 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {[llength $pblock_list]==0} {
		return -code error {Missing pblocks in arguments of option -pblocks}
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 		set clk_regions [get_clk_region_coordinates -all]
		set pblock_list [get_rect -pblocks $pblock_list -exact]
 		set pBlock_points_in_clk_region {} 
		set pBlock_clk_reg {}
	
		for {set x 0} {$x<[llength $pblock_list]} {incr x} {	 

				 set in_clk_reg 0
				 set pBlock_in {}
				 set clk_region_inside {}
				 
				 #puts "PBLOCK: [lindex [lindex $pblock_list $x] 0]"	
				 #puts "CLK_REGIONS: $clk_regions"
				 
			 for {set y 0} {$y<[llength $clk_regions]} {incr y} {
				 set point_nr 0	
				 
				 set x_pB2 [lindex [lindex $pblock_list $x] 1]
				 set y_pB2 [lindex [lindex $pblock_list $x] 2]
				 set x_pB1 [lindex [lindex $pblock_list $x] 3]
				 set y_pB1 [lindex [lindex $pblock_list $x] 4] 
				 set x_pB0 $x_pB2
				 set y_pB0 $y_pB1
				 set x_pB3 $x_pB1
				 set y_pB3 $y_pB2
				 
				 set rect_points "$x_pB0 $y_pB0 $x_pB1 $y_pB1 $x_pB2 $y_pB2 $x_pB3 $y_pB3"
				 
				 set x_ll_clkR [lindex [lindex $clk_regions $y] 1]
				 set y_ll_clkR [lindex [lindex $clk_regions $y] 2]
				 set x_ur_clkR [lindex [lindex $clk_regions $y] 3]
				 set y_ur_clkR [lindex [lindex $clk_regions $y] 4]
		 
				 for {set point 0} {$point<[llength $rect_points]} {set point [expr {$point+2}]} {
				 #puts "[lindex $rect_points $point]>=$x_ll_clkR && [lindex $rect_points $point]<=$x_ur_clkR && [lindex $rect_points [expr {$point + 1}]]>=$y_ur_clkR && [lindex $rect_points [expr {$point + 1}]]<=$y_ll_clkR"
					 if {[lindex $rect_points $point]>=$x_ll_clkR && [lindex $rect_points $point]<=$x_ur_clkR && [lindex $rect_points [expr {$point + 1}]]>=$y_ur_clkR && [lindex $rect_points [expr {$point + 1}]]<=$y_ll_clkR} {
						 #puts "in_clk_reg: $in_clk_reg"
							if {$in_clk_reg==0} {
									set pBlock_in "[lindex [lindex $pblock_list $x] 0] $point_nr [lindex [lindex $clk_regions $y] 0]"
									#puts "$pBlock_in"
									set in_clk_reg 3							
									set clk_reg "[lindex [lindex $pblock_list $x] 0] [lindex [lindex $clk_regions $y] 0]"	
									#puts "$clk_reg"
							} else {
								if {[search_String $clk_reg [lindex [lindex $clk_regions $y] 0] 1]==-1} {
									set clk_reg [linsert $clk_reg [expr {[llength $clk_reg]-1}] [lindex [lindex $clk_regions $y] 0]]
								}
								set clk_region_inside [lindex [lindex $clk_regions $y] 0]
								set pBlock_in [linsert $pBlock_in $in_clk_reg $point_nr]
								#puts $pBlock_in
								set pBlock_in [linsert $pBlock_in [expr {$in_clk_reg + 1}] $clk_region_inside]
								set in_clk_reg [expr {$in_clk_reg+2}]							
							}
						 
					
					}
				incr point_nr
				}	

			}
			
			if {$exact} {
		          set pBlock_points_in_clk_region [linsert $pBlock_points_in_clk_region $x $pBlock_in]	
			} else {
		          set pBlock_clk_reg [linsert $pBlock_clk_reg $x $clk_reg]	

			}

		 }

		if {$exact} {
			return $pBlock_points_in_clk_region		
		} else {
			return $pBlock_clk_reg		
		}
}

 ###########################################################################################
 #																						   #
 #										get_pblock_neighbours                              #
 #																						   #
 #																						   #
 ###########################################################################################
proc get_pblock_neighbours {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblocks {}
 set error 0
 set help 0

 
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblocks { 
				set pblocks [lshift args]
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
						[-pblocks  <pblocks_list>]

						
			Description: Returns the neighbour regions and as the case may be the pblocks around the specified pblock in -pblocks.
						 Returns a list like {{pblock_3 RIGHT pblock_5 LEFT pblock_2 ABOVE pblock_1 BELOW NONE} {pblock_5 RIGHT NONE LEFT pblock_3 ABOVE pblock_1 BELOW NONE} where specified pblocks are -pblocks {pblock_3 pblock_5}}.
						 Lists within the returned list of this proc are identically structured.
						 
						 Example 1: only one pblock on each side 
						 
						 
						 Index 0: NAME of specified pblock in -pblocks
						 Index 1: side string: RIGHT 
						 Index 2: Region or Pblock of RIGHT side
						 Index 3: side string: LEFT
						 Index 4: Region or Pblock of LEFT side
						 Index 5: side string: ABOVE 
						 Index 6: Region or Pblock of ABOVE side [upper side]
						 Index 7: side string: BELOW
						 Index 8: Region or Pblock of BELOW side [lower side]						 

						 Example 2: more pblocks on each side could be possible 
						 For -pblocks {pblock_1} returns a list like {{pblock_1 RIGHT NONE LEFT NONE ABOVE CLOCKREGION BELOW X0Y1 X1Y0 pblock_5 pblock_4 pblock_3 pblock_2}}
						 
						 Index 0: NAME of specified pblock in -pblocks
						 Index 1: side string: RIGHT
						 Index 2: Region or Pblock of RIGHT side
						 Index 3: side string: LEFT
						 Index 4: Region or Pblock of LEFT side						 
						 Index 5: side string: ABOVE
						 Index 6: Region or Pblock of ABOVE side [upper side]
						 Index 7: side string: BELOW
						 Index 8: Region or Pblock of BELOW side [lower side]
						 Index 9: Region or Pblock of BELOW side [lower side]
						 Index 10:Region or Pblock of BELOW side [lower side]
						 Index 11:Region or Pblock of BELOW side [lower side]

						 
			Example:    get_pblock_neighbours -pblocks {pblock_1} or get_pblock_neighbours -pblocks {pblock_1 pblock_3 pblock_4}
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	if {[llength $pblocks]==0} {
		return -code error {No pblocks are specified in option -pblocks}
	}
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------	
 
 		##OUTPUT: {X0Y0 X1Y0 X0Y1 X1Y1 X0Y2 X1Y2}
set pblock_list [get_pblocks *]
 ### liste mit pBlöcken für Rekonfiguration mit deren Koordinaten
set recon_Block_list [get_rect -pblocks $pblock_list -exact]
set act_pb_list $pblocks
puts "pblocks: $pblocks"
set all_clk_regions [get_clock_regions]
set blocks_around {}
set pBlock_clk_reg [pblock_in_clk_region -pblocks $pblock_list]

	########################sortierte listen -->herausfinden welche Blöcke rechts, links, oberhalb oder unterhalb des aktuellen pblocks liegen		
set x_sorted [lsort -integer -index 1 $recon_Block_list]
set y_sorted [lsort -integer -decreasing -index 2 $recon_Block_list]

for {set x 0} {$x<[llength $act_pb_list]} {incr x} {	
		
		set act_pb [lindex [lindex $x_sorted [search_part_list $x_sorted [lindex $act_pb_list $x]]] 0]
		set act_pb_in_x_sorted [search_part_list $x_sorted $act_pb]
		set act_pb_in_y_sorted [search_part_list $y_sorted $act_pb]
		set act_clk_reg_pb_in  [lindex $pBlock_clk_reg [search_part_list $pBlock_clk_reg $act_pb]]
		puts "act_clk_reg_pb_in: $act_clk_reg_pb_in"
	    set pblock_spec_list "$act_pb"	
		
		############################################rechts und links pblocks bestimmen
		for {set rl 0} {$rl<2} {incr rl} {
			if {$rl==0} {
				set start_index [expr {$act_pb_in_x_sorted + 1}]
				set end_index   [expr {[llength $x_sorted] - 1}]
				set last_element 0
				set found 0
				set next_clk_reg_add 1
				####wenn letztes element in der liste
				if {$act_pb_in_x_sorted==$end_index} {
					set last_element 1	
				}
				set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "RIGHT"]
			} else {
				set start_index [expr {$act_pb_in_x_sorted - 1}]
				set end_index 0
				set last_element 0 
				set found 0
				set next_clk_reg_add -1
				if {$act_pb_in_x_sorted==$end_index} {
					set last_element 1	
				}	
				set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "LEFT"]				
			}		
			while {$found==0} {		
			if {$last_element!=1} {
				set compare_pb [lindex [lindex $x_sorted $start_index] 0]
				set compare_clk_reg_pb_in [lindex $pBlock_clk_reg [search_String $pBlock_clk_reg $compare_pb 0]]	
				###########prüfen ob pBlock in der gleichen Region ist
				for {set y 1} {$y<[llength $act_clk_reg_pb_in]} {incr y} {
					if {[search_String $compare_clk_reg_pb_in [lindex $act_clk_reg_pb_in $y] 1]!=-1} {
						set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] $compare_pb]
						set found 1
						break
					}
				}
					
				##########prüfen ob pBlock in der nächsten Region ist
				if {$found==0} {	
					for {set y 1} {$y<[llength $act_clk_reg_pb_in]} {incr y} {
						set name_coor_act [get_name_coor [lindex $act_clk_reg_pb_in $y]]			
						for {set z 1} {$z<[llength $compare_clk_reg_pb_in]} {incr z} {		
							set name_coor_compare [get_name_coor [lindex $compare_clk_reg_pb_in $z]]				
							if {[expr {[lindex $name_coor_act 0] + $next_clk_reg_add}]==[lindex $name_coor_compare 0] && [lindex $name_coor_act 1]==[lindex $name_coor_compare 1]} {
								set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] $compare_pb]
								set found 1
								break
							}
						}
					}				
				}
			} 
			if {$start_index==$end_index && $found==0 || $last_element==1} {
				###wenn keine Pblöcke in der gleichen clk region oder nebenan, dann ist der Block neben an eine Clkregion
				set clk_coor_pb {}
				set found 1
				for {set y 1} {$y<[llength $act_clk_reg_pb_in]} {incr y} {
					set clk_reg_coor "[get_name_coor [lindex $act_clk_reg_pb_in $y]]"
					set clk_coor_pb [linsert $clk_coor_pb [llength $clk_coor_pb] $clk_reg_coor]
				}
				set clk_coor_pb [lsort -integer -index 0 $clk_coor_pb]
				if {[llength $clk_coor_pb]>1} {
					if {$rl==0} {
						set x_expr [expr {[llength $clk_coor_pb] - 1}]
					} else {
						set x_expr 0
					}
				} else {
					set x_expr 0
				}
				set clk_reg_name "X[expr {[lindex [lindex $clk_coor_pb $x_expr] 0] + $next_clk_reg_add}]Y[lindex [lindex $clk_coor_pb 0] 1]"
				
				if {[search_String $all_clk_regions $clk_reg_name 1]!=-1} {
					set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "CLOCKREGION"]
					set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] $clk_reg_name]
				} else {
					set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "NONE"]
				}
			}		
			if {$rl==0} {
				incr start_index				
			} else {
				set start_index [expr {$start_index - 1}]
			}
		}
	}	
	##################################################oben und unten pblocks bestimmen
		for {set ab 0} {$ab<2} {incr ab} {
		
			if {$ab==0} {
				set start_index [expr {$act_pb_in_y_sorted + 1}]
				set end_index   [expr {[llength $y_sorted] - 1}]
				set last_element 0
				set found 0
				set next_clk_reg_add 1
				if {$act_pb_in_y_sorted==$end_index} {
					set last_element 1	
				}
				set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "ABOVE"]
			} else {
				set start_index [expr {$act_pb_in_y_sorted - 1}]
				set end_index 0
				set last_element 0 
				set found 0
				set next_clk_reg_add -1
				if {$act_pb_in_y_sorted==$end_index} {
					set last_element 1	
				}	
				set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "BELOW"]				
			}
			
			set pblocks_all_above_below {}
			
			while {$found==0} {		

			if {$last_element!=1} {
				set compare_pb [lindex [lindex $y_sorted $start_index] 0]

				set compare_clk_reg_pb_in [lindex $pBlock_clk_reg [search_String $pBlock_clk_reg $compare_pb 0]]	

					
				##########prüfen ob pBlock in der nächsten Region ist
					for {set y 1} {$y<[llength $act_clk_reg_pb_in]} {incr y} {
						set name_coor_act [get_name_coor [lindex $act_clk_reg_pb_in $y]]
						for {set z 1} {$z<[llength $compare_clk_reg_pb_in]} {incr z} {		
							set name_coor_compare [get_name_coor [lindex $compare_clk_reg_pb_in $z]]
							puts "coor_compare: $name_coor_compare"
							puts "name_coor_act: $name_coor_act"
							if {[expr {[lindex $name_coor_act 1] + $next_clk_reg_add}]==[lindex $name_coor_compare 1] && [lindex $name_coor_act 0]==[lindex $name_coor_compare 0]} {
								##prüfen ob in Liste schon enthalten
								if {[search_String $pblocks_all_above_below $compare_pb 1]==-1} {
									set pblocks_all_above_below [linsert $pblocks_all_above_below [llength $pblocks_all_above_below] $compare_pb]
								}

							}
						}
					}				
			} 

			if {$start_index==$end_index && [llength $pblocks_all_above_below]==0 || $last_element==1} {
				###wenn keine Pblöcke in der clockregion oberhalb gefunden oder letztes element
				set clk_coor_pb {}
				set found 1
				for {set y 1} {$y<[llength $act_clk_reg_pb_in]} {incr y} {
					set clk_reg_coor "[get_name_coor [lindex $act_clk_reg_pb_in $y]]"
					set clk_coor_pb [linsert $clk_coor_pb [llength $clk_coor_pb] $clk_reg_coor]
				}
				set clk_coor_pb [lsort -integer -index 0 $clk_coor_pb]
				set clk_region 0

				for {set clk 0 } {$clk<[llength $clk_coor_pb]} {incr clk} {
					set clk_reg_name "X[lindex [lindex $clk_coor_pb $clk] 0]Y[expr {[lindex [lindex $clk_coor_pb $clk] 1]  + $next_clk_reg_add}]"
					if {[search_String $all_clk_regions $clk_reg_name 1]!=-1 && $clk_region!=1} {
						set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "CLOCKREGION"]
						set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] $clk_reg_name]
						set clk_region 1
					} elseif {[search_String $all_clk_regions $clk_reg_name 1]!=-1} {
						set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] $clk_reg_name]
					} elseif {$clk_region!=1} {
						set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] "NONE"]
						set clk_region 1
					}	
				}
			} elseif {$start_index==$end_index && [llength $pblocks_all_above_below]!=0} {
				for {set elements 0} {$elements<[llength $pblocks_all_above_below]} {incr elements} {
					set pblock_spec_list [linsert $pblock_spec_list [llength $pblock_spec_list] [lindex $pblocks_all_above_below $elements]]				
				}			
				set found 1
			}	
			
			if {$ab==0} {
				incr start_index				
			} else {
				set start_index [expr {$start_index - 1}]
			}
		}
	}		
set blocks_around [linsert $blocks_around $x $pblock_spec_list]	       		
}

return $blocks_around
}
 ################################################################################################
 ###########################################################################################
 #																						   #
 #										draw_static_region                                 #
 #																						   #
 #																						   #
 ###########################################################################################

proc draw_static_region {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock_name {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -name { 
				set pblock_name [lshift args]
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
						[-name  <NAME>]
						
			Description: The procedure draw_static_region fills the free region around the pblocks with another pblock which contains all the tiles around
						 the placed pblocks in the design implementation. This procedure should be used in connection with the relocation flow. This procedure is limitted to pblocks
						 in the implementation design that are aligned to one clock region (not smaller not higher). Around the used pblocks in the design this procedure insertes fences around these pblocks
						 so the isolated design flow which is used in connection with this procedure is not violated.
						 
			Example:    draw_static_region -name static_region
			
			Return Example: Returns a list which contains the pblock names used in the design and coordinates which refer to the created fence by the procedure. 
							Actually this are not the exact coordinates of the created block with this procedure. Anyway it is possible to gain information about placed borders
							of the created pblock for further usage (like placing cells at the borders of CLB tiles)
			
							{pblock_1 LEFT 137 RIGHT 174 ABOVE NONE BELOW 53} {pblock_2 LEFT 137 RIGHT 174 ABOVE 51 BELOW 106}
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {[llength $pblock_name]==0} {
		return -code error {A name for the pblock should be specified}
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
set recon_instances [get_cells -hierarchical * -filter {RELOC==1}]

set top_instance [get_cells -filter {IS_PRIMITIVE==0}]
current_instance $top_instance
set instance_below_top [get_cells -filter {IS_PRIMITIVE==0}]
current_instance


set all_instances $instance_below_top 

 for {set x 0} {$x<[llength $recon_instances]} {incr x} {
	set all_instances [lremove $all_instances [lindex $recon_instances $x]]
}

set static_instance [get_cells -hierarchical -filter {RELOC_STATIC_PART==1} ]
 
#Pblocks enthalten in Liste , 1 Spalte 1 pBlock
set pblock_list [get_pblocks *]
set pBlocks [llength $pblock_list]
 
 ### liste mit pBlöcken für Rekonfiguration mit deren Koordinaten
set recon_Block_list [get_rect -pblocks $pblock_list -exact]

 #########schauen in welche clockregion die pBlöcke liegen 
 
set clk_regions [get_clk_region_coordinates -all]

 ##############erst links vom Pblock neuen pblock zeichnen
set draw_clk_regions {} 
set pBlock_points_in_clk_region {} 
set pBlock_clk_reg {}
set in_clk_reg 0
set create_rect_clk_regions [get_clock_regions]		
set recon_Block_list [get_rect -pblocks $pblock_list -exact]

set clk_regions [get_clk_region_coordinates -all]
set draw_clk_regions {} 

set create_rect_clk_regions [get_clock_regions]


 ############CLK Regionen in einer Spalte
 set clk_reg_nr {}
 set expression {}
 
 for {set x 0} {$x<[llength $create_rect_clk_regions]} {incr x} {
	set expression "[lindex $create_rect_clk_regions $x] [get_name_coor [lindex $create_rect_clk_regions $x]]"
	set clk_reg_nr [linsert $clk_reg_nr $x $expression]		 
 }
 
 set clk_reg_nr [lsort -integer -index 1 $clk_reg_nr]
 set clk_reg_row [expr {[lindex [lindex $clk_reg_nr [expr {[llength $clk_reg_nr] - 1}]] 1] - [lindex [lindex $clk_reg_nr 0] 1] + 1}]
	 
	 
	#################################################################################
	#			   in welchen clk regionen die Pblöcke liegen						#
	#################################################################################
		 
set pBlock_points_in_clk_region [pblock_in_clk_region -pblocks $pblock_list -exact]

set pBlock_clk_reg [pblock_in_clk_region -pblocks $pblock_list]
 ###################Nachbarn der einzelnen pblöcke bestimmen

 set blocks_around [get_pblock_neighbours -pblocks $pblock_list]

 ##herausfinden welche Clockregionen gezeichnet werden sollen 
for {set x 0} {$x<[llength $pBlock_clk_reg]} {incr x} {
   for {set y 1} {$y<[llength [lindex $pBlock_points_in_clk_region $x]]} {incr y} {
		set create_rect_clk_regions [lremove $create_rect_clk_regions [lindex [lindex $pBlock_points_in_clk_region $x] $y]]
	} 
}	

 ###Pblöcke für statische Region zeichnen ---> erstmal ganze clk_regionen drumherum zeichnen falls welche frei sind

set static_pblock_name $pblock_name
create_pblock $static_pblock_name
set add_cell_pBlock 0
	
	#############################################################################################
	#																							#
	#                                  Nicht belegte Clockregionen zeichnen                     #
	#																							#
	#############################################################################################
set all_clk_regions [get_clock_regions]
set clk_reg_coor [get_clk_region_coordinates -clk_regions $all_clk_regions] 
set dist_btw_clk_regs [expr {[lindex [lindex $clk_reg_coor 1] 1] - [lindex [lindex $clk_reg_coor 0] 3]}]
set dist_btw_clk_regs [expr {$dist_btw_clk_regs/2}]

set draw_ps_section 0
set occupied_clk_regions {}

 ##herausfinden ob pblöcke in X0Y1 und X0Y2 clockregion
for {set x 0} {$x<[llength $pBlock_clk_reg]} {incr x} {
	for {set y 1} {$y <[llength [lindex $pBlock_clk_reg $x]]} {incr y} {
		set clk_region_act [lindex [lindex $pBlock_clk_reg $x] $y]
		
		##ZYNQ klein: if {$clk_region_act=="X0Y1" || $clk_region_act=="X0Y0"}
		if {$clk_region_act==[lindex $GLOBAL_PBLOCK::ps_clk_region 0] || $clk_region_act==[lindex $GLOBAL_PBLOCK::ps_clk_region 1]} {
			set draw_ps_section 1
			set occupied_clk_regions [linsert $occupied_clk_regions [llength $occupied_clk_regions] $clk_region_act]
		}
	}
}



 
for {set x 0} {$x<[llength $create_rect_clk_regions]} {incr x} {
	set act_clk_reg_coor [lindex $clk_reg_coor [search_part_list $clk_reg_coor [lindex $create_rect_clk_regions $x]]]
	set add_clk_region "CLOCKREGION_[lindex $create_rect_clk_regions $x]:CLOCKREGION_[lindex $create_rect_clk_regions $x]"
	##ZYNQ klein: if {$draw_ps_section!=1 || [lindex $create_rect_clk_regions $x]!="X0Y1" && [lindex $create_rect_clk_regions $x]!="X0Y0"}
	if {$draw_ps_section!=1 || [lindex $create_rect_clk_regions $x]!=[lindex $GLOBAL_PBLOCK::ps_clk_region 0] && [lindex $create_rect_clk_regions $x]!=[lindex $GLOBAL_PBLOCK::ps_clk_region 1]} {
		resize_pblock $pblock_name -add $add_clk_region
		
		if {[lindex $act_clk_reg_coor 1]!=[lindex $GLOBAL_PBLOCK::x_range 0]} {
			draw_rect -add -x_ll [expr {[lindex $act_clk_reg_coor 1] - $dist_btw_clk_regs}] -y_ll [lindex $act_clk_reg_coor 2] -x_ur [lindex $act_clk_reg_coor 1] -y_ur [lindex $act_clk_reg_coor 4] -name $pblock_name 
		}
		
		if {[lindex $act_clk_reg_coor 3]!=[lindex $GLOBAL_PBLOCK::x_range 1]} {
			draw_rect -add -x_ll [lindex $act_clk_reg_coor 3] -y_ll [lindex $act_clk_reg_coor 2] -x_ur [expr {[lindex $act_clk_reg_coor 3] + $dist_btw_clk_regs}] -y_ur [lindex $act_clk_reg_coor 4] -name $pblock_name 	
		}
	}
}
	

if {$add_cell_pBlock==0} {
	add_cells_to_pblock $static_pblock_name [get_cells $static_instance] -clear_locs
}

 ###ps einheit einbinden
 if {$draw_ps_section==1} {
	draw_rect -add -x_ll 0 -y_ll 105 -x_ur 53 -y_ur 1 -name $static_pblock_name

	set draw_rest_ps_clk_region $GLOBAL_PBLOCK::ps_clk_region 

	for {set x 0} {$x<[llength $occupied_clk_regions]} {incr x} {
		set draw_rest_ps_clk_region [lremove $draw_rest_ps_clk_region [lindex $occupied_clk_regions $x]]
	} 
	
	for {set x 0} {$x<[llength $draw_rest_ps_clk_region]} {incr x} {
		set rest_clk_region_coordinates [get_clk_region_coordinates -clk_regions [lindex $draw_rest_ps_clk_region $x]]
		draw_rect -add -x_ll 54 -y_ll [lindex [lindex $rest_clk_region_coordinates 0] 2] -x_ur [lindex [lindex $rest_clk_region_coordinates 0] 3] -y_ur [lindex [lindex $rest_clk_region_coordinates 0] 4] -name $static_pblock_name
	}
}
	#############################################################################################
	#																							#
	#								Blöcke horizontal zeichnen									#
	#																							#
	#																							#
	#############################################################################################
	
	
set all_pb_coor_fence {}
set right_pb {}
for {set x 0} {$x<[llength $recon_Block_list]} {incr x} {

	puts "[lindex [lindex $recon_Block_list $x] 0]"
	set x_ll_pB0 [lindex [lindex $recon_Block_list $x] 1]
	set y_ll_pB0 [lindex [lindex $recon_Block_list $x] 2]
	set x_ur_pB0 [lindex [lindex $recon_Block_list $x] 3]
	set y_ur_pB0 [lindex [lindex $recon_Block_list $x] 4] 
	set x_ul_pB0 $x_ll_pB0
	set y_ul_pB0 $y_ur_pB0
	set x_lr_pB0 $x_ur_pB0
	set y_lr_pB0 $y_ll_pB0	
	
	set act_pb [search_part_list $blocks_around [lindex [lindex $recon_Block_list $x] 0]]
	
	###################	rl=0 ------------>left blöcke zeichnen
	###################	rl=1 ------------>right blöcke zeichnen
	set pb_coor_fence {}
	set pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]
	puts "[lindex [lindex $recon_Block_list $x] 0]"
	for {set rl 0} {$rl<2} {incr rl} {
		
		if {$rl==0} {
			set side [lindex [lindex $blocks_around $act_pb] [expr {[search_String [lindex $blocks_around $act_pb] LEFT 1] + 1}]]
			set x_corner $x_ul_pB0	
			puts "LEFT"
		} else {
			set side [lindex [lindex $blocks_around $act_pb] [expr {[search_String [lindex $blocks_around $act_pb] RIGHT 1] + 1}]]
			set x_corner $x_ur_pB0
			puts "RIGHT"
		}
		set fence 1
		set i 1
		while {$fence} {
			if {$rl==0} {
				set filter_expr "ROW>=$y_ul_pB0 && ROW<=[expr {$y_lr_pB0}] && COLUMN==[expr {$x_ul_pB0 - $i}] && TILE_TYPE!=NULL"		
			} else {
				set filter_expr "ROW>=$y_ul_pB0 && ROW<=[expr {$y_lr_pB0}] && COLUMN==[expr {$x_ur_pB0 + $i}] && TILE_TYPE!=NULL"			
			}
			
			if {[search_String $GLOBAL_PBLOCK::iso_fence_types [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr]] 0] 1]!=-1} {
				#puts "TILE_TYPE: [get_property TILE_TYPE [get_tiles -filter $filter_expr]]"
				if {$rl==0} {
					set fence_row [expr {$x_corner - $i}]			
				} else {
				set fence_row [expr {$x_corner + $i}]				
				}

				set fence 0			
			}
				incr i			
		}
		puts "fence_row: $fence_row"
		set neighbour_of_ps_section 0

		if {$draw_ps_section==1} {
			set actual_pblock_clk_reg [pblock_in_clk_region -pblocks [lindex [lindex $recon_Block_list $x] 0]]
			for {set n 0} {$n<[llength $actual_pblock_clk_reg]} {incr n} {
				for {set p 1} {$p <[llength [lindex $actual_pblock_clk_reg $n]]} {incr p} {
					set clk_region_act [lindex [lindex $actual_pblock_clk_reg $n] $p]
					set y_clk_coor [cutString $clk_region_act [string first Y $clk_region_act 0] [string length $clk_region_act]]
					if {$y_clk_coor=="Y1" || $y_clk_coor=="Y2"} {
						set neighbour_of_ps_section 1
					}
				}
			}		
		}

		puts "pblock: [lindex [lindex $recon_Block_list $x] 0]"
		puts "neighbour_of_ps_section: $neighbour_of_ps_section"
		puts "side: $side"
		
		if {$side=="CLOCKREGION"} {
			####bestimmen der Clockregion 
			if {$rl==0} {
				set clock_region_neighbour [lindex [lindex $blocks_around $act_pb] [expr {[search_String [lindex $blocks_around $act_pb] LEFT 1] + 2}]]			
			} else {
				set clock_region_neighbour [lindex [lindex $blocks_around $act_pb] [expr {[search_String [lindex $blocks_around $act_pb] RIGHT 1] + 2}]]			
			}

			set coor_neighbour [lindex [get_clk_region_coordinates -clk_regions $clock_region_neighbour] 0]
		
			###############Entscheiden ob Zellen löschen von Clockregion oder hinzufügen
			if {$fence_row<=[lindex $coor_neighbour 3] && $rl==0} {
				puts "fence in clockregion"
				if {$neighbour_of_ps_section==1} {
					set x_ur_left [expr {$fence_row - 1}]
					set y_ur_left $y_ur_pB0
					set x_ll_left [expr {[lindex $coor_neighbour 3] + 1}]
					set y_ll_left $y_ll_pB0
					draw_rect -add -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name						
				} else {
					set x_ur_left [lindex $coor_neighbour 3]
					set y_ur_left $y_ur_pB0
					set x_ll_left $fence_row
					set y_ll_left $y_ll_pB0
				draw_rect -remove -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name				
				}
			} elseif {$fence_row>=[lindex $coor_neighbour 1] && $rl==1} {
					set x_ur_left $fence_row
					set y_ur_left $y_ur_pB0
					set x_ll_left [lindex $coor_neighbour 1]
					set y_ll_left $y_ll_pB0
				draw_rect -remove -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name			
			} else {
				puts "fence not in clcokregion-->rl: $rl"
				if {$rl==0} {
					set x_ur_left [expr {$fence_row - 1}]
					set y_ur_left $y_ur_pB0
					if {$neighbour_of_ps_section==1} {
						set x_ll_left 54
					} else {
						set x_ll_left [expr {[lindex $coor_neighbour 3] + 1}]
					}
					set y_ll_left $y_ll_pB0
				} else {
					set x_ur_left [expr {[lindex $coor_neighbour 1] - 1}]
					set y_ur_left $y_ur_pB0
					set x_ll_left [expr {$fence_row + 1}]
					set y_ll_left $y_ll_pB0				
				}
				puts "draw_rect -add -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name"
				draw_rect -add -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name				
			}	
		} elseif {$side=="NONE"} {
				if {$rl==0} {
					set x_ur_left [expr {$fence_row - 1}]
					set y_ur_left $y_ur_pB0
					if {$neighbour_of_ps_section==1} {
						set x_ll_left 54
					} else {
						set x_ll_left [lindex $GLOBAL_PBLOCK::x_range 0]
					}	
					set y_ll_left $y_ll_pB0	
					puts "NONE LEFT"
				} else {
					set x_ur_left [lindex $GLOBAL_PBLOCK::x_range 1]
					set y_ur_left $y_ur_pB0
					set x_ll_left [expr {$fence_row + 1}]
					set y_ll_left $y_ll_pB0
					puts "NONE RIGTH"					
				}
				
				puts "draw_rect -add -x_ll_left $x_ll_left -y_ll_left $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name"
				draw_rect -add -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name		
		} else {
			################suchen vom benachbarten fence	
			if {$rl==0} {
				set nb_coor [lindex $recon_Block_list [search_String $recon_Block_list $side 0]]
				set y_ur_nb [lindex $nb_coor 4]
				set y_lr_nb [lindex $nb_coor 2]
				set x_ur_nb [lindex $nb_coor 3]		
				set fence_nb 1
				set i 1					
				while {$fence_nb} {
					set filter_expr_nb "ROW>=$y_ur_nb && ROW<=[expr {$y_lr_nb}] && COLUMN==[expr {$x_ur_nb + $i}] && TILE_TYPE!=NULL"
					if {[search_String $GLOBAL_PBLOCK::iso_fence_types [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr_nb]] 0] 1]!=-1} {
						set fence_row_nb [expr {$x_ur_nb + $i}]
						set fence_nb 0			
					}
					incr i
				}
				
				if {$fence_row_nb<$x_ll_pB0} {

					set x_ur_left [expr {$fence_row - 1}]
					set y_ur_left $y_ur_pB0
					set x_ll_left [expr {$fence_row_nb + 1}]
					set y_ll_left $y_ll_pB0	
					draw_rect -add -x_ll $x_ll_left -y_ll $y_ll_left -x_ur $x_ur_left -y_ur $y_ur_left -name $static_pblock_name
					set pb_direct_neighbour 0
				} else {
					set x_ur_left $x_ur_pB0
					set y_ur_left $y_ur_pB0
					set x_ll_left $x_ll_pB0
					set y_ll_left $y_ll_pB0
					set pb_direct_neighbour 1
				}
			} 
		}
		
		puts "side: $side"
		puts "ACT_PB: [lindex [lindex $recon_Block_list $x] 0]"
		puts "ALL_PB_COOR_FENCE: $all_pb_coor_fence"
		puts "PB:COOR_FENCE: $pb_coor_fence" 		
		
		if {$rl==0} {
			if {$side!="CLOCKREGION" && $side!="NONE"} {
				if {$pb_direct_neighbour==1} {
					set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] LEFT]
					set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] [lindex $nb_coor 3]]						
				} else {
					set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] LEFT]
					set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] $x_ur_left]				
				}
				if {[search_String $all_pb_coor_fence $side 0]!=-1} {
					##schauen ob $side schon in der großen Liste vorhanden-->ja: dann RIGHT hinzufügen mit Koordinaten..wenn nicht dann right_pb schreiben
					puts "llength sub_pb_coor_fence: [lindex $all_pb_coor_fence [search_String $all_pb_coor_fence $side 0]]"
					if {[search_String [lindex $all_pb_coor_fence [search_String $all_pb_coor_fence $side 0]] RIGHT 1]==-1} {
						set length [llength [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence $side]]]
						set pb_coor_fence_help [linsert  [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence $side]] $length RIGHT]
						set pb_coor_fence_help [linsert  $pb_coor_fence_help [llength $pb_coor_fence_help] $x_ll_left]
						puts "PB_HELP: $pb_coor_fence_help"
						set all_pb_coor_fence [lreplace $all_pb_coor_fence [search_part_list $all_pb_coor_fence $side] [search_part_list $all_pb_coor_fence $side] $pb_coor_fence_help]
					}
				} else {
					puts "RIGTH_PB: $right_pb"
					set right_pb [linsert $right_pb [llength $right_pb] $side]
					set right_pb [linsert $right_pb [llength $right_pb] RIGHT]
					set right_pb [linsert $right_pb [llength $right_pb] $x_ll_left]					
				}			
			} else {
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] LEFT]
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] $x_ur_left]				
			}
		} else {
			if {$side=="CLOCKREGION" || $side=="NONE"} {
				puts "RIGHT_PB_2"
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] RIGHT]
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] $x_ll_left]			
			} 

			if {[search_String $right_pb  [lindex [lindex $recon_Block_list $x] 0] 0]!=-1} {
				puts "RIGHT_PB_3"
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] RIGHT]
				set pb_coor_fence [linsert $pb_coor_fence [llength $pb_coor_fence] [lindex $right_pb [expr {[search_String $right_pb  [lindex [lindex $recon_Block_list $x] 0] 0]+2}]]]						
			}
		}
	}
	set all_pb_coor_fence [linsert $all_pb_coor_fence [llength $all_pb_coor_fence] $pb_coor_fence]	
}

puts "NACH HORIZONTAL ZEICHNEN: $all_pb_coor_fence"	


	#############################################################################################
	#############################################################################################
for {set x 0} {$x<[llength $recon_Block_list]} {incr x} {
	puts "AKTUELLER BLOCK: [lindex [lindex $recon_Block_list $x] 0]"
	set x_ll_pB0 [lindex [lindex $recon_Block_list $x] 1]
	set y_ll_pB0 [lindex [lindex $recon_Block_list $x] 2]
	set x_ur_pB0 [lindex [lindex $recon_Block_list $x] 3]
	set y_ur_pB0 [lindex [lindex $recon_Block_list $x] 4] 
	set x_ul_pB0 $x_ll_pB0
	set y_ul_pB0 $y_ur_pB0
	set x_lr_pB0 $x_ur_pB0
	set y_lr_pB0 $y_ll_pB0	
	
	set act_pb [search_part_list $blocks_around [lindex [lindex $recon_Block_list $x] 0]]

	for {set ab 0} {$ab<2} {incr ab} {
		if {$ab==0} {
			puts "ABOVE FENCE"
			set pb_list_start [search_String [lindex $blocks_around $act_pb] ABOVE 1]
			set pb_list_end   [search_String [lindex $blocks_around $act_pb] BELOW 1]
		} else {
			puts "BELOW FENCE"
			set pb_list_start [search_String [lindex $blocks_around $act_pb] BELOW 1]
			set pb_list_end   [llength [lindex $blocks_around $act_pb]]			
		}
		set fence 1
		set i 1 
		puts "pb_list_start: $pb_list_start"
	    if {[lindex [lindex $blocks_around $act_pb] [expr {$pb_list_start+1}]]!="NONE"} {	
			if {[lindex [lindex $blocks_around $act_pb] [expr {$pb_list_start+1}]]=="CLOCKREGION"} {
				set pb_fences [lindex $all_pb_coor_fence [search_part_list $blocks_around [lindex [lindex $recon_Block_list $x] 0]]]
				puts "PB_FENCES: $pb_fences"
				set x_ll_hor [lindex $pb_fences [expr {[search_String $pb_fences LEFT 1] + 1}]]
				set x_ur_hor [lindex $pb_fences [expr {[search_String $pb_fences RIGHT 1] + 1}]]
				set x_ll_hor [expr {$x_ll_hor + 1}]
				set x_ur_hor [expr {$x_ur_hor - 1}]
			}
		
			if {$ab==0} {
				while {$fence} {
					set filter_expr "ROW==[expr {$y_ur_pB0 - $i}] && COLUMN>=$x_ll_pB0 && COLUMN<=$x_ur_pB0 && TILE_TYPE!=NULL"
					puts "filter_expr ab==0: $filter_expr"
					if {[llength [get_tiles -filter $filter_expr]]!=0} {
						set tile_types [get_property TILE_TYPE [get_tiles -filter $filter_expr]]	
						for {set n 0} {$n<[llength $tile_types]} {incr n} {		
							if {[search_String $GLOBAL_PBLOCK::iso_fence_types [lindex $tile_types $n] 1]!=-1} {
								set y_ll_hor [expr {$y_ur_pB0 - 1}]
								set y_ur_hor [expr {$y_ur_pB0 - $i}]         			
								set fence 0
								break
							}								
						} 
					} else {
							set y_ll_hor [expr {$y_ur_pB0 - 1}]
							set y_ur_hor [expr {$y_ur_pB0 - 1}] 
							set fence 0
							break						
					}
					incr i
				}
			} else {
				while {$fence} {
					set filter_expr "ROW==[expr {$y_lr_pB0 + $i}] && COLUMN>=$x_ll_pB0 && COLUMN<=$x_ur_pB0 && TILE_TYPE!=NULL"
					if {[llength [get_tiles -filter $filter_expr]]!=0} {
						set tile_types [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
						for {set n 0} {$n<[llength $tile_types]} {incr n} {		
							if {[search_String $GLOBAL_PBLOCK::iso_fence_types [lindex $tile_types $n] 1]!=-1} {
								set y_ll_hor [expr {$y_lr_pB0 + $i}]							
								set y_ur_hor [expr {$y_lr_pB0 + 1}]
								set fence 0
								break
							}								
						} 
						incr i
					} else {
						set y_ll_hor [expr {$y_lr_pB0 + 1}]							
						set y_ur_hor [expr {$y_lr_pB0 + 1}]
						set fence 0
						break					
					}
				}
			}
		} else {
			if {$ab==0} {
				set y_ll_content NONE
			} else {
				set y_ur_content NONE			
			}
		}
	
		if {[lindex [lindex $blocks_around $act_pb] [expr {$pb_list_start+1}]]=="CLOCKREGION"} {
			puts "AB: $ab  ---------->draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name"
			if {$ab==0} {
				set y_ll_content [expr {$y_ur_hor - 1}]
			} else {
				set y_ur_content [expr {$y_ll_hor + 1}]	
			}
			draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name		
		} elseif {[lindex [lindex $blocks_around $act_pb] [expr {$pb_list_start+1}]]!="NONE"} {	 
			set pb_ab {}


			for {set y [expr {$pb_list_start + 1}]} {$y<$pb_list_end} {incr y} {
				set pb_ab [linsert $pb_ab [llength $pb_ab] [lindex $recon_Block_list [search_part_list $recon_Block_list [lindex [lindex $blocks_around $act_pb] $y]]]]
			}
			puts "pb_ab: $pb_ab"
			set pb_ab [lsort -integer -increasing -index 1 $pb_ab]

			set exact_pb_ab {}
			set delete_elements {}
			set fence_left [lindex [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]] 2]]
			set fence_right [lindex [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]]] 4]
			set fence_left [expr {$fence_left + 1}]
			set fence_right [expr {$fence_right - 1}]

			##schauen welche blöcke direkt über dem pblock sind 
			for {set y 0} {$y<[llength $pb_ab]} {incr y} {
				set x_ll_pb [lindex [lindex $pb_ab $y] 1]
				set x_ur_pb [lindex [lindex $pb_ab $y] 3]
				set above_below_pb 0
				set exact_pb_ab [linsert $exact_pb_ab [llength $exact_pb_ab] [lindex $pb_ab $y]]
				
				if {$x_ll_pb>$x_ll_pB0 && $x_ur_pb<$x_ur_pB0} {
					set new_pb_ab [linsert [lindex $exact_pb_ab $y] 0 FULLY]
					incr above_below_pb
				} elseif {$x_ll_pb<=$x_ll_pB0 && $x_ur_pb<$x_ur_pB0 && $x_ur_pb>=$x_ll_pB0} {
					set new_pb_ab [linsert [lindex $exact_pb_ab $y] 0 LEFT_PART]
					incr above_below_pb		
				} elseif {$x_ur_pb>=$x_ur_pB0 && $x_ll_pb>$x_ll_pB0 && $x_ll_pb<=$x_ur_pB0} {
					set new_pb_ab [linsert [lindex $exact_pb_ab $y] 0 RIGHT_PART]
					incr above_below_pb	
				} elseif {$x_ur_pb>=$x_ur_pB0 && $x_ll_pb<=$x_ll_pB0} {
					set new_pb_ab [linsert [lindex $exact_pb_ab $y] 0 BIGGER]
					incr above_below_pb				
				} else {
					set new_pb_ab [linsert [lindex $exact_pb_ab $y] 0 OUTSIDE]
					incr above_below_pb									 
				}				
				puts "new_pb_ab: $new_pb_ab"
				if {$above_below_pb>0} {
					set exact_pb_ab [lremove_element $exact_pb_ab [search_part_list $exact_pb_ab [lindex [lindex $pb_ab $y] 0]]]
					set exact_pb_ab [linsert $exact_pb_ab [llength $exact_pb_ab] $new_pb_ab]		
				} 
			}
			
			if {[search_part_list $exact_pb_ab RIGHT_PART]!=-1} {
				set y_ll_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab RIGHT_PART] 0]] 3]
				set y_ur_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab RIGHT_PART] 0]] 5] 
			} elseif {[search_part_list $exact_pb_ab LEFT_PART]!=-1} {
				set y_ll_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab LEFT_PART] 0]] 3]
				set y_ur_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab LEFT_PART] 0]] 5] 				
			} elseif {[search_part_list $exact_pb_ab FULLY]!=-1} {
				set y_ll_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab FULLY] 0]] 3]
				set y_ur_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab FULLY] 0]] 5]				
			} elseif {[search_part_list $exact_pb_ab BIGGER]!=-1} {
				set y_ll_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab BIGGER] 0]] 3]
				set y_ur_content [lindex  [lindex $exact_pb_ab [lindex [search_part_list $exact_pb_ab BIGGER] 0]] 5]				
			} else {
				set y_ll_content [expr {$y_ur_hor - 1}]
				set y_ur_content [expr {$y_ll_hor + 1}]					
			}
			
		##löschen der blöcke aus liste, die nicht über pblock liegen

			puts "[lindex [lindex $recon_Block_list $x]] --->exact_pb_ab: $exact_pb_ab"
		####################Ab hier wird gezeichnet	
			set left_side_ab  [search_part_list $exact_pb_ab LEFT_PART]
			set right_side_ab [search_part_list $exact_pb_ab RIGHT_PART]	

		for {set y 0} {$y<[llength $exact_pb_ab]} {incr y} {		
				set pb_ab_part [lindex [lindex $exact_pb_ab $y] 0]
				puts "pb_ab_part: $pb_ab_part "
				puts "y:$y"
				
				if {$pb_ab_part=="OUTSIDE" && [search_part_list $exact_pb_ab RIGHT_PART]==-1 && [search_part_list $exact_pb_ab LEFT_PART]==-1 && [search_part_list $exact_pb_ab FULLY]==-1 && [search_part_list $exact_pb_ab BIGGER]==-1} {
						puts "OUTSIDE1"
						set x_ur_hor $fence_right
						set x_ll_hor $fence_left
						draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name
				} else {
					if {$pb_ab_part=="BIGGER"} {
						puts "NO FENCE DRAWN"
						break
					}			 
					if {$pb_ab_part=="LEFT_PART"} {
						set x_ll_hor [expr {[lindex [lindex $exact_pb_ab $y] 4] + 1}]
						if {[llength $exact_pb_ab]==1} {
							puts "L1"
							set x_ur_hor $fence_right
						} else {
							puts "L2"
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab [expr {$y + 1}]] 2] - 1}]					
						}
					} 
					
					if {$pb_ab_part=="FULLY" && [llength $exact_pb_ab]!=1} {
						if {$left_side_ab==-1 && y==0} {
							puts "F1"
							set x_ll_hor $fence_left
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab $y] 2] - 1}]
						} elseif {$left_side_ab!=-1 && $y<[expr {[llength $exact_pb_ab] - 1}]} {
							puts "F2"
							set x_ll_hor [expr {[lindex [lindex $exact_pb_ab $y] 4] + 1}]
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab [expr {$y + 1}]] 2] - 1}]
						} elseif {$left_side_ab==-1 && $y>0} {
							puts "F3"
							set x_ll_hor [expr {[lindex [lindex $exact_pb_ab [expr {$y - 1}]] 4] + 1}]
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab $y] 2] - 1}]			
						}
						
						if {$right_side_ab==-1 && $y==[expr {[llength $exact_pb_ab] - 1}]} {
							puts "F4"
							set x_ll_hor [expr {[lindex [lindex $exact_pb_ab $y] 4] + 1}]
							set x_ur_hor $fence_right
						}
					}
					
					if {$pb_ab_part=="RIGHT_PART"} {
						if {$left_side_ab==-1 && $y==0} {
							puts "R1"
							set x_ll_hor $fence_left
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab $y] 2] - 1}]
						} elseif {$left_side_ab!=-1} {
							puts "R2"
							set x_ll_hor [expr {[lindex [lindex $exact_pb_ab [expr {$y - 1}]] 4] + 1}]
							set x_ur_hor [expr {[lindex [lindex $exact_pb_ab $y] 2] - 1}]					
						}		
					}
					
					if {$pb_ab_part=="FULLY" && [llength $exact_pb_ab]==1} {
						puts "1 FULLY BLOCK"
						set x_ll_hor $fence_left
						set x_ur_hor [expr {[lindex [lindex $exact_pb_ab $y] 2] - 1}]
						draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name
						set x_ll_hor [expr {[lindex [lindex $exact_pb_ab $y] 4] + 1}]
						set x_ur_hor $fence_right
						draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name
					} elseif {[expr {$x_ur_hor - $x_ll_hor}]!=1 && [llength $exact_pb_ab]==1} {
						draw_rect -remove -x_ll $x_ll_hor -y_ll $y_ll_hor -x_ur $x_ur_hor -y_ur $y_ur_hor -name $static_pblock_name
					}	
				}
			}
		}
			if {$ab==0} {
				set fence_pb_content [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]]]
				set fence_pb_content [linsert  $fence_pb_content [llength $fence_pb_content] ABOVE]
				set new_fence [linsert  $fence_pb_content [llength $fence_pb_content] $y_ll_content]
				set all_pb_coor_fence [lreplace $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]] [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]] $new_fence]
			} else {
				set fence_pb_content [lindex $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]]]
				set fence_pb_content [linsert  $fence_pb_content [llength $fence_pb_content] BELOW]
				set new_fence [linsert  $fence_pb_content [llength $fence_pb_content] $y_ur_content]
				set all_pb_coor_fence [lreplace $all_pb_coor_fence [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]] [search_part_list $all_pb_coor_fence [lindex [lindex $recon_Block_list $x] 0]] $new_fence]				
			}	
	}
}

return $all_pb_coor_fence
}

 ###########################################################################################
 #																						   #
 #										get_slices		                                   #
 #																						   #
 #																						   #
 ###########################################################################################

 proc get_slices {args} {
   #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock {}
 set ret_all 0
 set side {}
 set start_point {}
 set row {}
 set tile_type_borders 0
 set slice_column 0
 set error 0
 set help 0
 set exact 0 
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblock { 
				set pblock [lshift args]
			  }
			  -side {
				set side [lshift args]
			  }
			  -start {
				set start_point [lshift args]
			  }
			  -slice_column {
				incr slice_column
			  }
			  -return_all {
				incr ret_all
			  }		  
			  -search_in_row {
				set row [lshift args]				
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
						[-pblock <pblock_name>] [optional]
						[-side   <LEFT/RIGHT>]
						[-start  <starting_point>]
						[-slice_column  <>] [optional]
						[-search_in_row <row_number>] [optional]
						
			Description: Searches for CLB sites in columns in size of the y range of the pblock assigned. Direction search from the borders of the pblock, when assigned [Example 1].
						 Also you can search for CLB sites only in one specific row [Example 2] in LEFT or in RIGHT side of the start point. 
						 By assigning option slice_column you get the return value where the sites where found. When not assigned you get the sites at this position returned.

						 
			Example 1:   get_slices -pblock pblock_1 -side LEFT -start 128
			Example 2:   get_slices  -side LEFT -start 128 -search_in_row 20
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {[llength $side]==0 || [llength $start_point]==0} {
		return -code error {get_slices: Some of the options are note correctly specified}	  
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
 
	if {[llength $pblock]!=0} {
		set pblock_coor [get_rect -pblocks $pblock -exact]
		set cnt_end 2
	} else {
		set cnt_end 1
	}
	 ###nur nach CLB'S suchen 
	 set CLB_TYPES {}
	 for {set x 0} {$x<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr x} {
		set act_clb_types [lindex $GLOBAL_PBLOCK::compatibel_clbs $x]
		for {set y 0} {$y<[llength $act_clb_types]} {incr y} {
			set CLB_TYPES [linsert $CLB_TYPES [llength $CLB_TYPES] [lindex $act_clb_types $y]]
		}
	 }
	 set sites_in_column {}
	 set end 0
	 set i   0
	 set inside 0
	 
	 while {$end==0} {
		if {$side=="LEFT"} {
			if {[llength $pblock]!=0} {
				set filter_expr "ROW<=[lindex [lindex $pblock_coor 0] 2] && ROW>=[lindex [lindex $pblock_coor 0] 4] && COLUMN==[expr {$start_point - $i}] && TILE_TYPE!=NULL"
			} else {
				set filter_expr "ROW==$row && COLUMN==[expr {$start_point - $i}] && TILE_TYPE!=NULL"
			}
			set last_value [expr {$start_point - $i}]
			if {$last_value<[lindex $GLOBAL_PBLOCK::x_range 0]} {
				incr end
			}
			if {[expr {$start_point - $i}]<[lindex $GLOBAL_PBLOCK::x_range 0]} {
				set end 1 
				set last_value -1
				set sites_in_column {}
				break
			}
			
		} else {
		    if {[llength $pblock]!=0} {
				set filter_expr "ROW<=[lindex [lindex $pblock_coor 0] 2] && ROW>=[lindex [lindex $pblock_coor 0] 4] && COLUMN==[expr {$start_point + $i}] && TILE_TYPE!=NULL"
			} else {
				set filter_expr "ROW==$row && COLUMN==[expr {$start_point + $i}] && TILE_TYPE!=NULL"
			}
			set last_value [expr {$start_point + $i}]
			if {[expr {$start_point + $i}]>[lindex $GLOBAL_PBLOCK::x_range 1]} {
				incr end
			}
			if {[expr {$start_point + $i}]>[lindex $GLOBAL_PBLOCK::x_range 1]} {
				set end 1 
				set last_value -1
				set sites_in_column {}
				break
			}			
		}
		
		if {$end==0} { 
			if {[llength [get_tiles -filter $filter_expr -quiet]]!=0} {
				set tile_types [get_property TILE_TYPE [get_tiles -filter $filter_expr] -quiet]
				for {set x 0} {$x<[llength $CLB_TYPES]} {incr x} {
					if {[search_String $tile_types [lindex $CLB_TYPES $x] 1]!=-1} {
						incr inside
						break
					}
				}
				if {$inside==$cnt_end} {
					set sites_in_column [get_sites -of_objects [get_tiles -filter $filter_expr] -quiet]
					incr end				
				}
			}			
			incr i
		}
	 }
	 
	 set return_value {}
	 set return_value [linsert $return_value 0 $sites_in_column]
	 set return_value [linsert $return_value 1 $last_value]
	 
	 if {$slice_column} {
		return $last_value
	 } elseif {$ret_all} {
		return $return_value
	 } else {
		return $sites_in_column	 
	 }

	 
 }
 ################################################################################################	
	

  ###########################################################################################
 #																						   #
 #										get_site_position                                  #
 #																						   #
 #																						   #
 ###########################################################################################
 
 ##determine position of slices
 proc get_site_position {site} {
	set tile [get_tiles -of_objects [get_sites $site]]
	set sorted_sites_in_tile [lsort -increasing [get_sites -of_objects [get_tiles $tile]]]
	
	if {[search_String $sorted_sites_in_tile $site 1]==0} {
		return 0
	} elseif {[search_String $sorted_sites_in_tile $site 1]==1} {
		return 1
	} else {
		return -1
	}
}


		 
proc search_fence {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set side {}
 set pblock {}
 set ret_fence 0
 set ret_all 0
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -side { 
				set side [lshift args]
			  }
			  -pblock {
				set pblock [lshift args]
			  }
			  -return_fence_column {
				incr ret_fence
			  }
			  -return_all {
				incr ret_all
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
						[-pblock <pblock>] ---------- pblock for example => {pblock_1 133 51 162 1}
                        [-side <LEFT/RIGHT>]
						[-return_fence_column <>] [optional]	
						[-return_all <>] [optional]						

						Description: Searches for next fence tiles in left or right direction determined by -side from the pblock borders y_ll and y_ur of defined pblock under -pblock. Is the option 
						-return_fence_colum denoted the function returns the x coordinate of the found tile. If option -return_all is denoted the function returns the tiles between pblock and fence

						 
			Example 1:   search_fence -pblock {pblock_1 133 51 162 1} -side LEFT -return_fence_column
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
	  if {[llength $side]==0} {
		return -code error {No argument for side is chosen to determine fence search direction }
	  }
	  
	  if {[llength $pblock]==0} {
		return -code error {No argument for pblock is chosen}
	  }
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
  		set rect_pblock [join $pblock " "] 
		set fence 1
		set i 1		
		set tiles_order_from_pb_border {}
		
		if {$side=="LEFT"} {
			set start_column [expr {[lindex $rect_pblock 1] - $i}]
		} else {
			set start_column [expr {[lindex $rect_pblock 3] + $i}]
		}		
		
		while {$fence} {
			if {$side=="LEFT"} {
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
				set tile_type [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr]] 0]
				set tiles_order_from_pb_border [linsert $tiles_order_from_pb_border [llength $tiles_order_from_pb_border] $tile_type]
			}			
			
			if {[search_String $GLOBAL_PBLOCK::iso_fence_types [lindex $tile_type 0] 1]!=-1 && $fence!=0} {
				if {$side=="LEFT"} {
					set fence_column [expr {[lindex $rect_pblock 1] - $i}]			
				} else {
					set fence_column [expr {[lindex $rect_pblock 3] + $i}]				
				}

				set fence 0			
			}
				incr i			
		}
		
		set end_column $fence_column
		
		if {$ret_fence==1 && $ret_all==0} {
			return $end_column
		}
		
		set return_all {}
		if {$ret_all} {
			set return_all [linsert $return_all 0 $start_column]
			set return_all [linsert $return_all 1 $end_column]
			set return_all [linsert $return_all 2 $tiles_order_from_pb_border]
			set return_all [join $return_all " "]
		}
			 
}

proc get_compatibel_pblock_pattern {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock {}
 set interface_side {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblock { 
				set pblock [lshift args]
			  }	
			  -interface_side { 
				set interface_side [lshift args]
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
						[-pblock <Pblock_1>]
						[-interface_side <LEFT/RIGHT>]

						
			Description: Finds identical Pblock pattern with identical interface sides
			 
			Example:    get_compatibel_pblock_pattern -pblock Pblock_1 -interface_side LEFT 
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------

  set compatibel_bram_dsp {{BRAM_L DSP_L} {BRAM_R DSP_R}}
 ###full identical search for reconfiguration flow pattern
  set pblock_name $pblock 
  set pblock_whole [get_rect -pblocks $pblock -exact]
  set pblock [lremove_element [join $pblock_whole] 0] 
  set recon_pblock [get_cells -hierarchical -filter {BLACK_BOX==TRUE}]
  set pins_rcell [llength [get_pins -of_objects [get_cells [lindex $recon_pblock 0]]]]
  
  ##defining how much slices in one column
  set clk_regions [lindex [get_clk_region_coordinates -all] 0]
  set slice_position [get_slices -side RIGHT -start 0 -search_in_row 1 -slice_column]
  set filter_expr "COLUMN==$slice_position && ROW>=[lindex $clk_regions 4] && ROW<=[lindex $clk_regions 2] && TYPE=~CLB*"
  set slices_nr_column [llength [get_sites -of_objects [get_tiles -filter $filter_expr]]]
  
  ##determine if more interface nets next clb search
  set lut_nr [llength $GLOBAL_PBLOCK::slice_lut]
  set multiple_clbs [expr {round (double ($pins_rcell/($slices_nr_column*$lut_nr)))}]
  
  set filter_expr "ROW==[lindex $pblock 1] && COLUMN>=[lindex $pblock 0] && COLUMN<=[lindex $pblock 2]"
  set ref_pblock_tiles [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
  set pblock_width [expr {[lindex $pblock 2] - [lindex $pblock 0]}]

  set all_clock_regions [get_clock_regions]
  
  set equal_pattern {}
  set equal_pattern_nr 0
  
  ##emulate the interface_side
  ##find fence_column
  set ref_fence_column [search_fence -pblock $pblock_whole -side $interface_side -return_fence_column]  
  ##search for second clb column from ref_rence_column
  set 2nd_clb_column [search_second_clb_column -pblock $pblock_name -interface_side $interface_side -start_search $ref_fence_column]
  set start_search 0
  set incr_clb_search 0
  if {$interface_side=="LEFT"} {
	set arith -1
  } else {
	set arith  1
  }
  ##search for next clb when more interfaces needed
  while {$start_search==0} {
	if {$multiple_clbs!=0 && $incr_clb_search<=$multiple_clbs} {
		set 2nd_clb_column [get_slices -side $interface_side -start [expr {$2nd_clb_column + $arith}] -search_in_row [lindex [lindex $pblock_whole 0] 2] -slice_column]
	} else {
		set start_search 1
	}
	 incr incr_clb_search	
  }
  
  if {$interface_side=="LEFT"} {
	set filter_expr "ROW==[lindex $pblock 1] && COLUMN>=$2nd_clb_column && COLUMN<=$ref_fence_column"
  } else {
	set filter_expr "ROW==[lindex $pblock 1] && COLUMN>=$ref_fence_column && COLUMN<=$2nd_clb_column"  
  }
  ##emulated interface side
  set ref_interface_tiles [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
  
  set filtered_ref_inf_tiles {}
  for {set x 0} {$x<[llength $ref_interface_tiles]} {incr x} {
	if {[lsearch -exact $GLOBAL_PBLOCK::iso_fence_types [lindex $ref_interface_tiles $x]]!=-1} {
	  set filtered_ref_inf_tiles [linsert $filtered_ref_inf_tiles [llength $filtered_ref_inf_tiles] [lindex $ref_interface_tiles $x]]
	}
  }
  
  if {$interface_side=="LEFT"} {
    set help [expr {[llength $filtered_ref_inf_tiles]-1}] 
  } else {
    set help 1
  }
  
 # set filtered_ref_inf_tiles_clb {}  
  #if {[llength $filtered_ref_inf_tiles]>3 && [lsearch -glob [lindex $filtered_ref_inf_tiles $help] CLB*]!=-1} {
  # for {set x 0} {$x<[llength $ref_interface_tiles]} {incr x} {
	#if {[lsearch -exact $GLOBAL_PBLOCK::iso_fence_types [lindex $filtered_ref_inf_tiles $x]]!=-1} {
	 # set filtered_ref_inf_tiles_clb [linsert $filtered_ref_inf_tiles_clb [llength $filtered_ref_inf_tiles_clb] [lindex $filtered_ref_inf_tiles $x]]
	#}
 # }
  #set filtered_ref_inf_tiles $filtered_ref_inf_tiles_clb  
  #}
  
   set filtered_ref_inf_tiles_clb {}  
  if {[llength $filtered_ref_inf_tiles]>3} {
   for {set y 0} {$y<[llength $filtered_ref_inf_tiles]} {incr y} {
	if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] [lindex $filtered_ref_inf_tiles $y]]!=-1 || [lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] [lindex $filtered_ref_inf_tiles $y]]!=-1 || $y==$help} {
	  set filtered_ref_inf_tiles_clb [linsert $filtered_ref_inf_tiles_clb [llength $filtered_ref_inf_tiles_clb] [lindex $filtered_ref_inf_tiles $y]]
	 # puts $filtered_ref_inf_tiles_clb
	}
  }
  set filtered_ref_inf_tiles $filtered_ref_inf_tiles_clb  
  } 		
		
  ##find exact same footprints
  for {set x 0} {$x<[llength $all_clock_regions]} {incr x} {
	set clk_reg_coor [ join [get_clk_region_coordinates -clk_regions [lindex $all_clock_regions $x]]]
	set clk_reg_coor [lremove_element $clk_reg_coor 0]
	set filter_expr "ROW==[expr {[lindex $clk_reg_coor 1] - 5}] && COLUMN>=[lindex $clk_reg_coor 0] && COLUMN<=[lindex $clk_reg_coor 2]"
	set clk_reg_tiles [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
	set end 0
	set block_start 0
	set block_end   [expr {$block_start + $pblock_width}]
 	
	while {$end==0} {

		set compare_tiles [lrange $clk_reg_tiles $block_start $block_end]		
		if {[llength $compare_tiles]!=[llength $ref_pblock_tiles]} {
			set end 1
		}
		
		set equal_tiles 0
		
		for {set y 0} {$y<[llength $compare_tiles]} {incr y} {
			if {[lindex $ref_pblock_tiles $y]==[lindex $compare_tiles $y]} {
				incr equal_tiles
			}
		}
		
		if {$equal_tiles==[llength $compare_tiles]} {
			incr equal_pattern_nr		
			set insert_pattern "[expr {$block_start + [lindex $clk_reg_coor 0]}] [expr {[lindex $clk_reg_coor 1]}] [expr {$block_end + [lindex $clk_reg_coor 0]}] [lindex $clk_reg_coor 3]"
			set equal_pattern [linsert $equal_pattern [llength $equal_pattern] $insert_pattern]
		}
		incr block_start
		set block_end [expr {$block_start + $pblock_width}]
		if {$block_end>[lindex $clk_reg_coor 2]} {
			set end 1
		}
	}
	
  }
  
  ###find exact footprints with suitable interfaces
  
  set compatibel_pattern {}
  #puts "NUMBER equal_patterns: [llength $equal_pattern]"
  
  for {set x 0} {$x<[llength $equal_pattern]} {incr x} {
	##emulate interface side of found pattern
	set found_pattern [join [lindex $equal_pattern $x]]
	#puts "PATTERN: $found_pattern"
	set pattern_name "pblock_dummy"
	set pattern_whole [list [linsert $found_pattern 0 $pattern_name]]
	
	##find compare fence of found_pattern
	set comp_fence_column [search_fence -pblock $pattern_whole -side $interface_side -return_fence_column]
    set comp_2nd_clb_column [search_second_clb_column -pblock $pattern_whole -interface_side $interface_side -start_search $comp_fence_column]	
    set start_search 0
    set incr_clb_search 0
	  ##search for next clb when more interfaces needed
	  while {$start_search==0} {
		if {$multiple_clbs!=0 && $incr_clb_search<=$multiple_clbs} {
			set comp_2nd_clb_column [get_slices -side $interface_side -start [expr {$comp_2nd_clb_column + $arith}] -search_in_row [lindex [lindex $pblock_whole 0] 2] -slice_column]
		} else {
			set start_search 1
		}
		 incr incr_clb_search	
	  }
if {$comp_2nd_clb_column!=-1} {	
		
  if {$interface_side=="LEFT"} {
	set filter_expr "ROW==[lindex $found_pattern 1] && COLUMN>=$comp_2nd_clb_column && COLUMN<=$comp_fence_column"
  } else {
	set filter_expr "ROW==[lindex $found_pattern 1] && COLUMN>=$comp_fence_column && COLUMN<=$comp_2nd_clb_column"  
  }

  ##emulated interface side for compare pattern
  set comp_interface_tiles [get_property TILE_TYPE [get_tiles -filter $filter_expr]]
  
  set filtered_comp_inf_tiles {}
  for {set y 0} {$y<[llength $comp_interface_tiles]} {incr y} {
	if {[lsearch -exact $GLOBAL_PBLOCK::iso_fence_types [lindex $comp_interface_tiles $y]]!=-1} {
	  set filtered_comp_inf_tiles [linsert $filtered_comp_inf_tiles [llength $filtered_comp_inf_tiles] [lindex $comp_interface_tiles $y]]
	}
  }  
  #puts "RFERENCE_SIDE_REF  : $filtered_ref_inf_tiles"
  #puts "REFERENCE_SIDE_COMP: $filtered_comp_inf_tiles"
   if {$interface_side=="LEFT"} {
    set help [expr {[llength $filtered_comp_inf_tiles]-1}] 
  } else {
    set help 1
  } 
   set filtered_comp_inf_tiles_clb {}  
  if {[llength $filtered_comp_inf_tiles]>3} {
   for {set y 0} {$y<[llength $filtered_comp_inf_tiles]} {incr y} {
	if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] [lindex $filtered_comp_inf_tiles $y]]!=-1 || [lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] [lindex $filtered_comp_inf_tiles $y]]!=-1 || $y==$help} {
	  set filtered_comp_inf_tiles_clb [linsert $filtered_comp_inf_tiles_clb [llength $filtered_comp_inf_tiles_clb] [lindex $filtered_comp_inf_tiles $y]]
	  #puts $filtered_comp_inf_tiles_clb
	}
  }
  set filtered_comp_inf_tiles $filtered_comp_inf_tiles_clb  
  }  

  
  ##compare emulated interface_sides

  set compatibel_tiles 0
  
  for {set z 0} {$z<[llength $filtered_comp_inf_tiles]} {incr z} {
	  set comp_clb_1 0 
	  set comp_clb_2 0 
	  set comp_bram_dsp_1 0
	  set comp_bram_dsp_2 0 
	  
	  if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] [lindex $filtered_comp_inf_tiles $z]]!=-1} {
		if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 0] [lindex $filtered_ref_inf_tiles $z]]!=-1} {
				incr comp_clb_1
		}
	  }

	  if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] [lindex $filtered_comp_inf_tiles $z]]!=-1} {
		if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs 1] [lindex $filtered_ref_inf_tiles $z]]!=-1} {
				incr comp_clb_2
		}
	  }  

	  if {[lsearch -exact [lindex $compatibel_bram_dsp 0] [lindex $filtered_comp_inf_tiles $z]]!=-1} {
		if {[lsearch -exact [lindex $compatibel_bram_dsp 0] [lindex $filtered_ref_inf_tiles $z]]!=-1} {
				incr comp_bram_dsp_1
		}
	  }   

	  if {[lsearch -exact [lindex $compatibel_bram_dsp 1] [lindex $filtered_comp_inf_tiles $z]]!=-1} {
		if {[lsearch -exact [lindex $compatibel_bram_dsp 1] [lindex $filtered_ref_inf_tiles $z]]!=-1} {
				incr comp_bram_dsp_2
		}
	  }  
	  
	  if {$comp_clb_1==1 || $comp_clb_2==1 || $comp_bram_dsp_1==1 || $comp_bram_dsp_2==1} {
		incr compatibel_tiles 
	  } 
  }
  
  if {$compatibel_tiles==[llength $filtered_comp_inf_tiles] && $compatibel_tiles==[llength $filtered_ref_inf_tiles]} {
	#puts "MATCHED: [lindex $equal_pattern $x]"
	set compatibel_pattern [linsert $compatibel_pattern [llength $compatibel_pattern] [lindex $equal_pattern $x]]
  } 
  }
}
  
  return $compatibel_pattern
}

proc search_second_clb_column {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
 set pblock {}
 set side {}
 set start {}
 set error 0
 set help 0

	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblock { 
				set pblock [lshift args]
			  }	
			  -interface_side { 
				set side [lshift args]
			  }	
			  -start_search { 
				set start [lshift args]
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
						[-pblock <Pblock_1>]

						
			Description: Finds identical Pblock pattern with identical interface sides
			 
			Example:    search_second_clb_column -pblock Pblock_1 -interface_side LEFT -start_search 10
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	  
 #----------------------------------------------------------------------------------------------------------------------
 # EXECUTION CODE
 #----------------------------------------------------------------------------------------------------------------------
	if {$GLOBAL_PBLOCK::init_done==0} {
		set device_part [get_property DEVICE [get_parts -of_objects [get_projects]]]
		init_plattform -part $device_part
		#return -code error {Run init_platform procedure before you configure your relocation design}
	}

    set pblock [join $pblock]
	if {[llength $pblock]==1} {
		set rect_pblock [join [get_rect -pblocks $pblock -exact]]
	} else {
		set rect_pblock $pblock
	}
	set clb_cnt 0
	set i 1 
	set tile_type {}
	set tiles_order_from_pb_border {}
	
	if {$side=="LEFT"} {
		set left_fence_tiles $start
	} else {
		set right_fence_tiles $start
	}
	
	while {$clb_cnt!=2} {
		if {$side=="LEFT"} {
			set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {$left_fence_tiles - $i}] && TILE_TYPE!=NULL"	
			if {[expr {$left_fence_tiles - $i}]<[lindex $GLOBAL_PBLOCK::x_range 0]} {
				set clb_cnt 2
				set fence_column -1					
				break
			}
		} else {
			set filter_expr "ROW>=[lindex $rect_pblock 4] && ROW<=[lindex $rect_pblock 2] && COLUMN==[expr {$right_fence_tiles + $i}] && TILE_TYPE!=NULL"				
			if {[expr {$right_fence_tiles + $i}]>[lindex $GLOBAL_PBLOCK::x_range 1]} {
				set clb_cnt 2 
				set fence_column -1
				break
			}					
		}
		
		if {$clb_cnt!=2} {
			set tile_type [lindex [get_property TILE_TYPE [get_tiles -filter $filter_expr]] 0]
			#puts "tile_type: $tile_type"
			set tiles_order_from_pb_border [linsert $tiles_order_from_pb_border [llength $tiles_order_from_pb_border] $tile_type] 
		}
		for {set comp 0} {$comp<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr comp} {
			set clb_comp_list [lindex $GLOBAL_PBLOCK::compatibel_clbs $comp]
			if {[search_String $clb_comp_list [lindex $tile_type 0] 1]!=-1 && $clb_cnt!=2} {
				#puts "TILE_TYPE: [get_property TILE_TYPE [get_tiles -filter $filter_expr]]"
				if {$side=="LEFT"} {
					set fence_column [expr {$left_fence_tiles - $i}]			
				} else {
					set fence_column [expr {$right_fence_tiles + $i}]				
				}
				incr clb_cnt			
			}	
		}
		incr i
	}	
	return $fence_column
}