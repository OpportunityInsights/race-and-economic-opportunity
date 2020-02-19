/*

This .do file prepares CZ-level estimates for mapping. 

*/

use if par_cz>0 using "${final}/cz_mobility_mskd.dta", clear

rename par_cz cz

* ----------------------------
* Construct estimates at p25 and p75 
* ----------------------------
local parrank 25 75
local outcomes kir kfr

foreach prk in `parrank' {
	foreach outc in `outcomes' {
		gen `outc'_p`prk' = `outc'_icept + 0.`prk'*`outc'_slope
		gen `outc'_p`prk'_se = sqrt(`outc'_icept_se^2 ///
									+ 0.`prk'^2*`outc'_slope_se^ 2 ///
									+ 2*0.`prk'*`outc'_cov )
	}
}


* ----------------------------
* Keep estimates for mapping and reshape 
* ----------------------------
*Only want to release the points that get used (13 maps)
drop if !inlist(kid_race,0,1,2,4)
gen race_label=""
replace race_label="_pooled" if kid_race==0
replace race_label="_white" if kid_race==1
replace race_label="_black" if kid_race==2
replace race_label="_hispanic" if kid_race==4
drop kid_race

replace gender = "_" + gender

keep cz race_label gender kir_p*5 kfr_p*5 n_kfr n_kir

reshape wide kir* kfr* n_* , i(cz gender) j(race_label) string
reshape wide kir* kfr* n_*, i(cz) j(gender) string
	
* ----------------------------
* Make bins  
* ----------------------------
* Create bins 
ds cz, not
local map_vars `r(varlist)'
foreach var in `map_vars' {
	xtile bin_`var'=`var', nq(100)
}
tempfile base
save `base'		

* Get the max and min in each bin 
foreach var in `map_vars' {
	use `base', clear
	drop if missing(bin_`var')
	collapse (min) min_`var'=`var' (max) max_`var'=`var', by(bin_`var')
	rename bin_`var' bin
	tempfile temp_`var'
	save `temp_`var''
}
	
gettoken first map_vars: map_vars
di "`first'"
use `temp_`first'', clear
foreach file in `map_vars' {
	merge 1:1 bin using `temp_`file'', nogen
}

tempfile bin_val
save `bin_val'

* ----------------------------
* Save results  
* ----------------------------
use `base', clear
keep bin_* cz
ds bin_*
chopper, vars(`r(varlist)')
save "${final}/map_cz_estimate", replace
			
use `bin_val', clear
chopper, vars(min_* max_*)
save "${final}/map_cz_bin_min_max", replace