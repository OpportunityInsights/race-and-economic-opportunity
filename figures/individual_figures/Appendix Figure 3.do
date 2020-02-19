/*

This .do file creates Appendix Figure 3. 

*/

// This figure is constructed from the national_percentile_outcomes dataset 
// that is publicly available from the Opportunity Insights website. 
use "${final}/national_percentile_outcomes.dta", clear

ds kfr* 
foreach var in `r(varlist)' {
	replace `var' = 100 * `var'
}

* ----------------------------------------------
* Appendix Figure 3
* ----------------------------------------------
local psize 0.5 

* Loop over races 
foreach race in white black hisp asian {
	reg kfr_native_`race'_pooled par_pctile // [w = kfr_native_`race'_pooled_n]
	local native_slope : di %4.2f _b[par_pctile]
	local native_intercept : di %4.2f _b[_cons]

	reg kfr_imm_`race'_pooled par_pctile // [w = kfr_imm_`race'_pooled_n]
	local imm_slope : di %4.2f _b[par_pctile]
	local imm_intercept : di %4.2f _b[_cons]

	tw ///
		(scatter kfr_native_`race'_pooled par_pctile, msize(*`psize') mcolor(maroon) msymbol(diamond)) /// 
		(scatter kfr_imm_`race'_pooled par_pctile, msize(1) mcolor(dkgreen) msymbol(plus)) ///
		(lfit kfr_native_`race'_pooled par_pctile, lcolor(maroon)) ///
		(lfit kfr_imm_`race'_pooled par_pctile, lcolor(forest_green)) ///
		, ///
		xtitle("Parent Household Income Rank", color(black)) ///
		ytitle("Mean Child Household Income Rank", color(black) margin(t=3)) ///
		ylabel(20(20)80, gmax tlcolor(black) labcolor(black)) ///
		xlabel(0(20)100, tlcolor(black) labcolor(black)) plotregion(margin(zero)) ///
		title(${title_size}) ///
		legend(order	(1 "Mothers Born in U.S. (Intercept: `native_intercept'; Slope: `native_slope')" ///
						 2 "Mothers Born Outside U.S. (Intercept: `imm_intercept'; Slope: `imm_slope')") ///
						 position(5) cols(1) ring(0) size(small) bm(b=3) color(black))  /// 
		xscale(range(0 101) lcolor(black)) ///
		yscale(lcolor(black)) 
graph export "${figures}/bin_all_imm_native_`race'_par_rank.pdf", as(pdf) name("Graph") replace
}