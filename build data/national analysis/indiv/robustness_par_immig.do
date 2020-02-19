/*

This .do file creates parametric and non-parametric rank-rank estimates 
by parent origin country. 

*/

clear
set more off

*---------------------------------------------------
* Prepare the sample of all kids
*---------------------------------------------------

* Load dataset of all relevant children
use 	kid_pik 				kid_race		gender		cohort ///
		kid_fam_inc_rank_full	kid_indv_rank_full	claim_year ///
		kid_fam_inc	kid_indv_inc ///
		if inrange(cohort, $fcoh , $lcoh ) ///
		using "${in}/skinny${suf}", clear

rename cohort kid_cohort

* Shorten variable names 
rename kid_fam_inc_rank_full kfr
rename kid_indv_rank_full kir

* Merge on Mom and Dad PIKs 
merge 1:1 kid_pik using "${in}/spine${suf}", assert(2 3) keep(3) keepusing(mom_pik dad_pik) nogen

* Generate has_mom and has_dad indicators
gen has_mom = !missing(mom_pik)
gen has_dad = !missing(dad_pik)

* Identify which parents are immigrants using this 2000 long form and the ACS
foreach pers in mom dad {
	rename `pers'_pik pik
	
	// Immigration in 2000 long form
	merge m:1 pik using "${in}/2000_long${suf}", /// 
		keepusing(year_to_us place_of_birth cohort occ) keep(1 3)
	g `pers'_match=_merge==3
	drop _merge
	rename (year_to_us place_of_birth cohort occ) (`pers'_ytu `pers'_pob `pers'_cohort `pers'_occ)
	
	// Immigration in ACS 
	merge m:1 pik using "${in}/acs${suf}", ///
		keepusing(year_to_us place_of_birth cohort occ) keep(1 3)
	replace `pers'_match = 1 if _merge == 3
	drop _merge
	replace `pers'_ytu = year_to_us if missing(`pers'_ytu) 
	replace `pers'_pob = place_of_birth if missing(`pers'_pob) & !missing(place_of_birth)
	replace `pers'_cohort = cohort if missing(`pers'_cohort) & !missing(cohort)
	replace `pers'_occ = occ if missing(`pers'_occ) & !missing(occ)
	
	// Replace year to US with missing if born in US 
	replace `pers'_ytu = . if `pers'_pob<100
	drop year_to_us place_of_birth cohort
	rename pik `pers'_pik
	
	// Add name of country of origin for ease 
	rename `pers'_pob place_of_birth
	merge m:1 place_of_birth using "${ext}/place_codes", keep(1 3) keepusing(place_name) nogen
	rename (place_of_birth place_name) (`pers'_pob `pers'_pname)
	
	// Indicator for having a parent that was surveyed
	g `pers'_samp=has_`pers'==1 & `pers'_match==1
	g `pers'_immig=~mi(`pers'_ytu) if `pers'_samp==1
	g `pers'_native=`pers'_immig==0 if `pers'_samp==1
}

*---------------------------------------------------------------------------------------
* Construct a new def of parent rank that accounts for immigrants not being in the US
*---------------------------------------------------------------------------------------
* Append together cohorts in intergen 
preserve
	clear
	forval coh = $fcoh / $lcoh {
		append using "${raw}/intergen_`coh'${suf}" ///
			, keep(kid_pik par_fam_inc_1994 par_fam_inc_1995 par_fam_inc_1998 par_fam_inc_1999 par_fam_inc_2000 ///
			dad_indv_inc_2005 dad_indv_inc_2006 par_fam_inc_2005 par_fam_inc_2006)
	}
	tempfile intergen
	save `intergen'
restore

* Merge onto the base dataset
merge 1:1 kid_pik using `intergen', assert(3) nogen

* Generate family income 
egen mean_par_fam_inc_base = rowmean(par_fam_inc_1994 par_fam_inc_1995 par_fam_inc_1998 par_fam_inc_1999 par_fam_inc_2000)
replace mean_par_fam_inc_base = . if mean_par_fam_inc_base<=0


* Generate father income in later years 
egen mean_par_fam_inc_dadonly = rowmean(dad_indv_inc_2005 dad_indv_inc_2006)
replace mean_par_fam_inc_dadonly = . if mean_par_fam_inc_dadonly<0

* Rank variables within cohort 
foreach grp in base dadonly {
	gen tmp = 1 if !missing(mean_par_fam_inc_`grp')
	bys kid_cohort: egen totcount = total(tmp)
	drop tmp
	bys kid_cohort: egen par_rank_`grp' = rank(mean_par_fam_inc_`grp')
	replace par_rank_`grp' = par_rank_`grp'/totcount
	drop totcount
}

* Drop people with missing gender 
drop if gender == "0"

* save this file to be able to construct a crosswalk of incomes
tempfile incs
save `incs'

* clean out unnecessary variables
drop *par_fam_inc* dad_indv*

*-----------------------------------------------------------------
* Run the rank rank by country
*-----------------------------------------------------------------

* Expand to get pooled gender
expand 2, gen(dup)
replace gender = "P" if dup == 1
drop dup

* Construct variables to indicate the country (prioritize dad if both immigrant)
gen country = ""
replace country = mom_pname if mom_immig == 1 & dad_immig == 0
replace country = dad_pname if dad_immig == 1
replace country = "USA" if (mom_immig == 0 & (dad_immig == 0 | dad_immig == .)) ///
	| (dad_immig == 0 & (mom_immig ==0 | mom_immig == .)) // people we know are from the US from the long form
replace country = "Unknown" if missing(mom_immig) & missing(dad_immig) //people who aren't in the ACS or long form - we don't know where from

* Tidy up the country names to make sure groups are clear
replace country = "SOUTH KOREA" if country == "KOREA"
replace country = "UNITED KINGDOM" if inlist(country, "ENGLAND", "SCOTLAND", "NORTHERN IRELAND", "WALES")

* Restrict to only second generation immigrants (can't have parents arrive after the child was born)
replace country = "First Gen" if dad_immig == 1 & dad_ytu >= kid_cohort
replace country = "First Gen" if mom_immig == 1 & mom_ytu >= kid_cohort

tempfile base
save `base'

* for each of the set of parent ranks, run the regressions using regressby
* also do separately for kfr and kir
foreach grp in base dadonly {
	foreach var in kfr kir {
		use `base', clear
	
		* how many people are missing country?
		count if missing(country)
		noi di "`r(N)' are missing country"
		drop if missing(country)
		
		drop if missing(`var') | missing(par_rank_`grp')
		
		* for regressby to work, need at least 4 people per bygroup
		bys gender country: gen num_kids = _N
		drop if num_kids<4
		drop num_kids
		
		count
		if `r(N)'>=4 {
			* run regressby
			regressby4 `var' par_rank_`grp', robust by(country gender)
			
			* tidy up the output
			rename (_b_par_rank_`grp' _b_cons _se_par_rank_`grp' _se_cons   _cov_cons_par_rank_`grp') ///
				(slope icept slope_se icept_se cov)
				
			* add identifiers for the spec
			gen outcome = "`var'"
			gen par_rank = "`grp'"
			
			order outcome par_rank country gender, first
			
			* save the results
			tempfile `grp'_`var'
			save ``grp'_`var''
		}
	}
}

clear
foreach grp in base dadonly {
	foreach var in kfr kir {
		cap confirm file ``grp'_`var''
		if _rc==0 {
			append using ``grp'_`var''
		}
	}
}

tempfile reg_results
save `reg_results'

*----------------------------------------------------------------------------
* Get mean kid age at arrival and age in 2015
*----------------------------------------------------------------------------

* Can be an issue to measure parent income at different times
	// relative to arrival (since using 1994-2000 fixed). Calculate child age
	// at time of parent arrival

use `base', clear

* restrict to the set of people who aren't missing base line parent rank
drop if missing(par_rank_base)

* generate age at arrival for each parent's arrival
gen kid_age_mom = mom_ytu - kid_cohort
gen kid_age_dad = dad_ytu - kid_cohort

* generate age in 2015 for each group
gen age_mom = 2015 - mom_cohort
gen age_dad = 2015 - dad_cohort
gen age_kid = 2015 - kid_cohort

* collapse down by country gender
gcollapse (mean) kid_age_mom kid_age_dad age_mom age_dad age_kid, by(country gender)

tempfile collapse_country_gender
save `collapse_country_gender'

use `reg_results', clear
merge m:1 country gender using `collapse_country_gender', nogen keep(1 3) //places with fewer than 4 in the group won't match


* Restrict to the specs we want
*------------------------------
* pooled pooled with baseline, then sons/daughters indiv inc baseline and then sons with dad
keep if (gender == "P" & outcome == "kfr" & par_rank == "base") | ///
	(gender == "M" & outcome == "kir") | ///
	(gender == "F" & par_rank == "base" & outcome == "kir")
	
* keep only if there are 500 kids per country
keep if N>=500

* and then only if we can release all 4 stats for each country
bys country: gen num = _N
keep if num == 4
drop num

* remove countries that are aggregations
drop if country == "First Gen" | country == "Unknown"

* construct p25 & p75
foreach p in 25 75 {
	gen p`p' = icept + slope * (`p'/100)
	gen p`p'_se = sqrt(icept_se^2 + slope_se^2*(`p'/100)^2 + 2*cov*(`p'/100))
}

keep outcome par_rank country gender p* kid_age_m kid_age_dad age_mom age_dad age_kid N

save "${out}/robustness_immig_par", replace

*-----------------------------------------------------------------------------
* Also produce non-parametric results 
*-----------------------------------------------------------------------------

* have to loop over the income definitions
foreach grp in base dadonly {
	foreach var in kir kfr {
		use `base', clear
		
		count if missing(country)
		noi di "`r(N)' missing country"
		drop if missing(country)
		
		* generate par income ventile
		gen par_ventile = ceil(par_rank_`grp'*20)
		
		
		* collapse down by the par pctiles
		gen count = 1 if !missing(par_ventile) & !missing(`var')
		
		collapse (mean) `var'_`grp'=`var' (rawsum) count_`grp' = count , by(par_ventile country gender)
		
		tempfile nonpar_`grp'_`var'
		save `nonpar_`grp'_`var''
	}
}

* merge these together
use `nonpar_base_kfr', clear
merge 1:1 par_ventile country gender using `nonpar_base_kir', nogen
merge 1:1 par_ventile country gender using `nonpar_dadonly_kfr', nogen
merge 1:1 par_ventile country gender using `nonpar_dadonly_kir', nogen

* reshape this long
reshape long kfr_ kir_ count_, i(gender country par_ventile) j(par_rank) string
rename (kfr_ kir_) (mean_kfr mean_kir)
reshape long mean_, i(gender country par_ventile par_rank) j(outcome) string
rename mean_ mean
rename count_ N

* Restrict to the specs we want
*------------------------------
* keep only the demographic groups we want
* pooled pooled with baseline, then sons/daughters indiv inc baseline and then sons with dad
keep if (gender == "P" & outcome == "kfr" & par_rank == "base") | ///
	(gender == "M" & outcome == "kir") | ///
	(gender == "F" & par_rank == "base" & outcome == "kir")
	
* drop places that are missing the mean in a given par_ventile (weren't missing it for one spec when wide)
drop if missing(mean)

* only want places with 20 people in each bin
drop if missing(par_ventile)
bys country gender par_rank outcome: egen mincount = min(N)	
drop if mincount<20
drop mincount

* only keep places where we have 20 ventiles
bys country gender par_rank outcome: keep if _N==20 | (_N==16 & par_rank == "dadonly")

* only keep if we can release all 4 specs for the country
bys country par_ventile: gen num = _N
keep if (num == 4 & !inlist(par_ventile, 1, 2, 4, 5)) | ( num == 3 & inlist(par_ventile, 1, 2, 4, 5))
drop num

* remove countries that are aggregations
drop if country == "First Gen" | country == "Unknown"

* remove countries that are actually continents
drop if country == "ASIA"

* export results 
save "${out}/robustness_immig_nonpar", replace

*----------------------------------------------------------------------------
* Construct the income ventile to dollar amount crosswalks
*----------------------------------------------------------------------------
* initialize the ventile crosswalk
clear
set obs 20
gen ventile = _n
gen gender = "P"

tempfile vents
save `vents'

foreach def in kir kfr base dadonly {
	if "`def'"=="kir" {
		local incvar kid_indv_inc
		local rankvar kir
	}
	else if "`def'"=="kfr" {
		local incvar kid_fam_inc
		local rankvar kfr
	}
	else {
		local incvar mean_par_fam_inc_`def'
		local rankvar par_rank_`def'
	}
	use `incs', clear
	
	* only want the crosswalk for pooled gender since that's how they are ranked
	replace gender = "P"
	
	
	drop if missing(`incvar') | missing(`rankvar')
	gen ventile = ceil(`rankvar'*20)
	gen count = 1
	collapse (mean) `def' = `incvar' (rawsum) `def'_count = count, by(ventile gender)
	
	tempfile clps_`def'
	save `clps_`def''
}

use `vents', clear
foreach def in kir kfr base dadonly {
	merge 1:1 ventile gender using `clps_`def'', nogen assert(1 3)
}

* export 
save "${out}/robustness_immig_income_vent_cw", replace
