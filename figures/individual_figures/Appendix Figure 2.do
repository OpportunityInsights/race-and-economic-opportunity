/*

This .do file creates Appendix Figure 2. 

*/


* load data
use "${final}/density_byrace.dta", clear

* all races
twoway ///
	(scatter density_white par_pctile , msize(0.75) mcolor(navy) msymbol($sym_white)) ///
	(scatter density_black par_pctile , msize(0.75) mcolor(maroon) msymbol($sym_black)) ///
	(scatter density_asian par_pctile , msize(`psize_asian') msymbol($sym_asian)) ///
	(scatter density_hispanic par_pctile , msize(0.75) mcolor(orange) msymbol($sym_hisp)) ///
	(scatter density_natam par_pctile , msize(0.75) mcolor(lavender)  msymbol($sym_natam)) ///
	,ytitle("Share of Parents at Given Household Income Percentile", axis(1) margin(t=3)) ///
	xtitle("Parent Household Income Rank") title(${title_size}) ///
	legend(order(1 "White" 2 "Black" 3 "Asian" 4 "Hispanic" 5 "American Indian") ///
	ring(0) pos(1) col(2)) 
graph export "${figures}/bin_density_kfr_par_rank_all_race.${img}", replace