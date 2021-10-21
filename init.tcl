 source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/Reloc_Main.tcl
 source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/Drc_Reloc.tcl
 
 set_param tcl.collectionResultDisplayLimit 0
 
 create_property -type bool RELOC cell
 create_property -type bool RELOC_STATIC_PART cell
 ##drc_init kann nicht bei start des Tools geladen werden
 drc_init

 namespace eval GLOBAL_RELOC_STATE {
	variable sourced_RelocSetup 0
}


 proc init_plattform {args} {
  #-----------------------------------------------------------------------------------------------------------------
  #Process command line arguments
  #-----------------------------------------------------------------------------------------------------------------
  set board_part {}
  set error 0
  set help 0
  
	  while {[llength $args]} {
	  set flag [lshift args]
		  switch -exact -- $flag {
			  -part { 
				set board_part [lshift args]
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
						[-part <FPGA Architecture>]

						
			Description: Initilizes Plattform. Determines used Parameter. In the moment only xc7z020 is supported.
						 
			Example:    init_plattform -part xc7z020
		  
		  } $callerflag $callerflag ]
		   # HELP -->
		    return -code ok {}
	  }	
	
	 #----------------------------------------------------------------------------------------------------------------------
	 # EXECUTION CODE
	 #----------------------------------------------------------------------------------------------------------------------	
	
	### einbinden der verschiedenen Plattformen
	  global env
	  source $env(APPDATA)/Xilinx/Vivado/RELOC_TCL/RelocSetup.tcl
	  set GLOBAL_RELOC_STATE::sourced_RelocSetup 1
	  
	  set GLOBAL_PBLOCK::init_done 1
	  
	  if {$board_part=="xc7z020"} {
		set GLOBAL_PBLOCK::tile_length_list $FPGA_PALTFORM::tile_length_list_xc7z020
		set GLOBAL_PBLOCK::ps_clk_region $FPGA_PALTFORM::ps_clk_region_xc7z020
		set GLOBAL_PBLOCK::bitstream_mid_point $FPGA_PALTFORM::bitstream_mid_point_xc7z020
	  } elseif {$board_part=="xc7z045"} {
		set GLOBAL_PBLOCK::tile_length_list $FPGA_PALTFORM::tile_length_list_xc7z045
		set GLOBAL_PBLOCK::ps_clk_region $FPGA_PALTFORM::ps_clk_region_xc7z045	  
	  } else {
		return -code error (No valid part for board_part is choosen)
	  }
 }
 



