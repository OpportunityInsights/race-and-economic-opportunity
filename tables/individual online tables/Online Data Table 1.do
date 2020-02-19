/*

This .do file creates Online Data Table 1: National Statistics by Parent Income 
Percentile, Gender and Race. 

*/


* ----------------------------
* SET-UP 
* ----------------------------
* local races and local to label all races 
local races asian black hisp aian white 
local races_label Asian Black Hispanic "American Indian&Alaska Natives" White 

* local genders and local to label all genders 
local genders male female
local genders_label Males Females

* ----------------------------
* PREP DATA 
* ----------------------------
* kfr rank rank
use "${final}/bin_kfr_par_rank", clear

foreach var of varlist kfr* {
	rename `var' `var'_pooled
}

renvars _all, subst(native_american aian)
renvars _all, subst(hispanic hisp)

label var par_pctile "Parent Household Income Rank"

local i=1 
foreach race in `races' {
	cap confirm var kfr_`race'_pooled 
	if !_rc {
		local label : word `i' of `races_label'
		label var kfr_`race'_pooled "`label': Household Income Rank" 
		}
	local ++i
	}

tempfile kfr_par_rank
save `kfr_par_rank'


* kfr for kids w/ native mothers
use "${final}/bin_kfr_native_par_rank", clear

renvars _all, subst(native_american aian)
renvars _all, subst(hispanic hisp)

foreach var of varlist kfr* {
	rename `var' `var'_pooled
}

renvars _all, subst(_native_ _nativemom_)

local i=1 
foreach race in `races' {
	cap confirm var kfr_nativemom_`race'_pooled 
	if !_rc {
		local label : word `i' of `races_label'
		label var kfr_nativemom_`race'_pooled "`label' with Native Moms: Household Income Rank" 
		}
	local ++i
	}

tempfile kfr_native_par_rank
save `kfr_native_par_rank'

*kfr by gender
use "${final}/bin_kfr_par_rank_F", clear

rename kfr kfr_
reshape wide kfr, i(par_pctile gender) j(kid_race)

rename kfr_1 kfr_white_
rename kfr_2 kfr_black_

reshape wide kfr*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kfr_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kfr_`race'_`gender' "`label' `gender_label': Household Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kfr_gender
save `kfr_gender'

* kfr pooled, nonmissing race
use "${final}/bin_kfr_par_rank_pooled_notmissingrace", clear
label var kfr_pooled "All Children: Household Income Rank"

tempfile kfr_pooled
save `kfr_pooled'

* hours worked by gender (yearly avg)
use "${final}/bin_kid_hours_yr_par_rank_F", clear

rename kid_hours_yr kid_hours_
reshape wide kid_hours, i(par_pctile gender) j(kid_race)

rename kid_hours_1 kid_hours_white_
rename kid_hours_2 kid_hours_black_

reshape wide kid_hours*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_hours_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_hours_`race'_`gender' "`label' `gender_label': Hours of Work" 
			}
		local ++u 	
		}	
	local ++i
}

tempfile kid_hours_gender
save `kid_hours_gender'

*marriage rates
use "${final}/bin_kid_married_par_rank_bw", clear

rename kid_married* kid_married*_pooled

local i=1 
foreach race in `races' {
	cap confirm var kid_married_`race'_pooled 
	if !_rc {
		local label : word `i' of `races_label'
		label var kid_married_`race'_pooled "`label': Marriage Rate" 
		}
	local ++i
	}

tempfile kid_married
save `kid_married'

*kid no hs
use "${final}/bin_kid_no_hs_par_rank_F", clear

rename kid_no_hs kid_no_hs_
reshape wide kid_no_hs, i(par_pctile gender) j(kid_race)

rename kid_no_hs_1 kid_no_hs_white_
rename kid_no_hs_2 kid_no_hs_black_

reshape wide kid_no_hs*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_no_hs_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_no_hs_`race'_`gender' "`label' `gender_label': Percentage w/o High School Degree" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_no_hs
save `kid_no_hs'

*Kid employed (i.e. works a positive number of hours)
	// contains data for both genders! 
use "${final}/bin_kid_pos_hours_par_rank_F", clear

rename kid_pos_hours kid_pos_hours_
reshape wide kid_pos_hours, i(par_pctile gender) j(kid_race)

rename kid_pos_hours_1 kid_pos_hours_white_
rename kid_pos_hours_2 kid_pos_hours_black_

reshape wide kid_pos_hours*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_pos_hours_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_pos_hours_`race'_`gender' "`label' `gender_label': Percentage Positive Working Hours" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_pos_hours
save `kid_pos_hours'


*Kid Some College
	// contains data for both genders! 
use "${data}/bin_kid_somecoll_par_rank_F", clear

rename kid_somecoll kid_somecoll_
reshape wide kid_somecoll, i(par_pctile gender) j(kid_race)

rename kid_somecoll_1 kid_somecoll_white_
rename kid_somecoll_2 kid_somecoll_black_

reshape wide kid_somecoll*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)
renvars _all, subst(somecoll college)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_college_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_college_`race'_`gender' "`label' `gender_label': College Attendance Rates" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_college
save `kid_college'


*Kid Wage Rank 
	// contains data for both genders! 
use "${final}/bin_kid_wageflex_rank_par_rank_F", clear

ren kid_wageflex_rank kid_wage_rank
reshape wide kid_wage_rank, i(par_pctile gender) j(kid_race)

rename kid_wage_rank1 kid_wage_rank_white_
rename kid_wage_rank2 kid_wage_rank_black_

reshape wide kid_wage_rank*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_wage_rank_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_wage_rank_`race'_`gender' "`label' `gender_label': Wage Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_wage_rank
save `kid_wage_rank'

*KIR one Parent (males)
use "${final}/bin_kir_1par_par_rank_M", clear

drop pline*

reshape wide kir*, i(par_pctile) j(kid_race)

rename kir_1par1 kir_1par_white_male
rename kir_1par2 kir_1par_black_male

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kir_1par_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kir_1par_`race'_`gender' "`label' `gender_label' w/ Single-Parent: Individual Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kir_1par
save `kir_1par'


*KIR two Parent (males)
use "${final}/bin_kir_2par_par_rank_M", clear

drop pline*

reshape wide kir*, i(par_pctile) j(kid_race)

rename kir_2par1 kir_2par_white_male
rename kir_2par2 kir_2par_black_male

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kir_2par_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kir_2par_`race'_`gender' "`label' `gender_label' w/ Two-Parent HH: Individual Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kir_2par
save `kir_2par'


*KIR males no home
use "${final}/bin_kir_par_nohome_par_rank_M", clear

drop pline*

reshape wide kir*, i(par_pctile) j(kid_race)

rename kir_par_nohome1 kir_par_nohome_white_male
rename kir_par_nohome2 kir_par_nohome_black_male

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kir_par_nohome_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kir_par_nohome_`race'_`gender' "`label' `gender_label' w/ Parent who do not own Home: Individual Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kir_par_nohome
save `kir_par_nohome'


*KIR pooled gender
use "${final}/bin_kir_par_rank_bw", clear

rename kir* kir*_pooled

local i=1 
foreach race in `races' {
	cap confirm var kir_`race'_pooled 
	if !_rc {
		local label : word `i' of `races_label'
		label var kir_`race'_pooled "`label': Individual Income Rank" 
		}
	local ++i
	}

tempfile kir_pooled
save `kir_pooled'


*KIR by female
use "${final}/bin_kir_par_rank_F", clear

reshape wide kir*, i(par_pctile) j(kid_race)

rename kir1 kir_white_female
rename kir2 kir_black_female

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kir_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kir_`race'_`gender' "`label' `gender_label': Individual Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kir_female
save `kir_female'


*KIR by male
use "${final}/bin_kir_par_rank_M", clear

reshape wide kir*, i(par_pctile) j(kid_race)

rename kir1 kir_white_male
rename kir2 kir_black_male

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kir_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kir_`race'_`gender' "`label' `gender_label': Individual Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kir_male
save `kir_male'

*Spouse Rank
use "${data}/bin_spouse_rank_par_rank_F", clear

rename spouse_rank spouse_rank_
reshape wide spouse_rank, i(par_pctile gender) j(kid_race)

rename spouse_rank_1 spouse_rank_white_
rename spouse_rank_2 spouse_rank_black_

reshape wide spouse_rank*, i(par_pctile) j(gender) string
renvars _all, subst(M male)
renvars _all, subst(F female)

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var spouse_rank_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var spouse_rank_`race'_`gender' "`label' `gender_label': Spouse Income Rank" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile spouse_rank
save `spouse_rank'


*Incarceration (males)
use "${data}/bin_incarcerated_par_rank_bw_M", clear

rename kid_jail kid_jail_
reshape wide kid_jail, i(par_pctile) j(kid_race)

rename kid_jail_1 kid_jail_white_male
rename kid_jail_2 kid_jail_black_male

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_jail_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_jail_`race'_`gender' "`label' `gender_label': Percentage Incarcerated April 1, 2010" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_jail_male
save `kid_jail_male'

*Incarceration (females)
use "${data}/bin_incarcerated_par_rank_bw_F", clear

rename kid_jail kid_jail_
reshape wide kid_jail, i(par_pctile) j(kid_race)

rename kid_jail_1 kid_jail_white_female
rename kid_jail_2 kid_jail_black_female

local i=1
foreach race in `races' {
	local u=1
	foreach gender in `genders' {
		local gender_label : word `u' of `genders_label'
		cap confirm var kid_jail_`race'_`gender' 
		if !_rc {
			local label : word `i' of `races_label'
			label var kid_jail_`race'_`gender' "`label' `gender_label': Percentage Incarcerated April 1, 2010" 
			}
		local ++u 	
		}	
	local ++i
	}

tempfile kid_jail_female
save `kid_jail_female'

* ----------------------------
* IMPORT COUNTS  
* ----------------------------

use "${final}/baseline_sum_stats", clear
drop if mom_native == "Native"
keep kid_race gender count


replace gender = "_male" if gender == "M"
replace gender = "_female" if gender =="F"
replace gender = "_pooled" if gender == "P"
gen kid_lab = "xx"
replace kid_lab = "_white" if kid_race == 1
replace kid_lab = "_black" if kid_race == 2
replace kid_lab = "_asian" if kid_race == 3
replace kid_lab = "_hisp" if kid_race == 4
replace kid_lab = "_aian" if kid_race == 5
drop kid_race
reshape wide count, i(gender) j(kid_lab) string
gen sample = 1
reshape wide count*, i(sample) j(gender) string	
drop sample
rename *xx* **
foreach var of varlist *{
	count if !mi(`var')
	if `r(N)' == 0 drop `var'
}
expand 100
gen par_pctile = _n
tempfile countsprep
save `countsprep'


use "${final}/density_byrace", clear
ren density_natam density_aian
gen density_pooled = 0.01
merge 1:1 par_pctile using `countsprep', nogen
qui: replace count_pooled = count_pooled * 0.01
label var count_pooled "Number of Children"

local i=1 
foreach race in `races' {
	local label : word `i' of `races_label'
	qui: replace count_`race'_pooled = count_`race'_pooled*density_`race' 
	label var count_`race'_pooled "Number of `label' Children" 
	local ++i
}
drop density* *_male *_female
tempfile counts
save `counts'

* density of parent income by race
use "${data}/density_byrace", clear
ren density_natam density_aian

local i=1 
foreach race in `races' {
	cap confirm var density_`race'
	if !_rc {
		qui: replace density_`race' = density_`race' * 100
		local label : word `i' of `races_label'
		label var density_`race' "`label': Percentage of Parents in a Given Inc. Percentile" 
		}
		rename density_`race' density_`race'_pooled
	local ++i
	}

tempfile density
save `density'

* ----------------------------
* MERGE 
* ----------------------------

* local prepared files
local files kfr_native_par_rank kfr_gender kfr_pooled ///
	kid_hours_gender kid_married kid_no_hs kid_college kid_pos_hours /// 
	kid_wage_rank kir_1par kir_2par kir_par_nohome ///
	kir_pooled kir_male kir_female spouse_rank kid_jail_male kid_jail_female ///
	counts density

use `kfr_par_rank', clear

foreach f of local files {
	merge 1:1 par_pctile using ``f'', nogen
}

* ----------------------------
* FORMAT 
* ----------------------------

* tostring vars to avoid weird rounding things and save (+export csv)
qui: ds par_pctile count*, not
foreach var in `r(varlist)' {
	format `var' %4.2f
	tostring `var', replace force
	replace `var' =substr(`var', 1, 5) 
}

* counts - rounded to nearest 100 
foreach var of varlist count*{
	replace `var' = round(`var',100)
	tostring `var', replace force
}
	
destring *, replace 

* Order variables
ds count* par_pctile* density*, not
order `r(varlist)', alphabetic 
order kir_*par*, after(kir_white_pooled) alphabetic
order kfr_*, alphabetic
order density*, alphabetic 
order count*, alphabetic 
order count_pooled
order par_pctile
order kir_black* kir_white*, after(kid_wage_rank_white_male)

* ----------------------------
* EXPORT 
* ----------------------------	
compress
save "${online_data_tables}/pctile_clps_complete", replace	
export delimited "${online_data_tables}/pctile_clps_complete.csv", replace