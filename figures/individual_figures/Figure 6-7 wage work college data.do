/*

This .do file rearranges the data on wages, employment and college by 
race and gender, for graphing in Figures 6-7. 

*/

* set the varlist that will be looped over
local loop_vars kid_wageflex_rank kid_pos_hours kid_somecoll

* load data 
use "${final}/pctile_clps_mskd", clear 

* restrict to black and white 
keep if inlist(kid_race,1,2)

* make hs completion into dropout
gen kid_no_hs=1-kid_hs

*scale up the vars to be 0 to 100
foreach var of local loop_vars {
	if "`var'" != "kid_hours" {
		replace `var'=`var'*100
	}
}

*loop over gender
foreach g in  F M {
			
	foreach var of local loop_vars {		
	preserve
		keep par_pctile `var' kid_race gender
			ds par_pctile kid_race gender, not
			chopper, vars(`r(varlist)')
			save "${final}/bin_`var'_par_rank_`g'", replace
	restore
	}
}	