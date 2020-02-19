/*

This .do file rearranges the data for Figure 12D. 

*/

* local varlist variables to be plotted
local varlist  kir_ewrk

* choose if gaps should be displayed for predicted values or dots
local gap predict

* local gender
local gender male 


* load data 
use state county tract kir*p25* kir*_n kid_jail*p25* kid_jail*_n  has_dad*p25* has_dad*_n kid_work*25 kid_work*n  ///
	kir_ewrk* ///
	using "${final}/tract_race_gender_mskd", clear
	
* merge covariates
preserve
	use poor_share2000 state county tract ///
		using "${ext}/tract_covars", clear
	tempfile covs
	save `covs'
restore 
merge 1:1 state county tract using `covs', nogen

* restrict to places with low poverty
keep if poor_share2000<0.1

* rescale required variables
foreach var of varlist  has_dad_black_pooled_p25 ///
	 kir_ewrk_black_*_p25 {
	qui: replace `var' = `var'*100
}

tempfile preserve_data
save `preserve_data'

local xvar has_dad_black_pooled_p25
foreach yvar in `varlist' {
	use `preserve_data', clear
	
	binscatter `yvar'_black_male_p25 `yvar'_black_female_p25 has_dad_black_pooled_p25 /// 
		[w = `yvar'_black_male_n], nq(50) reportreg /// 
		savedata("${output}/savedata") replace
	import delimited "${output}/savedata.csv", clear
		
	keep `yvar'_black_male_p25 `yvar'_black_female_p25 has_dad_black_pooled_p25
	ds 
	chopper , vars(`r(varlist)')
	save "${final}/bin_`yvar'_black_male_female_hasdad", replace
}