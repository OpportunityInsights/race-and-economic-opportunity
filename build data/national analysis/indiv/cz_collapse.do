/*

This .do file creates a CZ-level collapse of certain variables. 
Although the CZ collapse is used as one of the online data tables, 
we make it with the build data because it is used to create various other 
figures and tables. 

*/

* -------------------------------------------------------------
* Construct population counts by CZ  
* -------------------------------------------------------------
import delimited "${ext}/county_pop_by_race_gender2000.csv", clear
egen cz_pop_white2000 = rowtotal(fuq001-fuq206)
egen cz_pop_black2000 = rowtotal(fuq207-fuq412)
egen cz_pop_hisp2000 = rowtotal(fm3001-fm3046)
drop state county
gen cty = string(statea,"%02.0f") + string(countya,"%03.0f")
keep cty cz_pop*
destring cty, replace
merge m:1 cty using "${ext}/cty_cz_cw.dta", keep(3) nogen
collapse (rawsum) cz_pop*, by(cz)
lab var cz_pop_white2000 "CZ Population - White (2000)"
lab var cz_pop_black2000 "CZ Population - Black (2000)"
lab var cz_pop_hisp2000  "CZ Population - Hispanic (2000)"
tempfile counts
save `counts'

* -------------------------------------------------------------
* Load 100 bin min and max values for CZ map  
* -------------------------------------------------------------
use "${final}/map_cz_bin_min_max", clear

* list covariates to use
local list kir_p25_black_F kir_p75_black_F kir_p25_hispanic_F kir_p75_hispanic_F ///
			kir_p25_white_F kir_p75_white_F kir_p25_black_M kir_p75_black_M ///
			kir_p25_hispanic_M kir_p75_hispanic_M kir_p25_white_M kir_p75_white_M ///
			kfr_p25_black_P kfr_p25_pooled_P kfr_p25_white_P

* save the mean of the min and max bins
foreach var of local list {
	egen mean_`var' = rowmean(min_`var' max_`var')
	
}
drop min* max*
tempfile mean
save `mean'

* load CZ's matched to 100 bins
use "${final}/map_cz_estimate", clear

* merge bins to mean bin values
foreach var of local list {
	rename bin_`var' bin
	merge m:1 bin using `mean', nogen keepusing(mean_`var') 
	rename bin bin_`var'
}
drop bin*
renvars mean_*, presub(mean_ )

* rename variables
foreach p in 25 75{
	renvars *p`p'*, postfix(_p`p')
	renvars *p`p'*, subst("_p`p'_" "_")
}

renvars *F*, subst("F" "female")
renvars *M*, subst("M" "male")
renvars *P*, subst("P" "pooled")

renvars *hisp*, subst("hispanic" "hisp")
renvars *pooled_pooled*, subst("pooled_pooled" "pooled")

* label variables
label var kfr_pooled_p25 ///
	"Kid Household Income Rank for Children with Parents at 25th Pct"

* loop through variables
foreach kr in kir kfr{
foreach p in 25 75{
foreach race in white black hisp {
foreach gender in male female pooled {

	* set string variables for different subgroups
	if "`kr'" == "kir" local kr_lab "Kid Individual Income Rank"
	if "`kr'" == "kfr" local kr_lab "Kid Household Income Rank"
	if "`race'" == "white" local race_lab "White"
	if "`race'" == "black" local race_lab "Black"
	if "`race'" == "hisp" local race_lab "Hispanic"
	if "`gender'" == "male" local gender_lab "Males"
	if "`gender'" == "female" local gender_lab "Females"
	if "`gender'" == "pooled" local gender_lab "Children"

	* confirm variable exists
	cap confirm var `kr'_`race'_`gender'_p`p'
	if !_rc{
	
	* label it if it exists
	label var `kr'_`race'_`gender'_p`p' ///
	"`kr_lab' for `race_lab' `gender_lab' with Parents at the `p'th Pct"
	
	}
}
}
}
}

* order variables
order cz* kfr_pooled* kfr* *black* *hisp* *white*

* drop missing cz 
drop if cz ==. 

* multiply with 100 
qui: ds cz , not
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 100
	}
	

* tostring vars and save (+export csv)
qui: ds cz, not
foreach var in `r(varlist)' {
	format `var' %4.2f
	tostring `var', replace force
	replace `var' =substr(`var', 1, 5) 
	}
	
tempfile cz_collapse
save `cz_collapse' 

keep cz czname pop2000
rename czname cz_name

* label variables
label var cz_name "Name of Commuting Zone"
rename pop2000 cz_pop2000 
label var cz_pop2000 "CZ Population (2000)"
tempfile names
save `names'

use `cz_collapse', clear
destring *, replace 
merge 1:1 cz using `counts', nogen
merge 1:1 cz using `names', nogen	
label var cz "Childhood Commuting Zone"	

order cz cz_name cz_pop2000
order cz_pop_*, alpha after(cz_pop2000)
compress

* export data tables
save "${online_data_tables}/cz_collapse", replace
export delimited "${online_data_tables}/cz_collapse.csv", replace
