/*

This .do file creates a national percentile collapse by race and gender. 

*/

set more off

*Read in the skinny data (only one row per kid required for this collapse)
	// Use only the 1978-1983 cohorts
use ///
	kid_pik			kid_race		gender ///
	cohort			par_rank		${pctilevars} ///
	using "${work}/race_work_78_83${suf}", clear
	
*Generate parent percentiles
g par_pctile=ceil(100*par_rank)

*Loop over outcomes to track non-missing count
foreach var of global pctilevars {
	g n_`var'=~mi(`var')
}
	
*Collapse variables
collapse (mean) ${pctilevars} (sum) n_* (count) count=cohort, by(par_pctile kid_race gender)

*Clean and output
order par_pctile kid_race gender count
sort par_pctile kid_race gender count
compress
save "${out}/pctile_clps", replace
