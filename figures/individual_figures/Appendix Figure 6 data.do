/*

This .do file rearranges the data for Appendix Figure 6. 

*/

*set the varlist that will be looped over
local loop_vars kir_2par kir_par_nohome kir_1par


* load data 
use "${final}/pctile_clps_mskd", clear 

*restrict to black and white 
keep if inlist(kid_race,1,2)

*scale up to be between 1 and 100
foreach var of local loop_vars {
		replace `var'=`var'*100
}

*set the non-var specific specs
local gap notlinear 

tempfile base
save `base'


*loop over gender
foreach g in  M  {
	
	*loop over selected outcome variables
	foreach var of local loop_vars {
		
	use `base', clear

	if "`gap'"=="linear" {
		*define the black white gap at p25 on the predicted line
		reg `var' par_pctile if gender=="`g'" & kid_race==1
		predict white_pred
		reg `var' par_pctile if gender=="`g'" & kid_race==2
		predict black_pred
		
		local gapvar1 white_pred
		local gapvar2 black_pred
	}
	if "`gap'"=="notlinear" {
		*define the black white gap at p25 on the points themselves since not linear
		
		local gapvar1 `var'
		local gapvar2 `var'
	}
	
	*Using the predicted values for the pX gap
	summ `gapvar1' if gender=="`g'" & kid_race==1 & par_pctile==`gapnum'
	local white_p`gapnum' `r(mean)'
	summ `gapvar2' if gender=="`g'" & kid_race==2 & par_pctile==`gapnum'
	local black_p`gapnum' `r(mean)'
	local gap`gapnum': di %4.1f `white_p`gapnum''-`black_p`gapnum''
	
	
	*make a series that will plot the black line at pX
	*only need two points
	gen pline`gapnum'=`gapnum' if _n<=2
	gen pline`gapnum'_val=.
	replace pline`gapnum'_val=`white_p`gapnum'' if _n==1
	replace pline`gapnum'_val=`black_p`gapnum'' if _n==2
	
	preserve
		keep par_pctile `var' kid_race pline*
		ds par_pctile kid_race, not
		chopper , vars(`r(varlist)')
		save "${final}/bin_`var'_par_rank_`g'", replace
	restore
	}
}