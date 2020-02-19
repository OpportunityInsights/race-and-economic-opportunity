/*

This .do file creates Appendix Figure 16. 

*/ 

*Open tract-level dataset
use "${final}/bin_black_rank_median_poor_share", clear
gen nonpoor_share2000 = 100* (1 - poor_share2000)
replace high_black = high_black * 100

*Binscatter of frac of tracts high-black vs pov rate
scatter high_black nonpoor_share2000 , xline(0.1)  /// 
	ytitle("Percent of Tracts where Black Men with Parents at p=25" ///
	"have Mean Rank above 50th Percentile") ///
	xtitle("Share Above Poverty Line in Tract in 2000 (%)") ///
	title(${title_size}) xline(90, lpattern(dash)) ///
	text(12.5 99 "Poverty Rate Below 10%", size(small)) ///
	ylab(,gmax)
graph export "${figures}/bin_frac_high_black_v_nonpoor.${img}", replace