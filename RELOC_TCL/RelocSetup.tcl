##########WIE PROJECT SETUP
 namespace eval GLOBAL_PBLOCK {
variable init_done 0
variable fpga_size_coordinates [get_fpga_size]
variable ps_clk_region {}
variable x_range "[lindex $fpga_size_coordinates 1] [lindex $fpga_size_coordinates 3]"
variable y_range "[lindex $fpga_size_coordinates 4] [lindex $fpga_size_coordinates 2]"
variable iso_fence_types {CLBLL_R CLBLM_L CLBLM_R CLBLL_L BRAM_L BRAM_R DSP_R DSP_L}
variable compatibel_clbs {{CLBLL_L CLBLM_L}  {CLBLL_R CLBLM_R}}
variable partly_compatibel {{BRAM_R DSP_R} {BRMA_L DSP_L}}
variable bitstream_mid_point 52
 ##clb_site_types list format ----------> 
variable clb_site_types {{CLBLM M L} {CLBLL LL L}}
variable slice_lut  {A6LUT B6LUT C6LUT D6LUT}

 ######Structure of list {TILE_TYPE | UPPER_DISTANCE FROM CENTER TO UPPER_END | LOWER_DISTANCE FROM CENTER TO LOWER END| TILE_TYPE | ............... | LOWER_DISTANCE FROM CENTER TO LOWER END}
variable tile_length_list {}
 }
 
namespace eval RELOC_FLOW {
variable read_cp_done 0
variable placed_dummy_cells 0
}  
 
namespace eval FPGA_PALTFORM {
 ######Structure of list {TILE_TYPE | UPPER_DISTANCE FROM CENTER TO UPPER_END | LOWER_DISTANCE FROM CENTER TO LOWER END| TILE_TYPE | ............... | LOWER_DISTANCE FROM CENTER TO LOWER END}
variable bitstream_mid_point_xc7z020 52
variable tile_length_list_xc7z020 {
NULL 0 0
T_TERM_INT 0 0 
TERM_CMT 0 0
BRKH_CLB 0 0 
BRKH_TERM_INT 0 0 
CLK_TERM 0 0 
PCIE_NULL 0 0 
INT_INTERFACE_PSS_L 0 0 
INT_L 0 0 
INT_R 0 0 
CLBLM_R 0 0 
CLBLL_L 0 0 
VBRK 0 0 
BRAM_INT_INTERFACE_L 0 0 
CLBLM_L 0 0 
INT_INTERFACE_R 0 0 
CLK_FEED 0 0 
CLBLL_R 0 0 
INT_FEEDTHRU_1 0 0 
INT_FEEDTHRU_2 0 0 
VFRAME 0 0 
INT_INTERFACE_L 0 0 
BRAM_INT_INTERFACE_R 0 0 
CMT_PMV_L 0 0 
IO_INT_INTERFACE_R 0 0 
R_TERM_INT 0 0 
RIOI3_SING 0 0 
RIOB33_SING 0 0 
RIOI3 1 0 
RIOB33 1 0 
BRAM_L 4 0 
DSP_R 4 0 
MONITOR_TOP_PELE1 4 0 
DSP_L 4 0 
BRAM_R 4 0 
CMT_FIFO_L 5 6 
RIOI3_TBYTESRC 1 0 
CMT_TOP_L_UPPER_T 7 5 
PSS4 9 10 
RIOI3_TBYTETERM 1 0 
CLK_BUFG_REBUF 1 0 
MONITOR_MID_PELE1 9 0 
CMT_TOP_L_UPPER_B 7 4 
MONITOR_BOT_PELE1 9 0 
HCLK_CLB 0 0 
HCLK_L 0 0 
HCLK_R 0 0 
HCLK_VBRK 0 0 
HCLK_BRAM 0 0 
HCLK_INT_INTERFACE 0 0 
HCLK_DSP_R 0 0 
CLK_HROW_TOP_R 4 4 
HCLK_FEEDTHRU_1 0 0 
HCLK_FEEDTHRU_2 0 0 
HCLK_FEEDTHRU_1_PELE 0 0 
HCLK_VFRAME 0 0 
HCLK_DSP_L 0 0 
HCLK_CMT_L 0 0 
HCLK_FIFO_L 0 0 
HCLK_TERM 0 0 
HCLK_IOI3 0 0 
HCLK_IOB 0 0 
PSS3 10 10 
CFG_SECURITY_TOP_PELE1 4 0 
CMT_TOP_L_LOWER_T 7 1 
CFG_SECURITY_MID_PELE1 9 0 
CMT_TOP_L_LOWER_B 7 8 
PSS2 9 11 
CFG_SECURITY_BOT_PELE1 9 0 
BRKH_INT 0 0 
BRKH_BRAM 0 0 
BRKH_DSP_R 0 0 
BRKH_CLK 0 0 
BRKH_DSP_L 0 0 
BRKH_CMT 0 0 
CFG_CENTER_TOP 9 0 
PSS1 9 11 
CFG_CENTER_MID 9 11 
PSS0 9 10 
CFG_CENTER_BOT 9 10 
CLK_BUFG_TOP_R 3 0 
BRKH_INT_PSS 0 0 
LIOB33_SING 0 0 
LIOI3_SING 0 0 
L_TERM_INT 0 0 
IO_INT_INTERFACE_L 0 0 
CMT_PMV 0 0 
LIOB33 1 0
LIOI3 1 0
CLK_BUFG_BOT_R 3 0 
CLK_MTBF2 0 0 
LIOI3_TBYTESRC 1 0 
CMT_FIFO_R 5 6 
CMT_TOP_R_UPPER_T 7 5 
CLK_PMV2 0 0 
LIOI3_TBYTETERM 1 0 
CLK_PMV2_SVT 0 0 
CMT_TOP_R_UPPER_B 7 4 
HCLK_CMT 0 0 
CLK_HROW_BOT_R 4 4 
CMT_TOP_R_LOWER_T 7 1 
CLK_PMVIOB 0 0 
CMT_TOP_R_LOWER_B 7 8 
CLK_PMV 0 0 
B_TERM_INT 0 0 }

variable tile_length_list_xc7z045 {
NULL 0 0
T_TERM_INT 0 0 
TERM_CMT 0 0
BRKH_CLB 0 0 
BRKH_TERM_INT 0 0 
CLK_TERM 0 0 
PCIE_NULL 0 0 
INT_INTERFACE_PSS_L 0 0 
INT_L 0 0 
INT_R 0 0 
CLBLM_R 0 0 
CLBLL_L 0 0 
VBRK 0 0 
BRAM_INT_INTERFACE_L 0 0 
CLBLM_L 0 0 
INT_INTERFACE_R 0 0 
CLK_FEED 0 0 
CLBLL_R 0 0 
INT_FEEDTHRU_1 0 0 
INT_FEEDTHRU_2 0 0 
VFRAME 0 0 
INT_INTERFACE_L 0 0 
BRAM_INT_INTERFACE_R 0 0 
CMT_PMV_L 0 0 
IO_INT_INTERFACE_R 0 0 
R_TERM_INT 0 0 
RIOI3_SING 0 0 
RIOB33_SING 0 0 
RIOI3 1 0 
RIOB33 1 0 
BRAM_L 4 0 
DSP_R 4 0 
MONITOR_TOP_PELE1 4 0 
DSP_L 4 0 
BRAM_R 4 0 
CMT_FIFO_L 5 6 
RIOI3_TBYTESRC 1 0 
CMT_TOP_L_UPPER_T 7 5 
PSS4 9 10 
RIOI3_TBYTETERM 1 0 
CLK_BUFG_REBUF 1 0 
MONITOR_MID_PELE1 9 0 
CMT_TOP_L_UPPER_B 7 4 
MONITOR_BOT_PELE1 9 0 
HCLK_CLB 0 0 
HCLK_L 0 0 
HCLK_R 0 0 
HCLK_VBRK 0 0 
HCLK_BRAM 0 0 
HCLK_INT_INTERFACE 0 0 
HCLK_DSP_R 0 0 
CLK_HROW_TOP_R 4 4 
HCLK_FEEDTHRU_1 0 0 
HCLK_FEEDTHRU_2 0 0 
HCLK_FEEDTHRU_1_PELE 0 0 
HCLK_VFRAME 0 0 
HCLK_DSP_L 0 0 
HCLK_CMT_L 0 0 
HCLK_FIFO_L 0 0 
HCLK_TERM 0 0 
HCLK_IOI3 0 0 
HCLK_IOB 0 0 
PSS3 10 10 
CFG_SECURITY_TOP_PELE1 4 0 
CMT_TOP_L_LOWER_T 7 1 
CFG_SECURITY_MID_PELE1 9 0 
CMT_TOP_L_LOWER_B 7 8 
PSS2 9 11 
CFG_SECURITY_BOT_PELE1 9 0 
BRKH_INT 0 0 
BRKH_BRAM 0 0 
BRKH_DSP_R 0 0 
BRKH_CLK 0 0 
BRKH_DSP_L 0 0 
BRKH_CMT 0 0 
CFG_CENTER_TOP 9 0 
PSS1 9 11 
CFG_CENTER_MID 9 11 
PSS0 9 10 
CFG_CENTER_BOT 9 10 
CLK_BUFG_TOP_R 3 0 
BRKH_INT_PSS 0 0 
LIOB33_SING 0 0 
LIOI3_SING 0 0 
L_TERM_INT 0 0 
IO_INT_INTERFACE_L 0 0 
CMT_PMV 0 0 
LIOB33 1 0
LIOI3 1 0
CLK_BUFG_BOT_R 3 0 
CLK_MTBF2 0 0 
LIOI3_TBYTESRC 1 0 
CMT_FIFO_R 5 6 
CMT_TOP_R_UPPER_T 7 5 
CLK_PMV2 0 0 
LIOI3_TBYTETERM 1 0 
CLK_PMV2_SVT 0 0 
CMT_TOP_R_UPPER_B 7 4 
HCLK_CMT 0 0 
CLK_HROW_BOT_R 4 4 
CMT_TOP_R_LOWER_T 7 1 
CLK_PMVIOB 0 0 
CMT_TOP_R_LOWER_B 7 8 
CLK_PMV 0 0 
B_TERM_INT 0 0 
RIOI_SING 0 0
RIOB18_SING 0 0 
RIOI 1 0
RIOB18 1 0
RIOI_TBYTESRC 1 0
RIOI_TBYTETERM 1 0
HCLK_IOI 0 0
BRKH_GTX 0 0 
BRKH_B_TERM_INT 0 0
GTX_INT_INTERFACE 0 0
R_TERM_INT_GTX 0 0
VBRK_EXT 0 0 
GTX_CHANNEL_3 5 5
GTX_CHANNEL_2 5 5
HCLK_L_BOT_UTURN 0 0
HCLK_R_BOT_UTURN 0 0
HCLK_GTX 0 0 
HCLK_TERM_GTX 0 0
PCIE_INT_INTERFACE_R 0 0 
PCIE_INT_INTERFACE_L 0 0 
GTX_COMMON 6 0
PCIE_TOP 4 1
GTX_CHANNEL_1 5 5
PCIE_BOT 9 10
GTX_CHANNEL_0 5 5
}

variable ps_clk_region_xc7z045 {X0Y5 X0Y6}
variable ps_clk_region_xc7z020 {X0Y1 X0Y2}

}