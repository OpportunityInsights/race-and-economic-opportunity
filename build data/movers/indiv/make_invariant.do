/*

This .do file builds a dataset with one row per child for our cohorts of interest 

*/

* Load in skinny file (drop individuals with missing gender)
use ///
	kid_pik	 		cohort 				par_rank_full ///
	kid_race 		gender 				kid_indv_rank_full_24 ///
 	kid_indv_rank_full_30	kid_fam_inc_rank_full_24 	kid_married_30 ///
	kid_indv_inc_24 	kid_indv_inc_30			kid_fam_inc_24 ///
	par_inc ///
	if (gender=="M"|gender=="F") & inrange(cohort, ${fcohort}, ${lcohort}) ///
	using "${in}/skinny${suf}", clear

* Missing kid_race
replace kid_race=-9 if mi(kid_race)
tab kid_race, m

* Rename full sample parent rank variable
rename par_rank_full par_rank

* Rename the income rank variables 
foreach age in 24 30 {

	*Individual income not well defined prior to 2005
	assert mi(kid_indv_inc_`age') if cohort+`age'<2005
	assert mi(kid_indv_rank_full_`age') if cohort+`age'<2005
	rename kid_indv_rank_full_`age' kir_`age'
	rename kid_indv_inc_`age' kii_`age'
}

* Rename family income variables
rename (kid_fam_inc_24 kid_fam_inc_rank_full_24) (kfi_24 kfr_24)

* Merge on 2010 incarceration
merge2 1:1 kid_pik using "${in}/2010_short${suf}", using_keys(pik) keepusing(incarcerated) keep(1 3) nogen
rename incarcerated kid_jail

* Save
compress
save "${out}/movers_invariant", replace