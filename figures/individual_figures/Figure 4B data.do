/*

This .do file rearranges the data for Figure 4B. 

*/

* load data
use "${final}/pctile_clps_mskd", clear

* keep black & white only 
keep if inrange(kid_race, 1, 2)

* collapse to pool gender
collapse (mean) kir (rawsum) count [w = count], by(par_pctile kid_race)

* create id and race ending for reshape
gen n = _n
gen race_tag = ""
replace race_tag = "_white" if kid_race == 1
replace race_tag = "_black" if kid_race == 2

* reshape to make kir_white and kir_black
reshape wide kir count, i(n par_pctile) j(race_tag) string
collapse kir_black kir_white count_white count_black, by(par_pctile)

* scale ranks by 100
foreach kir in kir_white kir_black {
	replace `kir' = 100 * `kir'
}

keep par_pctile kir_white kir_black
ds par_pctile, not
chopper, vars(`r(varlist)') 
save "${final}/bin_kir_par_rank_bw", replace