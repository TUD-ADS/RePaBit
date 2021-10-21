proc bin2hex {bin} {
    set result ""
    set prepend [string repeat 0 [expr (4-[string length $bin]%4)%4]]
    foreach g [regexp -all -inline {[01]{4}} $prepend$bin] {
        foreach {b3 b2 b1 b0} [split $g ""] {
            append result [format %X [expr {$b3*8+$b2*4+$b1*2+$b0}]]
        }
    }
    return $result
}

 ##for 32 bit values 
proc bin2hexSwapped {bin} {
	set orig_bin $bin
	set new_bit_order {}
	set insert 0
	set start 0 
	set bin_length [string length $bin]
	set end_swap [expr {$bin_length/4}]
	
	for {set x 0} {$x<$end_swap} {incr x} {
		set end [expr {$start + 3}]
		set first_4_bit [string range $bin $start $end]
		set rev_first_4_bit [string reverse $first_4_bit]
		set next_4_bit  [string range $bin [expr {$end + 1}] [expr {$end + 4}]]
		set rev_next_4_bit [string reverse $next_4_bit]
		set new_bit_order [linsert $new_bit_order $insert $rev_next_4_bit]
		set new_bit_order [linsert $new_bit_order [expr {$insert + 1}] $rev_first_4_bit]
		set insert [expr {$insert + 2}]	
		set start [expr {$end + 5}]
	}
	set bitswapped_bin [join $new_bit_order ""]
	set bitswapped_hex [bin2hex $bitswapped_bin]
	
	return $bitswapped_hex
} 


proc get_pblock_bitstream_location {args} {
 #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set pblock {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblock { 
				set pblock [lshift args]
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
						[-pblock <Pblock_1>]						
			Description: This procedure computes the FAR Address for a specific P-Block
						 
			Example:    get_pblock_bitstream_location -pblock Pblock_1
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 set bitstream_mid_point $GLOBAL_PBLOCK::bitstream_mid_point
	 set in_top_half -1
	 set clk_region_reference [lindex [get_clock_regions] 0]
	 set clk_region_reference [join [get_clk_region_coordinates -clk_regions $clk_region_reference]]
	 set clk_reg_height [expr {[lindex $clk_region_reference 2] - [lindex $clk_region_reference 4]}]
	 set row -1
	 set i 0
	 set end 0
	 ###decide wether pblock is in top or bottom half of floorplanning
	 set clk_reg_of_pblock [join [pblock_in_clk_region -pblocks $pblock]]
	 set pblock_coor [join [get_clk_region_coordinates -clk_regions [lindex $clk_reg_of_pblock 1]]]
	 ##set pblock_coor [join [get_rect -pblocks $pblock -exact]]
	 
	 if {[lindex $pblock_coor 2]<$bitstream_mid_point} {
		set in_top_half 0
	 } else {
		set in_top_half 1
	 }
	 
	 set starting_mid_point $bitstream_mid_point
	 
	 if {$in_top_half==0} {
		while {$end==0} { 
			if {$i==0} {
				set space 1
			} else {
				set space 2
			}
			set next_clock_region_border [expr {$starting_mid_point - $space - $clk_reg_height }]
			if {[lindex $pblock_coor 4]<=$next_clock_region_border} {
				set end 1
				set row $i
			} else {
				set starting_mid_point $next_clock_region_border
			}
			incr i
		}	 
	 } else {
		set next_clock_region_border $starting_mid_point
		while {$end==0} { 		
			if {$i==0} {
				set space 1
			} else {
				set space 2
			}		
			set next_clock_region_border [expr {$starting_mid_point + $space + $clk_reg_height }]
			if {[lindex $pblock_coor 4]<=$next_clock_region_border} {
				set end 1
				set row $i
			} else {
				set starting_mid_point $next_clock_region_border
			}
			incr i
		}	  
	 }
	 
	 return "$in_top_half $row"	 
}


proc get_partial_far_address {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set pblock {}
  set bit 0
  set hex 0 
  set hex_bitswapped 0 
  set ram_far 0 
  set clb_far 0 
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -pblock { 
				set pblock [lshift args]
			  } -bit { 
				incr bit
			  } -hex { 
				incr hex
			  } -hex_bitswapped { 
				incr hex_bitswapped
			  } -ram_far { 
				incr ram_far
			  } -clb_far { 
				incr clb_far
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
	  if {$clb_far==1 && $ram_far==1} {
		return -code error {ERROR: Only one type of far register can be returned }	  
	  }
	  if {$clb_far==0 && $ram_far==0} {
		return -code error {ERROR: Determine a far address type }	  
	  }	  
	  if {$bit==0 && $hex==0 && $hex_bitswapped==0} {
		return -code error {ERROR: Determine a return value for the far address type}		  
	  }
	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-pblock <Pblock_1>]
						[-bit <optional>]
						[-hex <optional>]
						[-hex_bitswapped <optional>]
						[-ram_far <optional>]
						[-clb_far <optional>]
						
			Description: This procedure computes the FAR Address for a specific Pblock
						 
			Example:    get_partial_far_address -pblock Pblock_1 -clb_far -hex_bitswapped
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 
	 set pblock_coor [join [get_rect -pblocks $pblock -exact]] 
	 set filter_expr "COLUMN>=[lindex $pblock_coor 1] && COLUMN<=[lindex $pblock_coor 3] && ROW==[lindex $pblock_coor 2]"
	 ##all tiles in the pblock from left side to right side
	 set pblock_tiles [get_tiles -filter $filter_expr]
	 
	 set header "000000"
	 set pblock_location [get_pblock_bitstream_location -pblock $pblock]
	 set top_half_position [lindex $pblock_location 0]
	 set row [lindex $pblock_location 1]
	 binary scan [binary format I $row] B32 row_bin32; set row_bin32
	 set row_bin [string range $row_bin32 [expr {32-5}] 31]
	 	 
	 if {$clb_far==1} {
		 ####FAR Adress CLK, CLB, I/O
		 set block_type_clb 0
		 set block_type_clb_bin "000"
		 ##gets x coordinate of first TILE in lower left corner in the pblock
		 set column_address_clb [lindex [get_name_coor [lindex $pblock_tiles 0]] 0]
		 binary scan [binary format I $column_address_clb] B32 column_address_clb_bin32; set column_address_clb_bin32
		 set column_address_clb_bin [string range $column_address_clb_bin32 [expr {32-10}] 31] 
		 ##in all partial bitstreams is the minor address 0
		 set minor_address_clb  0 
		 set minor_address_clb_bin "0000000"
		 set far_clb_address [join "$header $block_type_clb_bin $top_half_position $row_bin $column_address_clb_bin $minor_address_clb_bin" ""]
		 set far_address $far_clb_address		 
	 }
	 
	if {$ram_far==1} { 
		 ##check if bram tiles are in pblock region
		 set bram_in_pblock [lsearch -all -regexp $pblock_tiles .*RAM.*]
		 
		 if {[llength $bram_in_pblock]>=1} {
			set bram_far_legal 1
		 } else {
			set bram_far_legal 0
		 }
		 
		 if {$bram_far_legal==1} { 
		 ####FAR Adress RAM Content
		 set block_type_ram 1
		 set block_type_ram_bin "001"
		 ##gets x coordinate of first ram site in the bram tile in the pblock
		 set first_bram_tile [lindex $pblock_tiles [lindex $bram_in_pblock 0]]	
		 set bram_sites [get_sites -of_objects [get_tiles $first_bram_tile]]     
		 set column_address_ram [lindex [get_name_coor [lindex $bram_sites 0]] 0]

		 binary scan [binary format I $column_address_ram] B32 column_address_ram_bin32; set column_address_ram_bin32
		 set column_address_ram_bin [string range $column_address_ram_bin32 [expr {32-10}] 31] 
		 set minor_address_ram 0
		 set minor_address_ram_bin "0000000" 
		 
		 set far_ram_address [join "$header $block_type_ram_bin $top_half_position $row_bin $column_address_ram_bin $minor_address_ram_bin" ""]
		 set far_address $far_ram_address
		 } else {
			set far_address -1
		 }
	 }
	 
	 if {$ram_far==1 && $bram_far_legal==0} {
		return -1
	 }
	 
	 if {$bit==1} {
		return $far_address
	 } elseif {$hex==1} {
		set far_address_hex [bin2hex $far_address]
		return $far_address_hex
	 } elseif {$hex_bitswapped==1} {
	    set far_address_bitswapped [bin2hexSwapped $far_address]
		return $far_address_bitswapped
	 }	 
}

proc get_compatibel_pblocks {args} {
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
			  } -interface_side {
			    set interface_side [lshift args]
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
	  
	  if {[llength $pblock]==0} {
		return -code error {ERROR: Specify a pblock}
	  }
	  
	  if {[llength $interface_side]==0} {
		return -code error {ERROR: Specify an interface side. Valid interface sides are LEFT and RIGHT}	  
	  }
	  
	  if {[lsearch -exact {LEFT RIGHT} $interface_side]==-1} {
		return -code error {ERROR: Specify a valid interface side. Valid interface sides are LEFT and RIGHT}
	  }

	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-pblock <Pblock_1>]
						
			Description: Returns a list of compatibel pblocks in reference to the denoted pblock
						 
			Example:    get_compatibel_pblocks -pblock Pblock_1 -interface_side LEFT
			
			Returns:    {{FULLY pblock_1 pblock_2} {LOGICAL pblock_3}}
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 set compatibility_list {}
	 set fully_compatibel {FULLY}
	 set logical_compatibel {LOGICAL}
	 set filter_expr "NAME!=$pblock"
	 set rest_rp [get_pblocks -filter $filter_expr]
	 set ref_tiles [join [get_rect -pblocks $pblock -included_tiles]]
	 set ref_tiles [lremove_element $ref_tiles 0]
	 
	 if {$interface_side=="RIGHT"} {
		set ref_tiles [lreverse $ref_tiles]
	 }
	 
	 
	 for {set x 0} {$x<[llength $rest_rp]} {incr x} {
		set other_pb_tiles [join [get_rect -pblocks [lindex $rest_rp $x] -included_tiles]]
		set other_pb_tiles [lremove_element $other_pb_tiles 0]
		if {$interface_side=="RIGHT"} {
			set other_pb_tiles [lreverse $other_pb_tiles]
		}		
		set fully_compatibel_nr 0
		set logical_compatibel_nr 0
		set partly_compatibel 0
		for {set y 0} {$y<[llength $other_pb_tiles]} {incr y} {
		 ##completely compatibel
		 if {[lindex $ref_tiles $y]==[lindex $other_pb_tiles $y]} {
			incr fully_compatibel_nr
		 } else {
			set is_same_clb_side 0 
			##check whether other_pb_tile is a clb_tile
			for {set z 0} {$z<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr z} {
				if {[lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $z] [lindex $other_pb_tiles $y]]!=-1 && [lsearch -exact [lindex $GLOBAL_PBLOCK::compatibel_clbs $z] [lindex $ref_tiles $y]]!=-1} {
					incr is_same_clb_side
					incr logical_compatibel_nr
				}
			}
			
			###other_pb_tile is not tile type clb
			###check whether is DSP or BRAM block which may be partly compatibel of the footprint of the pblocks
			if {$is_same_clb_side==0} {
				for {set z 0} {$z<[llength $GLOBAL_PBLOCK::compatibel_clbs]} {incr z} {
				if {[lsearch -exact [lindex $GLOBAL_PBLOCK::partly_compatibel $z] [lindex $other_pb_tiles $y]]!=-1 && [lsearch -exact [lindex $GLOBAL_PBLOCK::cpartly_compatibel $z] [lindex $ref_tiles $y]]!=-1} {
					incr partly_compatibel
				}					
				}
			}
			###check bram or dsp tile
		 }	
		}
		
		set logical_compatibel0 $fully_compatibel_nr
		set logical_compatibel1 [expr {$fully_compatibel_nr + $partly_compatibel}]
		set logical_compatibel2 [expr {$fully_compatibel_nr + $partly_compatibel + $logical_compatibel_nr}]
		
		if {$fully_compatibel_nr==[llength $other_pb_tiles]} {
			set fully_compatibel [linsert $fully_compatibel [llength $fully_compatibel] [lindex $rest_rp $x]]
		} 
		if {$logical_compatibel1==[llength $other_pb_tiles] || $logical_compatibel2==[llength $other_pb_tiles]} {
			set logical_compatibel [linsert $logical_compatibel [llength $logical_compatibel] [lindex $rest_rp $x]]
		} 
	 }
	 
	 set compatibility_list [linsert $compatibility_list 0 $fully_compatibel]
	 set compatibility_list [linsert $compatibility_list 1 $logical_compatibel]
	 
	 return $compatibility_list	
}

proc write_configuration_file {args} {
 #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set interface_side {}
  set error 0 
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -interface_side { 
				set interface_side [lshift args]
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

	  if {$help} {
		 set callerflag [lindex [info level [expr [info level] -1]]]
		 # <-- HELP
		  puts [format {
		   Usage: %s 
						[-file_path C:/Xilinx/..]
						
			Description: Generates a configuration .ini file in $Project_directory/"Project_name".reloc/reloc_configuration.ini
						 
			Example:    write_configuration_file -interface_side LEFT
			
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------
	 set side $interface_side
	 set pblocks [get_pblocks]
	 set brace_begin {[}
	 set brace_end {]}
	 set quote_sign {"} 
	##create new directory"
	 set project_directory [get_property XLNX_PROJ_DIR [get_designs]]
	 set project_name [lindex [split $project_directory /] end]
	 ###directory "project_name".reloc
	 set new_directory "$project_directory/$project_name.reloc"
	 file mkdir $new_directory
	 
	 ##create new ini file for configuration data
	 ##file name: reloc_configuration.ini
	 set file_name "$new_directory/reloc_configuration.ini"
	 set fileId [open $file_name "w"]
	 
	 
	 for {set x 0} {$x<[llength $pblocks]} {incr x} {
			set pblock_section [join [concat $brace_begin [lindex $pblocks $x] $brace_end] ""]
			puts $fileId $pblock_section
			set compatibel_pblocks [get_compatibel_pblocks -pblock [lindex $pblocks $x] -interface_side $side]
			set fully_comp_pblocks [lremove_element [lindex $compatibel_pblocks 0] 0]
			set logical_comp_pblocks [lremove_element [lindex $compatibel_pblocks 1] 0]
			set name_fully FULLY_COMPATIBEL=
			set name_comp LOGICAL_COMPATIBEL=
			
			if {[llength $fully_comp_pblocks]!=0} {	
				set fully_comp_expr $name_fully$quote_sign$fully_comp_pblocks$quote_sign
			} else {
				set fully_comp_pblocks NONE
				set fully_comp_expr $name_fully$quote_sign$fully_comp_pblocks$quote_sign
			}
			puts $fileId $fully_comp_expr
			
			if {[llength $logical_comp_pblocks]!=0} {
				set logical_comp_expr $name_comp$quote_sign$logical_comp_pblocks$quote_sign
			} else {
				set logical_comp_pblocks NONE
				set logical_comp_expr $name_comp$quote_sign$logical_comp_pblocks$quote_sign
			}
			puts $fileId $logical_comp_expr
			
			set pblock_far_clb_addr [get_partial_far_address -pblock [lindex $pblocks $x] -clb_far -hex_bitswapped]
			puts $fileId "FAR_CLB=$pblock_far_clb_addr"
			puts "[lindex $pblocks $x]"
			puts "FAR_CLB=[get_partial_far_address -pblock [lindex $pblocks $x] -clb_far -hex]"
			
			set pblock_far_ram_addr [get_partial_far_address -pblock [lindex $pblocks $x] -ram_far -hex_bitswapped]
			
			
			if {$pblock_far_ram_addr==-1} {
				puts $fileId "FAR_RAM= 0"
			} else {
				puts $fileId "FAR_RAM=$pblock_far_ram_addr"
			}		
				puts "FAR_RAM=[get_partial_far_address -pblock [lindex $pblocks $x] -ram_far -hex]"
	 }
	 
	 close $fileId
	 	 
}

 
