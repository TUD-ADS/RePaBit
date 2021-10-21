# proc lindex {idxList idx} {
	# set old_start_element 0
	# set idxList [join $idxList]
	# #puts "idxList: $idxList, index: $idx"
	# set return_element {}
	
	# for {set x 0} {$x<=$idx} {incr x} {
		# set new_start_element $old_start_element
		# set end_element [string first " " $idxList $new_start_element]
		
		# if {$idx==$x} {
			# if {$end_element==-1} {
				# set end_element [string length $idxList]
			# }
			# set element_string [cutString $idxList $new_start_element $end_element]
			# set return_element [linsert $return_element 0 $element_string]
			# return $return_element
			# break;
		# } elseif {$end_element==-1} {
			# return -code error {"No String on this Element"}
			# break;
		# } else {
			# set old_start_element [expr {$end_element + 1}]
		# }
	# }	
# }


proc total_number {number} {
	set point_index [string first . $number 0]
	set string_length [string length $number]		
	if {[expr {$string_length - $point_index}]==2} {
		if {[string index $number [expr {$string_length - 1}]]==0} {
			return 1
		} else {
			return 0
		}
	} else {
		return 0
	}
}	

 ##Function for Cutting string between Indexes
proc cutString {string index_start index_end} {
set var {}
for {set x $index_start} {$x<$index_end} {incr x} {
	set iteration_char [string index $string $x]
	append var $iteration_char 
}
return $var
}

 ####Search in a list for the first Element which is determined by string
proc search_part_list {InputList string} {
 set matched_index_list {}
 for {set x 0} {$x<[llength $InputList]} {incr x} {
	if {[lindex [lindex $InputList $x] 0]==$string} {
		set matched_index_list [linsert $matched_index_list [llength $matched_index_list] $x]
	}
 }
 if {[llength $matched_index_list]!=0} {
	return $matched_index_list 
 } else {
	return -1
 }

}
 #############################search for string in list---from beginning of character to the last character in each element
proc search_String {liste string exact} {
	set matched_index_list {}
	set index 0
	
	for {set x 0} {$x<[llength $liste]} {incr x} {   
	set ok 1
	   for {set y 0} {$y<[string length $string]} {incr y} {
			if {[string index [lindex $liste $x] $y]!=[string index $string $y]} {
				set ok 0
				set y [string length $string]
			}
	   }
	   if {$exact==1} {
		if {$ok==1 && [string length [lindex $liste $x]]==[string length $string]} {
			incr index
			set matched_index_list [linsert $matched_index_list $index $x]
		}	   
	   } else {
		if {$ok==1} {
			incr index
			set matched_index_list [linsert $matched_index_list $index $x]
		}		   
	   }

	}
	if {[llength $matched_index_list]==0} {
		return -1
	} else {
		return  $matched_index_list 
	}	
	
} 
 ##getLast Cell out of hierarchical structure like: list = {x/y/z r/b/g}, returned list {z g}
proc getLastCellName {lists} {
	set length_cell_list [llength $lists]
	set derived_cellNames " "
	for {set x 0} {$x<$length_cell_list} {incr x} {
		set derived_help      [lindex $lists $x]
		set str_start [string last / $derived_help]
		set str_end [string length $derived_help]
		set derived_cell_name [cutString $derived_help [expr {$str_start + 1}] $str_end]
		set derived_cellNames [linsert $derived_cellNames 1 $derived_cell_name] 
	}
return $derived_cellNames
}



 ##########################Define how much instances in an data path of an instance name
 ##########################Falls nicht gefunden, dann 0 zurück geben
proc InstanceDepth {InstancePath} {
	set lengthPath [string length [expr {$InstancePath}]]
	##puts "LengthPath: $lengthPath"
	set inst_cnt 1
	set stringindex 0
	set break_while 1
	
	while {$break_while==1} {
		set stringindex [string first / $InstancePath [expr {$stringindex +1}]]	
		if {$stringindex==-1 && $inst_cnt==1} {
			return 1
		} elseif {$stringindex==-1 && $inst_cnt!=1} {
		    set break_while 0	
	
		} else {
		  set inst_cnt [expr {$inst_cnt + 1}]
		}
	}
	return $inst_cnt
}

	#################Example: cl_i/stat_0/U0/ledcl/LED2_out[2]_INST_0/O, path cut on second Element..input lastInstance_index=2 ---> $partPath==cl_i/stat_0
	#################Return the instance path till element "lastInstance_index" of an instance path
proc InstancePath {fullPath lastInstance_index} {	

	set lengthList [string length [expr {$fullPath}]]
	set count 0
	set stringindex 0
	for {set x 0} {$x<$lastInstance_index} {incr x} {
		set stringindex [string first / $fullPath [expr {$stringindex +1}]]			
	}
	set partPath [cutString $fullPath 0 $stringindex]
	return $partPath	
}

	################Search for a part string in a bigger string
proc StringPart_Compare {main_string search_string} {
	set search_string "$search_string 1"
	set new_string [string map $search_string $main_string]
	set result [string compare $new_string $main_string]
	if {$result!=0} {
		return 1
	} else {
		return 0
	}
}

	##shifts string elements of an list
  proc lshift {listVar1} {
   upvar 1 $listVar1 ko
   set r [lindex $ko 0]
   set ko [lreplace $ko [set ko 0] 0]
   return $r
 }
 
  ##removes an specified element "value" in a list "listVariable"
 proc lremove_element {listVariable value} {
    set listvar $listVariable
    set idx $value
    set listvar [lreplace $listvar $idx $idx]
	return $listvar
}

 ##removes all instances of a list "listVar" except the string "element"
proc lremove_rest {listVar element} {
	set not_erase $element
	for {set x 0} {$x<[llength $listVar]} {incr x} {
		if {[search_String $not_erase [lindex $listVar $x] 1]==-1} {
			set listVar [lremove_element $listVar $x]
		}
	}
	return $listVar
}
 proc K { x y } { set x }
 proc lremove { listvar string } {
         set listvar [expr {$listvar}]
         foreach item [K $listvar [set listvar [list]]] {
                 if {[string equal $item $string]} { continue }
                 lappend listvar $item
         }		 
		 return $listvar
 }
 
 proc list_dissolve { list_dis } {
set end 0
set x 0
set dissolved_list {}
set found 0
set worked_list {}

while {$end==0} {
 if {[llength [lindex $list_dis $x]]!=1 && $found!=1} {

	 if {$x==[llength $list_dis]} {
		set end 1
		return $list_dis	
	 }
	for {set y 0} {$y<[llength [lindex $list_dis $x]]} {incr y} {
		set dissolved_list [linsert $dissolved_list [llength $dissolved_list] [lindex [lindex $list_dis $x] $y]]
	}
	
	set worked_list [lreplace $list_dis $x $x [lindex $dissolved_list 0]]
	
	for {set y [expr {$x + 1}]} {$y<[expr {[llength $dissolved_list] + $x}]} {incr y} {
		set worked_list [linsert $worked_list $y [lindex $dissolved_list [expr {$y - $x}]]]
	}
	
	set found 1
	set end 1
 } 

 incr x
}

return $worked_list

}