/*

This .do file creates education transition matrices by race. 

*/

clear
set more off

* ---------------------------------------------------
* Prepare data
* ---------------------------------------------------

* Load data
use ///
	kid_pik		gender		cohort ///
	kid_race	mom_yob		dad_yob ///
	if inlist(gender,"M","F") & inrange(cohort,1978,1983) & ~mi(kid_race) ///
	using "${in}/skinny${suf}", clear
	
* Rename some variables 
rename (cohort mom_yob dad_yob) (kid_cohort mom_cohort dad_cohort)
	
* Merge on parent PIKs
	// Note that missing gender and cohorts won't match
merge 1:1 kid_pik using "${in}/spine${suf}", assert(2 3) keep(3) keepusing(mom_pik dad_pik) nogen

* Prepare education label 
label define edu ///
	0 "Not in universe" ///
	1 "No school" ///
	2 "Less than HS" ///
	3 "HS degree" ///
	4 "College no degree" ///
	5 "Associate degree" ///
	6 "Bachelor degree" ///
	7 "Graduate degree"

* Merge in education from ACS and long form for parents, mothers and fathers 
	// Note we have m:1 merges for mom and dad, because kids can share parents
foreach pers in mom dad kid {

	* ACS
	merge2 m:1 `pers'_pik using "${in}/acs${suf}", using_keys(pik) keepusing(education year) keep(1 3) nogen
	rename (education year) (`pers'_edu_acs `pers'_year_acs)
	gen byte `pers'_in_acs=~mi(`pers'_year_acs)
	
	* Remove out of universe people
	replace `pers'_edu_acs=. if `pers'_edu_acs==0
	
	* 2000 Long Form
	merge2 m:1 `pers'_pik using "${in}/2000_long${suf}", using_keys(pik) keepusing(education) keep(1 3)  
	rename education `pers'_edu_lf
	gen byte `pers'_in_lf=_merge==3
	drop _merge
	
	* Remove out of universe people
	replace `pers'_edu_lf=. if `pers'_edu_lf==0
	
	* Joint education variable, prioritizing more recent ACS
	gen `pers'_edu=`pers'_edu_acs 
	replace `pers'_edu=`pers'_edu_lf if mi(`pers'_edu_acs)
	
	label values `pers'_edu edu
	
	* Education age
	gen `pers'_edu_age=`pers'_year_acs-`pers'_cohort if ~mi(`pers'_edu_acs)
	replace `pers'_edu_age=2000-`pers'_cohort if mi(`pers'_edu_acs) & ~mi(`pers'_edu_lf)
	
	* Drop unnecessary variables
	drop *_acs *_lf
}

* Only keep rows with non-missing kid education
drop if mi(kid_edu)

* Replace with zero if below minimum age 
foreach pers in mom dad kid {
	replace `pers'_edu=. if `pers'_edu_age<25 | mi(`pers'_edu_age)
}

* For joint parent education variable, prioritize mom education
gen par_edu=mom_edu
replace par_edu=dad_edu if missing(par_edu)

* Keep only rows with non-missing kid and parent education
keep if ~mi(par_edu) & ~mi(kid_edu)

* Make educational categories 
	// Less than HS (1,2)
	// HS (3)
	// Some college/Associate degree (4,5)
	// 4yr college or more (6,7)
foreach pers in kid par {
	gen `pers'_level=.
	replace `pers'_level=1 if inlist(`pers'_edu,1,2)
	replace `pers'_level=2 if inlist(`pers'_edu,3)
	replace `pers'_level=3 if inlist(`pers'_edu,4,5)
	replace `pers'_level=4 if inlist(`pers'_edu,6,7)
	assert ~mi(`pers'_level)
}

* ---------------------------------------------------
* Collapse 
* ---------------------------------------------------

* Collapse 
collapse (count) n=kid_cohort, by(kid_race gender par_level kid_level)

*Before producing output table, assert all cells are based on at least 20 individuals
if "${suf}"=="" assert n>=20 & ~mi(n)

*Save to do by gender results
tempfile clps
save `clps'

* ---------------------------------------------------
* Results, pooled across genders  
* ---------------------------------------------------

collapse (sum) n, by(kid_race par_level kid_level)

*Total number of kids within race-gender
bys kid_race: egen n_rg=sum(n)

*Total number of kids within race / gender / parent education level
bys kid_race par_level: egen n_rg_par=sum(n)

*Share of kids within race/parent education level
gen par_share=n_rg_par/n_rg

*Share of kids within race / parent education / kid education level
gen cond_p=n/n_rg_par

* Drop variables we no longer need 
drop n n_rg_par

*Make pooled gender variable
gen gender="P"

order ///
	kid_race	gender		n_rg ///	
	par_level 	par_share	kid_level ///
	cond_p

*Reshape wide
reshape wide cond_p, i(kid_race gender n_rg par_level par_share) j(kid_level)

tempfile pooled
save `pooled'

* ---------------------------------------------------
* Results, split by gender   
* ---------------------------------------------------

use `clps', clear

*Total number of kids within race-gender
bys kid_race gender: egen n_rg=sum(n)

*Total number of kids within race / gender / parent education level
bys kid_race gender par_level: egen n_rg_par=sum(n)

*Share of kids within race/parent education level
gen par_share=n_rg_par/n_rg

*Share of kids within race / parent education / kid education level
gen cond_p=n/n_rg_par

drop n n_rg_par

order ///
	kid_race	gender		n_rg ///	
	par_level 	par_share	kid_level ///
	cond_p

*Reshape wide
reshape wide cond_p, i(kid_race gender n_rg par_level par_share) j(kid_level)

* ---------------------------------------------------
* Merge together and output     
* ---------------------------------------------------

*Append pooled rows
append using `pooled'
sort kid_race gender par_level

* Output 
save "${out}/edu_transition_matrix${suf}", replace
