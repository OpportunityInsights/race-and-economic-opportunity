/*

This .do file creates Online Data Tables 6 ("Parametric Estimates of Income Ranks for 
Second Generation Immigrant Children by Parent Income, Country of Origin and Gender") 
and 7 ("Non-Parametric Estimates of Income Ranks for Second Generation Immigrant 
Children by Parent Income, Country of Origin and Gender")

*/

*----------------------------------------------------
* 1) Parametric specs
*----------------------------------------------------

use "${final}/robustness_immig_par_mskd.dta", clear

** wide on outcome
reshape wide p*5* n, i(par_rank country gender) j(outcome) string

rename *kfr kfr_*
rename *kir kir_*

** wide on par_rank
reshape wide kir_* kfr_*, i(country gender) j(par_rank) string

rename kfr_*base kfr_pi_*
rename kir_*base kir_pi_*
rename kfr_*dadonly kfr_fi_*
rename kir_*dadonly kir_fi_*

** wide on gender
reshape wide kir_* kfr_* kid_* age_*, i(country) j(gender) string

rename *i_*M *i_M_*
rename *i_*F *i_F_*
rename *i_*P *i_P_*
rename kid_aaa* us_yrs_before*
rename *mom* *mom_*
rename *dad* *dad_*
rename *kid* *kid_*
rename age_mom* age_in2015_mom*
rename age_dad* age_in2015_dad*
rename age_kid* age_in2015_kid*
rename *_n n_*

* use loops to define variable labels to match other files
ds country, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {

	* initialize the label to be blank
	local `var'lab = ""
	
	* start with the type of estimate
	if regex("`var'", "p25") == 1 {
		local `var'lab = "p25"
	}
	else if regex("`var'", "p75") == 1 {
		local `var'lab = "p75"
	}
	else if regex("`var'", "us_yrs_before") == 1 {
		local `var'lab = "Mean num yrs in US before birth of child"
	}
	else if regex("`var'", "^n_") == 1 {
		local `var'lab = "Count"
	}
	else if regex("`var'", "^age") == 1 {
		local `var'lab = "Mean age in 2015"
	}
	* then if they are SEs add a bit for that
	if regex("`var'", "_se$") == 1 {
		local `var'lab = "``var'lab'" + " SE"
	}

	* set the kid income def
	if regex("`var'", "kir") == 1 {
		local `var'lab = "``var'lab'" + ", kid indiv. inc"
	}
	else if regex("`var'", "kfr") == 1 {
		local `var'lab = "``var'lab'" + ", kid fam. inc"
	}

	* set the parent income def
	if regex("`var'", "_pi_") == 1 {
		local `var'lab = "``var'lab'" + ", par. baseline inc"
	}
	else if regex("`var'", "_fi_") == 1 {
		local `var'lab = "``var'lab'" + ", father indiv. inc"
	}

	* set the gender
	if regex("`var'", "_P") == 1 {
			local `var'lab = "``var'lab'" + ", pooled gender"
	}
	else if regex("`var'", "_M") == 1 {
			local `var'lab = "``var'lab'" + ", male"
	}
	if regex("`var'", "_F") == 1 {
			local `var'lab = "``var'lab'" + ", female"
	}
	label var `var' "``var'lab'"
}

* drop the combinations that don't exist

** kfr by gender
foreach var of local outcomevars {
	if regex("`var'", "kfr") == 1 & (regex("`var'", "_M") == 1 | regex("`var'", "_F") == 1) {
			drop `var'
	}
}

** dad inc not male
ds country, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {
	if regex("`var'", "_fi_") == 1 & (regex("`var'", "_P") == 1 | regex("`var'", "_F") == 1) {
			drop `var'
	}

}

** kir, pooled gender
ds country, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {
	if regex("`var'", "kir") == 1 & regex("`var'", "_P") == 1  {
			drop `var'
	}

}

* order the variables
order country *kfr* *kir*F* *kir_pi*M* *kir*_fi*M* age*P age*F age*M us*P us*F us*M

drop *_fi_*
rename *_pi_* *_*

drop age_in2015_kid*

* save the results
save "${online_data_tables}/parametric", replace
export delimited "${online_data_tables}/parametric.csv", replace

*-------------------------------------------
* 2) Non-parametric specs
*-------------------------------------------

use "${final}/robustness_immig_nonpar_mskd.dta", clear

* reshape wide to match other characteristics

** wide on outcome
reshape wide mean n, i(country par_ventile gender par_rank) j(outcome) string
rename mean* *
rename nk* n_k*

** wide on par_rank
reshape wide k* n_*, i(country par_ventile gender) j(par_rank) string
rename *base *_pi_
rename *dadonly *_fi_

** wide on gender
reshape wide k* n_*, i(country par_ventile) j(gender) string

* clean up the labels

* use loops to define variable labels to match other files
ds country par_ventile, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {

	* initialize the label to be blank
	local `var'lab = ""
	
	if regex("`var'", "^n_") == 1 {
		local `var'lab = "Count"
	}
	else {
		local `var'lab = "Mean rank"
	}

	* set the kid income def
	if regex("`var'", "kir") == 1 {
		local `var'lab = "``var'lab'" + " kid indiv. inc"
	}
	else if regex("`var'", "kfr") == 1 {
		local `var'lab = "``var'lab'" + " kid fam. inc"
	}

	* set the parent income def
	if regex("`var'", "_pi_") == 1 {
		local `var'lab = "``var'lab'" + ", par. baseline inc"
	}
	else if regex("`var'", "_fi_") == 1 {
		local `var'lab = "``var'lab'" + ", father indiv. inc"
	}

	* set the gender
	if regex("`var'", "_P") == 1 {
			local `var'lab = "``var'lab'" + ", pooled gender"
	}
	else if regex("`var'", "_M") == 1 {
			local `var'lab = "``var'lab'" + ", male"
	}
	if regex("`var'", "_F") == 1 {
			local `var'lab = "``var'lab'" + ", female"
	}
	label var `var' "``var'lab'"
}


* drop the combinations that don't exist

** kfr by gender
foreach var of local outcomevars {
	if regex("`var'", "kfr") == 1 & (regex("`var'", "_M") == 1 | regex("`var'", "_F") == 1) {
			drop `var'
	}
}

** dad inc not male
ds country, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {
	if regex("`var'", "_fi_") == 1 & (regex("`var'", "_P") == 1 | regex("`var'", "_F") == 1) {
			drop `var'
	}

}

** kir, pooled gender
ds country, not
local outcomevars `r(varlist)'

foreach var of local outcomevars {
	if regex("`var'", "kir") == 1 & regex("`var'", "_P") == 1  {
			drop `var'
	}

}

* tidy up the order
order par_ventile country *kfr* *kir*F* *kir_pi*M* *kir*_fi*M* 

drop *_fi_*
rename *_pi_* *_*

* save the results
save "${online_data_tables}/nonparametric", replace
export delimited "${online_data_tables}/nonparametric.csv", replace