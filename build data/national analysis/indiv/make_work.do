/*

This .do file creates the main work dataset used for the national analysis. 

*/

clear 
set more off

*------------------------------------------------------------------------------
* Make lists of variables to pull from each data set
*------------------------------------------------------------------------------

*Output variables
global xyvars ///
	kid_dead			kfr					kir ///
	kfi					kii					kid_working ///
	mom_teen			has_mom				has_dad ///
	two_par				kid_teenbirth		par_inc ///
	kir_inrace			kfr_inrace			par_rank_inrace ///
	par_edu				kid_edu				kid_somecoll ///
	kid_hs				kid_jail 			dad_jail ///
	kid_occ				kid_hours			kid_pos_hours ///
	kid_wage			kid_wage_rank		mom_native ///
	par_homeowner		par_mortgage		par_homevalue ///
	par_vehicles 		par_rich			two_par_census ///
	kir_2par 			kir_2par25			kir_1par ///
	kir_somecoll 		kir_native 			kfr_native ///
	kid_married 		kir_par_nohome 		kir_working ///
	kir_everwork		spouse_rank			dad_native ///
	dad_hs				dad_somecoll		mom_hs ///
	mom_somecoll		kir_everwork_1par	kir_everwork_2par ///
	kir_dad				kir_nodad			kir_everwork_dad ///
	kir_everwork_nodad	mom_rank			dad_rank ///
	kid_wageflex		kid_wageflex_rank	kid_weeks_worked ///
	kid_hours_yr

*Store list of variables to read 
local pull_vars ///
	kid_pik			gender			cohort ///
	kid_race		mom_yob			dad_yob ///
	kid_married 	par_married 	par_state ///
	par_county  	par_tract 		par_block ///
	kid_state 		kid_county		kid_tract ///
	death_year 		kid_teenbirth 	kid_working ///
	kir_working		mom_inc			dad_inc
	
*Variables to pull from the raw data for inflation adjustment  
local inc_vars ///
	kid_pik				cohort				par_rank_n ///
	par_fam_inc_1994	par_fam_inc_1995	par_fam_inc_1998 ///
	par_fam_inc_1999	par_fam_inc_2000 	par_fam_inc_1994_2000
	
*Raw census variable names
local short2010 ///
	incarcerated 
	
local short2000 ///
	incarcerated		homeowner		child_2_parent 
	
local long2000 ///
	education 		year_to_us		homeowner ///
	outrightowner	homevalue		mortgage ///
	vehicles		move_year
	
local acs ///
	education 		year_to_us		homeowner ///
	outrightowner	homevalue		mortgage ///
	vehicles		move_year		hours_worked ///
	tot_inc			labor_inc		occ ///
	weeks_worked	year
	
*Shortened census variables names 
local short2010_clean ///
	jail10
	
local short2000_clean ///
	jail00			home00			two_pars00
	
local long2000_clean ///
	edu_lf			ytu_lf			ho_lf ///
	outho_lf		hval_lf			mrtg_lf ///
	veh_lf			my_lf
	
local acs_clean ///
	edu_acs			ytu_acs			ho_acs ///
	outho_acs		hval_acs		mrtg_acs ///
	veh_acs			my_acs			hw_acs ///
	ti_acs			li_acs			occ_acs ///
	wkw_acs			year_acs
	
*------------------------------------------------------------------------------
* Correct for inflation-adjusted incomes
*------------------------------------------------------------------------------
	
* Build main parent and kid incomes to account for inflation adjustment
g kfi_2015=.
g kfi_2014=.
g kii_2015=.
g kii_2014=.
quietly forvalues i=$fcohort/$lcohort {
	noi di "Appending `i' Cohort"
	append using "${raw}/intergen_`i'${suf}", ///
		keep(`inc_vars' kid_fam_inc_`=2015-`i'' kid_fam_inc_`=2014-`i'' ///
				kid_indv_inc_`=2015-`i'' kid_indv_inc_`=2014-`i'')
	replace kfi_2015=kid_fam_inc_`=2015-`i'' if cohort==`i'
	replace kfi_2014=kid_fam_inc_`=2014-`i'' if cohort==`i'
	replace kii_2015=kid_indv_inc_`=2015-`i'' if cohort==`i'
	replace kii_2014=kid_indv_inc_`=2014-`i'' if cohort==`i'
}
drop kid_fam* kid_indv*

* Fix parent incomes
foreach y in 1994 1995 1998 1999 2000 {
	g yr=`y'
	g new_par_`y'=par_fam_inc_`y'
	inflate, var(new_par_`y') yearvar(yr)
	drop yr
	assert ~mi(new_par_`y') & ~mi(par_fam_inc_`y')
}

* Generate new parent income
egen new_par_inc=rowmean(new_par_*)

* Fix kid incomes
foreach y in 2014 2015 {
	foreach i in kfi kii {
		g yr=`y'
		g new_`i'_`y'=`i'_`y'
		inflate, var(new_`i'_`y') yearvar(yr)
		drop yr
		assert ~mi(new_`i'_`y') & ~mi(`i'_`y')
	}
}

* Drop kids with negative or 0 parent income
count if new_par_inc<=0
di "`r(N)' kids dropped from negative real parent income"
drop if new_par_inc<=0

* Keep only new variables and old parent rank
keep kid_pik cohort new_par_inc new_kfi_2014 new_kii_2014 new_kfi_2015 new_kii_2015
rename new_* *

* New kid incomes 
assert ~mi(kii_2015) & ~mi(kii_2014) & ~mi(kfi_2015) & ~mi(kfi_2014)
egen kii=rowmean(kii_*)
egen kfi=rowmean(kfi_*)
assert ~mi(kii) & ~mi(kfi)

* Rank incomes 
egen tot=count(par_inc), by(cohort)
foreach i in kfi kii par_inc {
	egen `i'_rank=rank(`i'), by(cohort)
	replace `i'_rank=`i'_rank/tot
}
drop tot

* Clean and output
rename (par_inc_rank kfi_rank kii_rank) (par_rank kfr kir)
keep kid_pik par_rank par_inc kfr kir kii kfi
tempfile inc
save `inc'

*------------------------------------------------------------------------------
* Initial pull
*------------------------------------------------------------------------------

* Pull variables from the data reading in restricted cohorts and those with 
		// non-missing genders
use `pull_vars' if cohort>=${fcohort} & cohort<=${lcohort} & ///
	(gender=="M"|gender=="F") ///
	using "${in}/skinny${suf}", clear
	
*------------------------------------------------------------------------------
* Generate useful variables from the tax records
*------------------------------------------------------------------------------

*Merge on income ranks 
	// Keep only those who match (the non-matchers will be negative real par-inc kids)
merge 1:1 kid_pik using `inc', keep(3) nogen

*Indicator for parents having above median income
g par_rich=par_rank>=.5

*Indicator for having died 
g kid_dead=~mi(death_year)
drop death_year

* Set teenbirth to missing for the 1978 cohort (not enough years of dependents data)
replace kid_teenbirth=. if cohort<1979

* Merge on mom and dad pik
merge 1:1 kid_pik using "${in}/spine${suf}", ///
	keepusing(mom_pik dad_pik) assert(2 3) keep(3) nogen
	
* Indicator for ever working in 2014 and 2015
g kir_everwork=kii!=0
	
* Define parental variables
g has_mom=~mi(mom_pik)
g has_dad=~mi(dad_pik)
g mom_teen=(cohort-mom_yob)<20 if ~mi(mom_yob)
g two_par=has_mom==1 & has_dad==1

* Make a variable for spouse income
g spouse_inc=kfi-kii

*Generate parent individual income ranks
	// No need to inflation adjust as we are only using 2005 data
assert ~mi(mom_inc) & ~mi(dad_inc)
egen tot=count(mom_inc), by(cohort)
foreach p in mom dad {
	egen `p'_rank=rank(`p'_inc), by(cohort)
	replace `p'_rank=`p'_rank/tot
}
drop tot mom_inc dad_inc

* Generate spouseal earnings ranks
egen tot=count(spouse_inc), by(cohort)
egen spouse_rank=rank(spouse_inc), by(cohort)
replace spouse_rank=spouse_rank/tot
drop tot

* Generate within-race income ranks
egen tot=count(kfi), by(cohort kid_race)
egen kir_inrace=rank(kii), by(cohort kid_race)
egen kfr_inrace=rank(kfi), by(cohort kid_race)
egen par_rank_inrace=rank(par_inc), by(cohort kid_race)
foreach inc in kir kfr par_rank {
	replace `inc'_inrace=`inc'_inrace/tot
}
drop tot

*------------------------------------------------------------------------------
* Pull census data
*------------------------------------------------------------------------------

*Thees merges are m:1 because of the parents with multiple kids in the sample
foreach pers in mom dad kid {

	* 2010 Census
	merge2 m:1 `pers'_pik using "${in}/2010_short${suf}", using_keys(pik) keepusing(`short2010') keep(1 3) nogen
	rename	(`short2010') (`short2010_clean')

	* 2000 Census
	merge2 m:1 `pers'_pik using "${in}/2000_short${suf}", using_keys(pik) keepusing(`short2000') keep(1 3) nogen 
	rename (`short2000') (`short2000_clean')
	
	* ACS
	merge2 m:1 `pers'_pik using "${in}/acs${suf}", using_keys(pik) keepusing(`acs') keep(1 3) nogen
	rename (`acs') (`acs_clean')
	g byte `pers'_in_acs=~mi(year_acs)
	
	* 2000 Long Form
	merge2 m:1 `pers'_pik using "${in}/2000_long${suf}", using_keys(pik) keepusing(`long2000') keep(1 3)  
	rename (`long2000') (`long2000_clean')
	g byte `pers'_in_lf=_merge==3
	drop _merge
	
	* Inflation adjust the ACS variables
	foreach v in hval_acs mrtg_acs ti_acs li_acs {
		inflate, var(`v') yearvar(year_acs)
	}
	
	* Inflation adjust the long form incomes
	g year_lf=2000 if `pers'_in_lf==1
	foreach v in hval_lf mrtg_lf {
		inflate, var(`v') yearvar(year_lf)
	}
	drop year_lf
	
	* Give all variables person-specific names
	foreach v in `short2010_clean' `short2000_clean' `acs_clean' `long2000_clean' {
		rename `v' `pers'_`v'
	}	
	
	* Make joint education variable - prioritize ACS to capture as old as possible
	g `pers'_edu=`pers'_edu_acs 
	replace `pers'_edu=`pers'_edu_lf if mi(`pers'_edu_acs)
	g `pers'_somecoll=`pers'_edu>=4 if ~mi(`pers'_edu)
	g `pers'_hs=`pers'_edu>=3 if ~mi(`pers'_edu)	
	
	* Define age of education measurement for kids
		// Set education vars to missing if appropriate
	if "`pers'"=="kid" {
		g edu_age=kid_year_acs-cohort if ~mi(kid_edu_acs)
		replace edu_age=2000-cohort if mi(kid_edu_acs) & ~mi(kid_edu_lf)
		
		// Must be 19 to measure high school
		replace kid_hs=. if edu_age<19
		
		* Must be 20 to measure college 
		replace kid_somecoll=. if edu_age<20
		replace kid_edu=. if edu_age<20
		drop edu_age
	}
	
	drop `pers'_edu_acs `pers'_edu_lf 
	label values `pers'_edu edu
	
	* Make joint wealth proxy variables - prioritize long form
	destring `pers'_veh_acs, replace force
	foreach v in ho mrtg hval veh {
		g `pers'_`v'=`pers'_`v'_lf if `pers'_in_lf==1
		replace `pers'_`v'=`pers'_`v'_acs if `pers'_in_lf==0 & `pers'_in_acs==1
		replace `pers'_`v'=0 if mi(`pers'_`v') & (`pers'_in_lf==1 | `pers'_in_acs==1)
		drop `pers'_`v'_lf `pers'_`v'_acs
		
	}
	
	* Make a joint native variable
	g `pers'_native_acs=mi(`pers'_ytu_acs) if `pers'_in_acs==1
	g `pers'_native_lf=mi(`pers'_ytu_lf) if `pers'_in_lf==1
	g `pers'_native=`pers'_native_lf if `pers'_in_lf==1
	replace `pers'_native=`pers'_native_acs if `pers'_in_lf==0 & `pers'_in_acs==1
	drop `pers'_native_acs `pers'_native_lf `pers'_ytu_acs `pers'_ytu_lf
		
}

* Drop variables that we don't use
drop ///
	mom_jail10		mom_two_pars00	mom_jail00 ///
	mom_hw_acs		mom_ti_acs		mom_li_acs ///
	mom_occ_acs		dad_jail10		dad_two_pars00 ///
	dad_home00		dad_year_acs	dad_hw_acs ///
	dad_ti_acs		dad_li_acs 		dad_occ_acs ///
	dad_my_acs 		kid_jail00 		kid_home00 ///
	kid_my_acs		kid_my_lf		dad_wkw_acs /// 
	mom_wkw_acs


*------------------------------------------------------------------------------
* Clean census variables
*------------------------------------------------------------------------------

* Incarceration variables
rename (kid_jail10 dad_jail00) (kid_jail dad_jail)

* Child having two parents in the 2000 census
g two_par_census=kid_two_pars00==1 if ~mi(kid_two_pars00)

* Generate an indicator for being in the ACS at ages 30 and older
	// Note that all people >=15 years old in ACS have non missing labor income
g in_acs=~mi(kid_year_acs) & ((kid_year_acs-cohort)>=30) & ~mi(kid_li_acs)

* Generate hours variable
g kid_hours = kid_hw_acs if in_acs==1
replace kid_hours = 0 if mi(kid_hours) & in_acs==1
drop kid_hw_acs

* Working
	// Note those with 0 hours have 0 labor income
g kid_pos_hours=kid_hours>0 if in_acs==1

	// Labor income
g kid_labor_inc = kid_li_acs if in_acs==1

	// Occupation
g kid_occ = kid_occ_acs if in_acs==1

* Wages 
	// Note this will be missing for those with 0 hours
g kid_wage = kid_labor_inc/(kid_hours*50) if in_acs==1

* Set kid weeks worked to 0 if missing 
	// All people with missing weeks worked have hours of 0
replace kid_wkw_acs=0 if mi(kid_wkw_acs) & in_acs==1

* Generate a variable for annual hours worked per week
g kid_hours_yr=(kid_hours*kid_wkw_acs)/51

* Generate a second wage variable that uses the weeks worked variable instead of 50
g kid_wageflex = kid_labor_inc/(kid_hours*kid_wkw_acs) if in_acs==1

* Wage ranks
egen tot=count(kid_wage), by(cohort kid_year_acs)	
foreach i in wage wageflex {
	egen kid_`i'_rank=rank(kid_`i'), by(cohort kid_year_acs)
	replace kid_`i'_rank=kid_`i'_rank/tot
}
drop tot 
rename kid_wkw_acs kid_weeks_worked

* Make combined parent wealth and education variables
foreach v in ho mrtg hval veh edu {
	g par_`v'=mom_`v'
	replace par_`v'=dad_`v' if mi(par_`v')
	drop mom_`v' dad_`v'
}
rename (par_ho par_mrtg par_hval par_veh) ///
	(par_homeowner par_mortgage par_homevalue par_vehicles)
	
* Topcode number of cars at 5
replace par_vehicles=5 if par_vehicles>5 & ~mi(par_vehicles)

* Individual income ranks for kids in various samples
g kir_2par=kir if two_par==1
g kir_1par=kir if two_par==0
g kir_2par25=kir_2par if ((cohort-mom_yob)>=25)
g kir_somecoll=kir if kid_somecoll==1
g kir_native=kir if mom_native==1
g kfr_native=kfr if mom_native==1
g kir_par_nohome=kir if par_homeowner==0 
g kir_everwork_1par=kir_everwork if two_par==0
g kir_everwork_2par=kir_everwork if two_par==1
g kir_dad=kir if has_dad==1
g kir_nodad=kir if has_dad==0
g kir_everwork_dad=kir_everwork if has_dad==1
g kir_everwork_nodad=kir_everwork if has_dad==0

*------------------------------------------------------------------------------
* Output work data
*------------------------------------------------------------------------------

* Set by variables to -9 when missing 
foreach var of global setmiss {
	replace `var'=-9 if mi(`var')
}

keep ///
	kid_pik			gender			cohort ///
	kid_race		par_rank		par_married ///
	par_state 		par_county  		par_tract ///
	par_block 		kid_state 		kid_county ///
	kid_tract 		${xyvars} 	
	
order ///
	kid_pik			gender			cohort ///
	kid_race		par_rank		par_married ///
	par_state 		par_county  		par_tract ///
	par_block 		kid_state 		kid_county ///
	kid_tract 		${xyvars} 		 		 		
	
compress

* Output full file
preserve
label data "Cross sectional race work file"
save "${work}/race_work", replace
restore

* Output 1978-1983 cohort version
preserve
keep if inrange(cohort,1978,1983)
save "${work}/race_work_78_83", replace

*------------------------------------------------------------------------------
* Merge to the long file for exposure weighted estimates (only 78_83 cohort)
*------------------------------------------------------------------------------

* Make a temp file of the needed long variables
use ///
	kid_pik			cohort 			year ///
	par_cz			par_state		par_county ///
	par_tract 		gender ///
	if (year-cohort)<=23 & (year-cohort)>=0 & (gender=="M"|gender=="F") & cohort<=1983 ///
	using "${in}/long${suf}", clear

* Set by variables to -9 when missing 
foreach var in par_state par_county par_tract par_cz {
	replace `var'=-9 if mi(`var')
}

drop cohort gender

* Merge to the skinny file
merge m:1 kid_pik using "${work}/race_work_78_83", nogen assert(1 3) keep(3) ///
	keepusing( ///
	gender			cohort 			kid_race ///		
	par_rank		par_married 	kid_state ///
	kid_county 		kid_tract 		${xyvars})

* Output 1978-1983 cohort long file
label data "Long race work file"
save "${work}/race_work_long_78_83", replace
