/* 

This .do file creates Figures 5A and B. 

*/

foreach g in M F {
	use "${final}/bin_kir_par_rank_`g'", clear

	* Slopes
	local i = 0
	foreach race in white black{
		local ++i
		reg  kir par_pctile if kid_race == `i'
		local slope_`race' : di %3.2f _b[par_pctile]
		local icpt_`race' : di %3.2f _b[_cons]
		foreach p in 25 75{
			sum kir if par_pctile == `p' & kid_race == `i', meanonly
			local y_`race'_`p'= `r(mean)'
		}	
	}
	* calculate gaps at p25 and p75
	foreach p in 25 75{
		cap drop pline_val_`p'
		cap drop pline`p'
		gen pline`p' = `p'
		gen pline_val_`p' =.
		replace pline_val_`p'  = `y_white_`p'' in 1
		replace pline_val_`p' = `y_black_`p'' in 2
		local gap = `y_white_`p'' - `y_black_`p''
		local gap_p`p' : di %4.1f `gap'
	}

	* Plot 
	local psize 0.75
	twoway ///
		(scatter kir par_pctile if kid_race == 1, ///
			msize(`psize') mcolor(navy) msymb(${sym_white})) ///
		(scatter kir par_pctile if kid_race == 2, ///
			mcolor(maroon) msize(`psize') msymb(${sym_black})) ///
		(lfit kir par_pctile if kid_race == 1, lcolor(navy)) ///
		(lfit kir par_pctile if kid_race == 2, lcolor(maroon)) ///
		(line pline_val_25 pline25, lcolor(black) lwidth(medthick)) ///
		(line pline_val_75 pline75, lcolor(black) lwidth(medthick)) ///
		, xtitle("Parent Household Income Rank") ///
		ytitle("Mean Child Individual Income Rank") ///
		ylabel(20(20)80, gmax gmin) ///
		xlabel(0(20)100) ///
		text(35 35 "Diff. at p=25: `gap_p25'", size(small)) ///
		text(48 85 "Diff. at p=75: `gap_p75'", size(small)) ///
		legend(order(1 "White (Intercept: `icpt_white', Slope: `slope_white')" ///
				 2 "Black (Intercept: `icpt_black', Slope: `slope_black')") ///
			col(1) ring(0) pos(4) bm(b=3)) ///
		title(${title_size}) 
	graph export "${figures}/bin_kir_par_rank_`g'.${img}", replace	
	}
