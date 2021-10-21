# RePaBit

Partial reconfiguration in FPGAs increases the flexibility of a system due to dynamic replacement of hardware modules. However, more memory is needed to store all partial bitstreams and the generation of all partial bitstreams for all possible regions on the FPGA is very time-consuming. In order to overcome these issues, bitstream relocation can be used. In this paper, a novel approach that facilitates bitstream relocation with the Xilinx Vivado tool flow is presented. In addition, the approach is automated by TCL scripts that extend Vivado to RePaBit. RePaBit is successfully evaluated on the Xilinx Zynq FPGA using 1D and 2D relocation of complex modules such as MicroBlaze processors. The results show a negligible overhead in terms of area and frequency while enabling more flexibility by partial bitstream relocation as well as a faster design time.

# Citations
If you use this work in your research, please cite the following paper:

J. Rettkowski, K. Friesen and D. Göhringer, "RePaBit: Automated generation of relocatable partial bitstreams for Xilinx Zynq FPGAs", 2016 International Conference on ReConFigurable Computing and FPGAs (ReConFig), 2016, pp. 1-8, doi: 10.1109/ReConFig.2016.7857186.

# Contact Info
M.Sc. Jens Rettkowski, Technische Universität Dresden, jens.rettkowski@mailbox.tu-dresden.de,

Google Scholar: https://scholar.google.de/citations?user=3LzRFWcAAAAJ&hl=de