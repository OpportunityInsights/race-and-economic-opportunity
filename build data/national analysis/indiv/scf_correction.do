/*

This .do file corrects for the bias created by imperfect observation of wealth 
in the ACS/Census/tax records dataset. 

*/

* ---------------------------------
* Creating relevant locals
* ---------------------------------
	// The locals are from the results in cond_regressions_mskd. 
	// To avoid having to read in the results from that file, we hard-code the 
	// results here. 
* Short regressions, p25
local b_white_short_m_25 = 9.1
local b_white_short_f_25 = -1.9

* Intermediate regressions, p25
local b_white_intermediate_m_25 = 8.4
local b_white_intermediate_f_25 = -2.3

* Short regressions, p75
local b_white_short_m_75 = 11.4
local b_white_short_f_75 = -0.7

* Intermediate regressions, p75
local b_white_intermediate_m_75 = 11.0
local b_white_intermediate_f_75 = -1.2

* ---------------------------------
* Setting up
* ---------------------------------
* Load full dataset
use "${ext}/rscfp2001", clear
replace nvehic = 5 if nvehic > 5 

* Verify that there are no missing variables
nmissing

* Label variables: https://www.federalreserve.gov/econres/files/bulletin.macro.txt
lab var houses "Value of primary residence"
lab var hhouses "Whether own a primary residence"
lab var PAYMORT1 "Amount paid monthly in mortgage payments on primary mortgage"
lab var nvehic "Vehicles owned or leased by the household"

* Shorten variable names
ren (networth PAYMORT1) (nw mort)

* Gen race dummies
gen white = RACECL4 == 1

* Gen education dummies
  // we will treat less than HS as the base category
gen hs = edcl == 2
gen coll = edcl == 3
gen bach = edcl == 4

* ---------------------------------
* Generate rank variables
* ---------------------------------
* Restrict sample
keep if kids > 0

* Generate rank variables (after getting rid of people without kids)
xtile r_nw = nw [pw = wgt], nq(1000)
replace r_nw = r_nw/10
xtile r_income = income [pw = wgt], nq(1000)
replace r_income = r_income/10

*************************
* Run regression
*************************
* Save base 
tempfile base 
save `base' 

* Loop over percentiles
foreach percentile in 25 75 {

	use `base', clear 

	if "`percentile'" == "25" replace r_income = r_income - 25 // recentering
	if "`percentile'" == "75" replace r_income = r_income - 75 // recentering

	capture drop white_r_income
	gen white_r_income = white*r_income

	* Only include black and white families
	keep if RACECL4 == 1 | RACECL4 == 2 // corresponds to white or black

	* Store regression coefficients with no proxies
	reg r_nw r_income white white_r_income hs coll bach married [pw = wgt]
	local beta_wealth_short_`percentile' = _b[white]

	* Store regression coefficients with proxies
	reg r_nw r_income white white_r_income hs coll bach married houses hhouses mort nvehic [pw = wgt]
	local beta_wealth_intermediate_`percentile' = _b[white]
}

* Loop over percentiles and genders
foreach percentile in 25 75 {
	foreach gender in m f {
		gen corrected_`percentile'_`gender' = (`beta_wealth_short_`percentile'' * `b_white_intermediate_`gender'_`percentile'' /// 
			- `beta_wealth_intermediate_`percentile'' * `b_white_short_`gender'_`percentile'') / /// 
			(`beta_wealth_short_`percentile'' - `beta_wealth_intermediate_`percentile'')
		local corrected_`percentile'_`gender' = (`beta_wealth_short_`percentile'' * `b_white_intermediate_`gender'_`percentile'' /// 
			- `beta_wealth_intermediate_`percentile'' * `b_white_short_`gender'_`percentile'') / /// 
			(`beta_wealth_short_`percentile'' - `beta_wealth_intermediate_`percentile'')
	}
}

keep corrected* 

* ---------------------------------
* Export results for table 
* ---------------------------------
preserve 

gen label = ""
gen parents_at_p25 = . 
gen parents_at_p75 = . 

replace label = "b Tilde" in 1
replace parents_at_p25 = `b_white_short_m_25'  in 1
replace parents_at_p75 = `b_white_short_m_75'  in 1

replace label = "b Hat" in 2 
replace parents_at_p25 = `b_white_intermediate_m_25'  in 2
replace parents_at_p75 = `b_white_intermediate_m_75'  in 2

replace label = "lambda Tilde" in 3 
replace parents_at_p25 = `beta_wealth_short_25'  in 3 
replace parents_at_p75 = `beta_wealth_short_75'  in 3 

replace label = "lambda Hat" in 4 
replace parents_at_p25 = `beta_wealth_intermediate_25'  in 4
replace parents_at_p75 = `beta_wealth_intermediate_75'  in 4

replace label = "Corrected (b)" in 5 
sum corrected_25_m
replace parents_at_p25 = `r(mean)'  in 5 
sum corrected_75_m
replace parents_at_p75 = `r(mean)'  in 5 

keep label parents_at*

drop if _n > 5

save "${final}/scf_correction", replace 

* ---------------------------------
* Export results for graphing
* ---------------------------------
restore 
drop if _n > 1
keep corrected_*
rename *_m *1 
rename *_f *2 
gen aux = _n 
reshape long corrected_25 corrected_75, i(aux) j(gender)
tostring gender, replace 
replace gender = "M" if gender == "1" 
replace gender = "F" if gender == "2" 
drop aux 
gen aux = _n 
gen corrected = . 
gen p = . 
set obs 4
replace gender = "M" in 3 
replace gender = "F" in 4 
replace p = 25 in 1 
replace p = 25 in 2 
replace p = 75 in 3 
replace p = 75 in 4 
sum corrected_25 if gender == "M"
replace corrected = `r(mean)' if gender == "M" & p == 25 
sum corrected_25 if gender == "F"
replace corrected = `r(mean)' if gender == "F" & p == 25 
sum corrected_75 if gender == "M"
replace corrected = `r(mean)' if gender == "M" & p == 75 
sum corrected_75 if gender == "F"
replace corrected = `r(mean)' if gender == "F" & p == 75 

gen ylab = corrected + 0.3 if gender == "M"
replace ylab = 0 if gender == "F" 

tempfile output 
save `output'

foreach p in 25 75 {
	use `output', clear 
	keep if p == `p' 
	save "${final}/wealth proxies correction `p'.dta", replace
}
