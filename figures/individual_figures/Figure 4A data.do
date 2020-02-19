/*

This .do file rearranges the data for Figure 4A. 

*/

* load data
use "${final}/pctile_clps_mskd", clear

* keep black & white only 
keep if inrange(kid_race, 1, 2)

* collapse to pool gender
collapse (mean) kid_married (rawsum) count [w = count], by(par_pctile kid_race)

* create id and race ending for reshape
gen n = _n
gen race_tag = ""
replace race_tag = "_white" if kid_race == 1
replace race_tag = "_black" if kid_race == 2

* reshape to make kir_white and kir_black
reshape wide kid_married count, i(n par_pctile) j(race_tag) string

collapse kid_married_black kid_married_white count_white count_black, by(par_pctile)

* scale ranks by 100
foreach var of varlist kid_married_white kid_married_black {
	replace `var' = 100 * `var'
}

* export 
keep par_pctile kid_married_black kid_married_white
ds par_pctile, not
chopper, vars(`r(varlist)')
save "${final}/bin_kid_married_par_rank_bw", replace