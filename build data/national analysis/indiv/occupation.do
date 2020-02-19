/*

This .do file produces the distribution of occupations by race-gender-parent income.

*/

set more off

*------------------------------------------------------------------------------
* Occupational histogram
*------------------------------------------------------------------------------

use ///
	kid_pik			gender			kid_race ///
	par_rank		kid_occ 		cohort ///
	kid_pos_hours ///
	using "${work}/race_work_78_83${suf}", clear
	
* Restrict to those who are working
keep if kid_pos_hours==1

* Generate occupation variables
tostring kid_occ, replace format(%04.0f)
g kid_1occ=substr(kid_occ,1,1)
destring kid_1occ, replace

* Generate parent deciles
g par_d=ceil(par_rank*10)

* Collapse to get counts
collapse (count) count=cohort, by(kid_1occ par_d gender kid_race)

* Output collapse
order kid_race gender par_d kid_1occ count
sort kid_race gender par_d kid_1occ count
compress
save "${out}/occupation_histogram", replace
