/*

This .do file create the data for Appendix Figure 2. 

*/

* load data
use "${final}/pctile_clps_mskd", clear

* keep black & white only 
keep if inrange(kid_race, 1, 5)

* collapse to pool gender
collapse (mean) kfr (rawsum) count [w = count], by(par_pctile kid_race)

* create id and race ending for reshape
gen n = _n
gen race_tag = ""
replace race_tag = "_white" if kid_race == 1
replace race_tag = "_black" if kid_race == 2
replace race_tag = "_asian" if kid_race == 3
replace race_tag = "_hispanic" if kid_race == 4
replace race_tag = "_natam" if kid_race == 5

drop kid_race n

* reshape to make kfr_white and kfr_black
reshape wide kfr count, i(par_pctile) j(race_tag) string

*construct the densities manually
foreach race in white black asian hispanic natam {
	egen total_`race' = total(count_`race')
	gen density_`race' = count_`race' / total_`race'
}

keep density_* par_pctile
chopper, vars(density_*)
save "${final}/density_byrace", replace