/*

This .do file reads in the long dataset of outcomes and reshapes wide. 

*/

* --------------------------------------------------------
* Setting up 
* --------------------------------------------------------

* Set outcomes of interest
local outcomes ///
	kir kfr kid_jail has_dad has_mom kir_working kir_2par two_par kid_working kir_everwork ///
	kir_1par kir_everwork_1par kir_everwork_2par kir_everwork_dad kir_everwork_nodad ///
	kir_dad kir_nodad
	
* Set parent ranks 
local parrank 25 75

* Import data
use if par_state>0 & par_state!=72 using "${final}/tract_mobility_mskd", clear

* --------------------------------------------------------
* Rearranging, changing variable names  
* --------------------------------------------------------

* Take par_ off of the geo identifiers
rename (par_state par_county par_tract) (state county tract)

rename n_* *_n

* Keep only the relevant vars
local keep_var state county tract kid_race gender
foreach outc of local outcomes {
	local keep_var `keep_var' ///
		`outc'_icept `outc'_slope `outc'_icept_se `outc'_slope_se ///
		`outc'_cov   `outc'_n
}

keep `keep_var' par_rich

* Shorten variable names 
renvars kir_working*, subst(kir_working kinr_working)
renvars kir_2par*, subst(kir_2par kr_2par)
renvars *working*, subst("working" "w")
renvars *everwork*, subst("everwork" "ew")
renvars kir_ew_1par*, subst("1par" "1")
renvars kir_ew_2par*, subst("2par" "2")
renvars kir_ew_dad*, subst("dad" "d")
	// using a for "absent"
renvars kir_ew_nodad*, subst("nodad" "a")
renvars kir_dad*, subst("dad" "d")
renvars kir_nodad*, subst("nodad" "a")

* Change outcomes local to reflect these changes to variable names 
local old kir_working kir_2par kid_working kir_everwork kir_everwork_1par kir_everwork_2par ///
	kir_everwork_dad kir_everwork_nodad kir_dad kir_nodad
local outcomes2: list outcomes - old
local outcomes2 `outcomes2' kinr_w kr_2par kid_w kir_ew kir_ew_1 kir_ew_2 kir_ew_d kir_ew_a ///
	kir_d kir_a

* Rename race and gender for reshape
gen kid_race_name = ""
replace kid_race_name = "_pooled"   if kid_race == 0
replace kid_race_name = "_white"   	if kid_race == 1
replace kid_race_name = "_black"   	if kid_race == 2
replace kid_race_name = "_asian"   	if kid_race == 3
replace kid_race_name = "_hisp"    	if kid_race == 4
replace kid_race_name = "_natam"   	if kid_race == 5
replace kid_race_name = "_other"   	if kid_race == 6
replace kid_race_name = "_missing" 	if kid_race == -9
drop kid_race

gen gender_name = ""
replace gender_name = "_male"   if gender == "M"
replace gender_name = "_female" if gender == "F"
replace gender_name = "_pooled" if gender == "P"
drop gender

foreach prk in `parrank' {
	foreach outc in `outcomes2' {
		gen `outc'_p`prk' = `outc'_icept + 0.`prk'*`outc'_slope
		gen `outc'_p`prk'_se = sqrt(`outc'_icept_se^2 ///
									+ 0.`prk'^2*`outc'_slope_se^ 2 ///
									+ 2*0.`prk'*`outc'_cov )
	}
}

* Replace nojail with jail
ds *_nojail*
local nojail `r(varlist)'

	// Don't want the ones with se or n
ds *nojail*se *nojail*_n
local nojail_se `r(varlist)'
local nojail_out : list nojail - nojail_se
di "`nojail_out'"

	// Replace with 1 - jail 
foreach var in `nojail_out' {
	replace `var' = 1 - `var'
}
rename *_jail* *_j*

* Keep only relevant variables 
keep state county tract kid_race gender *_p* *_n*  par_rich
drop *_cov* *_icept* *_slope*

* Reshape (wide on race)
ds state county tract  kid_race_name gender_name, not
unab stub : `r(varlist)'
reshape wide `stub', i(state county tract gender_name) j(kid_race_name) string

* Reshape (wide on gender)
ds state county tract gender_name, not
unab stub : `r(varlist)'
reshape wide `stub' , i(state county tract) j(gender_name) string

* Rename variables
rename *_n_* *_*_n
foreach prk in `parrank' {
	rename *_p`prk'_* *_*_p`prk'
	rename *_se_* *_*_se
}

* Fix the names that we had to shorten at the beginning
rename kinr_w* kir_w*
rename *_w_* *_work_*
rename kr_2par* kir_2par*
rename *_j_* *_jail_*
rename *_ew_* *_ewrk_*
rename *ewrk_1* *ewrk1p*
rename *ewrk_2* *ewrk2p*
rename *ewrk_d_* *ewrkf_*
rename *ewrk_a_* *ewrknf_*
rename *kir_d_* *kir_f_*
rename *kir_a_* *kir_nf_*

* --------------------------------------------------------
* Label and save   
* --------------------------------------------------------

foreach var of varlist _all {
	label var `var' ""
}

save "${final}/tract_race_gender_mskd.dta", replace
