/*

This .do file rearranges data for graphing in Figure 12A-C. 

*/

* ---------------------
* Setting up 
* ---------------------

* local varlist variables to be plotted
local varlist kir kir_ewrk kid_jail

* choose if gaps should be displayed for predicted values or dots
local gap predict

* local gender
local gender male 

* ---------------------
* Creating tract-level data 
* ---------------------

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
foreach var in kir_white_`gender'_p25 kir_black_`gender'_p25 has_dad_black_pooled_p25 ///
	kir_work_white_`gender'_p25 kir_work_black_`gender'_p25 kid_jail_white_`gender'_p25 ///
	kid_jail_black_`gender'_p25 kir_ewrk_black_`gender'_p25 kir_ewrk_white_`gender'_p25 {
	qui: replace `var' = `var'*100
}

tempfile preserve_data
save `preserve_data'

* ---------------------
* Binscatter data
* ---------------------

foreach yvar in `varlist' {
	use `preserve_data', clear
			
	binscatter `yvar'_white_`gender'_p25 `yvar'_black_`gender'_p25 has_dad_black_pooled_p25 /// 
		[w = `yvar'_black_`gender'_n], nq(50) reportreg /// 
		savedata("${final}/savedata") replace
	import delimited "${final}/savedata.csv", clear
	
	keep `yvar'_white_`gender'_p25 `yvar'_black_`gender'_p25 has_dad_black_pooled_p25 yax* xax*
	ds 
	chopper , vars(`r(varlist)')
	save "${final}/bin_`yvar'_hasdad", replace
}