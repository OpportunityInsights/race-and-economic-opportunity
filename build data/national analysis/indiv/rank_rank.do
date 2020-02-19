/*

This .do file produces rank-rank slopes by cohort. 

*/

set more off

* Use the full data to go up to the 1988 cohort
use ///
	kid_pik			kid_race 		par_rank ///
	kfr 			cohort ///
	if cohort<=1988 ///
	using "${work}/race_work", clear
	
* Run regressions
regressby3 kfr par_rank , by(kid_race cohort)

* Output
compress
save "${out}/rank_rank_cohort", replace