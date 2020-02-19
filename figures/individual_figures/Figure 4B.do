/*

This .do file creates Figure 4B. 

*/

use "${final}/bin_kir_par_rank_bw.dta", clear

* calculate slopes
foreach race in white black{
	reg  kir_`race' par_pctile
	local slope_`race' : di %3.2f _b[par_pctile]
	local icpt_`race' : di %3.2f _b[_cons]
	foreach p in 25 75{
		sum kir_`race' if par_pctile == `p', meanonly
		local y_`race'_`p'= `r(mean)'
	}	
}

* calculate gaps at p25 and p75
foreach p in 25 75{
	gen pline`p' = `p'
	gen pline_val_`p' =.
	replace pline_val_`p'  = `y_white_`p'' in 1
	replace pline_val_`p' = `y_black_`p'' in 2
	local gap = `y_white_`p'' - `y_black_`p''
	local gap_p`p' : di %4.1f `gap'
}

* create graph
twoway ///
	(scatter kir_white par_pctile , msize(0.75) mcolor(navy) m(${sym_white})) ///
	(scatter kir_black par_pctile , msize(0.75) mcolor(maroon) m(${sym_black})) ///
	(lfit kir_white par_pctile , lcolor(navy) ) ///
	(lfit kir_black par_pctile , lcolor(maroon) ) ///
	(line pline_val_25 pline25, lcolor(black) lwidth(medthick)) ///
	(line pline_val_75 pline75, lcolor(black) lwidth(medthick)) ///
	, ///
	ytitle("Mean Child Individual Income Rank") ///
	xtitle("Parent Household Income Rank") ///
	ylabel(20(20)80, gmax gmin) ///
	xlabel(0(20)100) ///
	text(35 35 "Diff. at p=25: `gap_p25'", size(small)) ///
	text(47 83 "Diff. at p=75: `gap_p75'", size(small)) ///
	legend(order(1 "White (Intercept: `icpt_white', Slope: `slope_white')" ///
				 2 "Black (Intercept: `icpt_black', Slope: `slope_black')") ///
				 col(1) ring(0) pos(4) bm(b=3)) ///
	title(${title_size}) 
graph export "${figures}/bin_kir_par_rank_bw.${img}", replace