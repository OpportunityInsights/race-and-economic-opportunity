/*

This .do file rearranges the data for Figure 10B. 

*/

* Load data 
use state county tract ///
	kir_white_male_p25 kir_black_male_p25 kir_white_male_n ///
	kir_black_male_n kir_white_male_p25_se  kir_black_male_p25_se ///
	using "${final}/tract_race_gender_mskd", clear

* Create gap variable 
gen kir_gap_male_p25 = (kir_white_male_p25 - kir_black_male_p25)*100
drop if missing(kir_gap_male_p25)

* Merge on poverty rates
merge 1:1 state county tract using "${ext}/tract_covars", keepusing(poor_share2000) nogen keep(match)

drop if missing(poor_share2000)

* Generate the nonpoor share
gen nonpoor_share2000 = (1-poor_share2000)*100

* Collapse into 25 bins
xtile nonpoor_share2000_20bin = poor_share2000 [w=kir_black_male_n], nq(20)
collapse (mean) nonpoor_share2000 kir_gap_male_p25 [w=kir_black_male_n], by(nonpoor_share2000_20bin)

* Create fitted line 
reg kir_gap_male_p25 nonpoor_share2000
predict kir_gap_male_p25_pred

* Export 
ds 
chopper, vars(`r(varlist)')
save "${final}/bin_kir_gap_notpoor_20bin", replace