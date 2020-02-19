/* 

This .do file rearranges the data for graphing in Figure 2A. 

*/ 


* ------------------------
* Setting up
* ------------------------

* select variables to be plotted (e.g. kfr)
local varlist_rr kfr kfr_native

* use mobility data by race 
use "${final}/pctile_clps_mskd", clear

* ------------------------
* Rearranging 
* ------------------------

* collapse over parent percentile and kid race (drop gender dimension)
foreach var of local varlist_rr {
	preserve
	collapse (mean) `var' (rawsum) n_`var' [w=n_`var'], ///
		by(par_pctile kid_race)
		tempfile `var'
		save ``var'' 
	restore
}
use `kfr', clear
merge 1:1 par_pctile kid_race using `kfr_native', nogen

* restrict to whites, blacks, asians, hispanics, native americans
keep if inrange(kid_race, 1,5)

gen race =""
replace race = "white" if kid_race == 1
replace race = "black" if kid_race == 2
replace race = "asian" if kid_race == 3
replace race = "hispanic" if kid_race == 4
replace race = "native_american" if kid_race == 5 

drop kid_race 

* reshape wide on race
renvars `varlist_rr' n_*, suff(_)
local reshape_var ""
foreach var in `varlist_rr' {
	local reshape_var "`reshape_var' `var'_ n_`var'_"
}
reshape wide `reshape_var', i(par_pctile) j(race) string

tempfile base
save `base'

* ------------------------
* Exporting 
* ------------------------

foreach var in `varlist_rr' {

	use `base', clear
	
	keep par_pctile `var'_white* `var'_black* `var'_asian* `var'_hispanic* `var'_native_american*
	ds par_pctile, not
	chopper, vars(`r(varlist)') 
	save "${final}/bin_`var'_par_rank.dta", replace
}