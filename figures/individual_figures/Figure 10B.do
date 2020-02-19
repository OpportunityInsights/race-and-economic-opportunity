/*

This .do file creates Figure 10B. 

*/

* Load data
use "${final}/bin_kir_gap_notpoor_20bin", clear

* Save intercept, slope and SEs
reg kir_gap_male_p25 nonpoor_share2000 
local icpt: di %3.2f _b[_cons]
local slope: di %3.2f _b[nonpoor_share2000]
local slope_se: di %3.2f _se[nonpoor_share2000]

* Plot
twoway scatter kir_gap_male_p25 nonpoor_share2000  || ///
	line kir_gap_male_p25_pred nonpoor_share2000, ///
		legend(off) title(${title_size}) ///
		ytitle("White Minus Black Indiv. Income Rank" "Given Parents at p = 25", bm(t=3)) ///
		xtitle("Share Above Poverty Line in Tract in 2000 (%)") ///
		text(6.15 90 "Slope = `slope' (`slope_se')")
graph export "${figures}/bin_kir_bw_gap_nonpoor.${img}", replace