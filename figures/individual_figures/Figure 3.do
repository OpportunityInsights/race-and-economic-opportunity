/*

This .do file creates Figure 3.

*/

// This figure is constructed from the national_percentile_outcomes dataset 
// that is publicly available from the Opportunity Insights website. 
use "${final}/national_percentile_outcomes.dta", clear

local psize 0.5

ds kfr*
foreach var in `r(varlist)' {
	replace `var' = 100 * `var'
}

* Set races
local races white black asian hisp natam

* Loop over all and native
foreach kfr_var in kfr kfr_native {

	* Get slopes and intercept terms
	foreach race in `races' {
		reg `kfr_var'_`race'_pooled par_pctile
		local slope_`race' : di %4.2f _b[par_pctile]
		local intercept_`race' : di %4.2f _b[_cons]
	}

	tw ///
		(scatter `kfr_var'_white_pooled par_pctile, msize(*`psize') mcolor(navy) msymbol($sym_white)) ///
		(scatter `kfr_var'_black_pooled par_pctile, msize(*`psize') mcolor(maroon) msymbol($sym_black)) ///
		(scatter `kfr_var'_asian_pooled par_pctile, msize(1) mcolor(forest_green) msymbol(plus)) ///
		(scatter `kfr_var'_hisp_pooled par_pctile, msize(*`psize') mcolor(dkorange) msymbol($sym_hisp)) ///
		(scatter `kfr_var'_natam_pooled par_pctile, msize(*`psize') mcolor(lavender) msymbol($sym_natam)) ///
		(lfit `kfr_var'_white_pooled par_pctile, lcolor(navy)) ///
		(lfit `kfr_var'_black_pooled par_pctile, lcolor(maroon)) ///
		(lfit `kfr_var'_asian_pooled par_pctile, lcolor(forest_green)) ///
		(lfit `kfr_var'_hisp_pooled par_pctile, lcolor(dkorange)) ///
		(lfit `kfr_var'_natam_pooled par_pctile, lcolor(lavender)) ///
		,xtitle("Parent Household Income Rank", color(black)) ///
		ytitle("Mean Child Household Income Rank", color(black) margin(t=3)) ///
		ylabel(20(20)80, gmax tlcolor(black) labcolor(black)) ///
		xlabel(0(20)100, tlcolor(black) labcolor(black)) plotregion(margin(zero)) ///
		legend(order	(3 "Asian (Intercept: `intercept_asian'; Slope: `slope_asian')" ///
						 1 "White (Intercept: `intercept_white'; Slope: `slope_white')" ///
						 4 "Hispanic (Intercept: `intercept_hisp'; Slope: `slope_hisp')" ///
						 2 "Black (Intercept: `intercept_black'; Slope: `slope_black')" ///
						 5 "American Indian (Intercept: `intercept_natam'; Slope: `slope_natam')") position(5) cols(1) ring(0) size(vsmall) bm(b=3) color(black)) ///
		title(${title_size}) ///
		xscale(range(0 101) lcolor(black)) ///
		yscale(lcolor(black))
	graph export "${figures}/bin_`kfr_var'_par_rank_all_race.pdf", as(pdf) name("Graph") replace
}


* Just children of immigrant parents -- we do not include Native Americans due to small number 
foreach race in `races' {
	reg kfr_imm_`race'_pooled par_pctile
	local slope_`race' : di %4.2f _b[par_pctile]
	local intercept_`race' : di %4.2f _b[_cons]
}

tw ///
	(scatter kfr_imm_white_pooled par_pctile, msize(*`psize') mcolor(navy) msymbol($sym_white)) ///
	(scatter kfr_imm_black_pooled par_pctile, msize(*`psize') mcolor(maroon) msymbol($sym_black)) ///
	(scatter kfr_imm_asian_pooled par_pctile, msize(1) mcolor(forest_green) msymbol($sym_asian)) ///
	(scatter kfr_imm_hisp_pooled par_pctile, msize(*`psize') mcolor(dkorange) msymbol($sym_hisp)) ///
	(lfit kfr_imm_white_pooled par_pctile, lcolor(navy)) ///
	(lfit kfr_imm_black_pooled par_pctile, lcolor(maroon)) ///
	(lfit kfr_imm_asian_pooled par_pctile, lcolor(forest_green)) ///
	(lfit kfr_imm_hisp_pooled par_pctile, lcolor(dkorange)) ///
	,xtitle("Parent Household Income Rank", color(black)) ///
	ytitle("Mean Child Household Income Rank", color(black) margin(t=3)) ///
	ylabel(20(20)80, gmax tlcolor(black) labcolor(black)) ///
	xlabel(0(20)100, tlcolor(black) labcolor(black)) plotregion(margin(zero)) ///
	title(${title_size}) ///
	legend(order	(3 "Asian (Intercept: `intercept_asian'; Slope: `slope_asian')" ///
				     1 "White (Intercept: `intercept_white'; Slope: `slope_white')" ///
					 4 "Hispanic (Intercept: `intercept_hisp'; Slope: `slope_hisp')" ///
					 2 "Black (Intercept: `intercept_black'; Slope: `slope_black')") ///
					 position(5) cols(1) ring(0) size(vsmall) bm(b=3) color(black)) ///
		xscale(range(0 101) lcolor(black)) ///
		yscale(lcolor(black))
graph export "${figures}/bin_imm_par_rank.pdf", as(pdf) name("Graph") replace