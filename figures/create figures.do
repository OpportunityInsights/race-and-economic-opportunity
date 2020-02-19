/*

This .do file runs over all figures presented in the paper. 

*/

* ---------------------------------------
* Setting up
* ---------------------------------------

* housekeeping
clear all 
set maxvar 15000
set more off
graph set window fontface default

* set the file type (png, wmf, or pdf)
global img 

* set the version of the figures (paper or slides)
global version 

* set race symbols 
global sym_white "circle"
global sym_black "triangle"
global sym_hisp "diamond"
global sym_asian "plus"

* set the title size
if "${version}"=="slides" {
    global title_size `"" ", size(vlarge)"'
}
else if "${version}"=="paper" {
    global title_size ""
}

* ---------------------------------------
* Main Figures
* ---------------------------------------
do "${code}/figures/individual_figures/Figure 1A.do"
do "${code}/figures/individual_figures/Figure 1B.do"
do "${code}/figures/individual_figures/Figure 2A data.do"
do "${code}/figures/individual_figures/Figure 2A.do"
do "${code}/figures/individual_figures/Figure 2B.do"
do "${code}/figures/individual_figures/Figure 3.do"
do "${code}/figures/individual_figures/Figure 4A data.do"
do "${code}/figures/individual_figures/Figure 4A.do"
do "${code}/figures/individual_figures/Figure 4B data.do"
do "${code}/figures/individual_figures/Figure 4B.do"
do "${code}/figures/individual_figures/Figure 5 data.do"
do "${code}/figures/individual_figures/Figure 5.do"
do "${code}/figures/individual_figures/Figure 6-7 wage work college data.do"
do "${code}/figures/individual_figures/Figure 6-7 wage work college.do"
do "${code}/figures/individual_figures/Figure 6-7, Appendix Figure 5 hours high school spouse rank kfr data.do"
do "${code}/figures/individual_figures/Figure 6-7, Appendix Figure 5 hours high school spouse rank kfr.do"
do "${code}/figures/individual_figures/Figure 7 incarceration data.do"
do "${code}/figures/individual_figures/Figure 7 incarceration.do"
do "${code}/figures/individual_figures/Figure 8 geographic data.do"
do "${code}/figures/individual_figures/Figure 8, Appendix Figure 9 individual data.do"
do "${code}/figures/individual_figures/Figure 8.do"
do "${code}/figures/individual_figures/Figure 9, Appendix Figure 11.do"
do "${code}/figures/individual_figures/Figure 10A.do"
do "${code}/figures/individual_figures/Figure 10B data.do"
do "${code}/figures/individual_figures/Figure 10B.do"
do "${code}/figures/individual_figures/Figure 11.do"
do "${code}/figures/individual_figures/Figure 12A-C data.do"
do "${code}/figures/individual_figures/Figure 12A-C.do"
do "${code}/figures/individual_figures/Figure 12D data.do"
do "${code}/figures/individual_figures/Figure 12D.do"
do "${code}/figures/individual_figures/Figure 13.do"
do "${code}/figures/individual_figures/Figure 14 data.do"
do "${code}/figures/individual_figures/Figure 14.do"

* ---------------------------------------
* Appendix Figures
* ---------------------------------------
do "${code}/figures/individual_figures/Appendix Figure 1 data.do"
do "${code}/figures/individual_figures/Appendix Figure 1.do"
do "${code}/figures/individual_figures/Appendix Figure 2 data.do"
do "${code}/figures/individual_figures/Appendix Figure 2.do"
do "${code}/figures/individual_figures/Appendix Figure 3.do"
do "${code}/figures/individual_figures/Appendix Figure 4 data.do"
do "${code}/figures/individual_figures/Appendix Figure 4.do"
do "${code}/figures/individual_figures/Appendix Figure 6 data.do"
do "${code}/figures/individual_figures/Appendix Figure 6.do"
do "${code}/figures/individual_figures/Appendix Figure 7 data.do"
do "${code}/figures/individual_figures/Appendix Figure 7.do"
do "${code}/figures/individual_figures/Appendix Figure 8.do"
do "${code}/figures/individual_figures/Appendix Figure 9.do"
do "${code}/figures/individual_figures/Appendix Figure 10.do"
do "${code}/figures/individual_figures/Appendix Figure 12, 13 data.do"
do "${code}/figures/individual_figures/Appendix Figure 12, 13.do"
do "${code}/figures/individual_figures/Appendix Figure 14, 15 data.do"
do "${code}/figures/individual_figures/Appendix Figure 14, 15.do"
do "${code}/figures/individual_figures/Appendix Figure 16 data.do"
do "${code}/figures/individual_figures/Appendix Figure 16.do"