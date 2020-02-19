/*

This .do file creates Appendix Figure 6. 

*/

*set the varlist that will be looped over
local loop_vars kir_2par kir_par_nohome kir_1par

*set the non-var specific graph specs
local msize 0.75

*loop over gender
foreach g in M {
	
	*loop over selected outcome variables
	foreach var of local loop_vars {
		
		*set the var specific specs
		if "`var'"=="kir_2par" {
			local ytitle "Mean Child Individual Income Rank"
			local ymin 20
			local ymax 80
			local step 10
			local xtext_1 40
			local ytext_1 38
			local xtext_2 65
			local ytext_2 65
			local textunit ""
			local gap notlinear //linear or notlinear
			local gapnum1 25 //specify where to calculate the gap
			local gapnum2 75
		}
		
		if "`var'"=="kir_1par" {
			local ytitle "Mean Child Individual Income Rank"
			local ymin 20
			local ymax 80
			local step 10
			local xtext_1 40
			local ytext_1 38
			local xtext_2 75
			local ytext_2 65
			local textunit ""
			local gap notlinear //linear or notlinear
			local gapnum1 25 //specify where to calculate the gap
			local gapnum2 75
		}
		
		
		if "`var'"=="kir_mom_nohome" {
			local ytitle "Mean Child Individual Income Rank"
			local ymin 20
			local ymax 80
			local step 10
			local xtext_1 40
			local ytext_1 38
			local xtext_2 75
			local ytext_2 65
			local textunit ""
			local gap notlinear //linear or notlinear
			local gapnum1 25 //specify where to calculate the gap
			local gapnum2 75
		}
		
*Do the set up for making the p25 gap and plotting a line to show the gap

	use "${final}/bin_`var'_par_rank_`g'.dta", replace
	generate gender = "`g'" 
	replace pline25 = pline25[1] in 2
	
	*define the black white gap at p25 on the points themselves since not linear
	local gapvar1 `var'
	local gapvar2 `var'
	qui: su `var' if par_pctile ==25 
	local max = `r(max)'
	local min = `r(min)'
	replace pline25_val = `max' in 2
	replace pline25_val = `min' in 1

	gen pline75 = . 
	replace pline75 = 75 in 1
	replace pline75 = 75 in 2
		
	gen pline75_val = . 
	qui: su `var' if par_pctile ==75 
	local max = `r(max)'
	local min = `r(min)'
	replace pline75_val = `max' in 2
	replace pline75_val = `min' in 1
	
	*Using the predicted values for the pX gap
	foreach gap_p in 1 2 {
		summ `gapvar1' if gender=="`g'" & kid_race==1 & par_pctile==`gapnum`gap_p''
		local white_p`gapnum`gap_p'' `r(mean)'
		summ `gapvar2' if gender=="`g'" & kid_race==2 & par_pctile==`gapnum`gap_p''
		local black_p`gapnum`gap_p'' `r(mean)'
		local gap`gapnum`gap_p'' : di %4.1f `white_p`gapnum`gap_p'''-`black_p`gapnum`gap_p'''
		}
		
	tw  (scatter `var' par_pctile if gender=="`g'" & kid_race==1, msize(`msize') mcolor(navy) msymbol(${sym_white})) ///
		(lfit `var' par_pctile if gender=="`g'" & kid_race==1, lcolor(navy)) ///
		(scatter `var' par_pctile if gender=="`g'" & kid_race==2, msize(`msize') mcolor(maroon) msymbol(${sym_black})) ///
		(lfit `var' par_pctile if gender=="`g'" & kid_race==2, lcolor(maroon)) ///
		(line pline`gapnum1'_val pline`gapnum1', lcolor(black) lwidth(medthick)) ///
		(line pline`gapnum2'_val pline`gapnum2', lcolor(black) lwidth(medthick)) ///
		,ytitle(`ytitle', margin(t=3)) xtitle("Parent Household Income Rank") ///
		ylabel(`ymin'(`step')`ymax', gmax gmin) ///
		legend(order(1 "White" 3 "Black") rows(2) ring(0) pos(5) bm(b=3)) ///
		text(`ytext_1' `xtext_1' "Diff. at p=25: `gap25'`textunit'", size(small)) ///
		text(`ytext_2' `xtext_2' "Diff. at p=75: `gap75'`textunit'", size(small)) ///
		title(${title_size})
	graph export "${figures}/bin_`var'_par_rank_`g'.${img}", replace
	}
}		