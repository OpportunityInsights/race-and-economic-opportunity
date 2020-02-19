/*

This .do file runs a series of regressions conditioning on observables to document 
earnings gaps relative to whites. 

Note: in order to interpret the coefficients at the income level of interest, the 
parent rank is differenced out. 

*/

set more off

* Read in the skinny data (only one row per kid required for this collapse)
	// Use only the 1978-1983 cohorts
use ///
	kid_pik				kid_race		gender ///
	cohort				par_rank		par_state ///
	par_county			par_tract		par_block ///
	has_dad				has_mom			two_par ///
	par_edu				par_homeowner	par_mortgage ///
	par_homevalue 		par_vehicles ///
	${regvars} ///
	using "${work}/race_work_78_83${suf}", clear
	
* Store a local of the races
levelsof kid_race, local(race_list)

* Store a local with the first outcome and race
local first `: word 1 of ${regvars}'
local first_r `: word 1 of `race_list''

* Generate a group variable for tracts and blocks
egen par_geo_tract=group(par_state par_county par_tract)
egen par_geo_block=group(par_state par_county par_tract par_block)

* Keep only those with non-missing geography to keep sample constant
drop if par_block==-9

* Difference out parent rank to interpret the gap at the 25th and 75th percentile
g pr_d25 = par_rank-.25
g pr_d75=par_rank-.75

* Run regressions by gender and pooled
quietly foreach g in M F P {

	* If doing pooled regressions make everybody a P
	if "`g'"=="P" replace gender="P"
	
	foreach p in 25 75 {
		foreach r of local race_list {
		
			* Generate the kid_black indicator
			g kid_mnrty=kid_race==`r' if kid_race==1 | kid_race==`r'

			* Generate interaction term
			g km_pr_d`p' = kid_mnrty*pr_d`p'
				
			foreach v of global regvars {	
				noi di "Gender: `g' Percentile: `p' Race: `r' Outcome: `v'"

				* Replace output on first pass
				if "`v'"=="`first'" & "`g'"=="M" & `r'==`first_r' & `p'==25 local opt replace
				else local opt append
				
				* Raw gap
				reg `v' kid_mnrty if gender=="`g'" 
				regsave using "${out}/raw_regressions", cmdline `opt' ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 0, two_par, 0, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for parent income
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 0, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for parent income and two parents
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' two_par if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 1, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for parent income and education
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' i.par_edu if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 1, two_par, 0, wealth, 0, tract, 0, block, 0)
		
				* Gap controlling for parent income and wealth proxies 
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' i.par_homeowner ///
					par_mortgage par_homevalue i.par_vehicles if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 0, wealth, 1, tract, 0, block, 0)
		
		
				* Gap controlling for parent income and education and two parents
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' two_par i.par_edu if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 1, two_par, 1, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for parent income, wealth, education, and two parents
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' two_par i.par_edu i.par_homeowner ///
					par_mortgage par_homevalue i.par_vehicles if gender=="`g'" 
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 1, two_par, 1, wealth, 1, tract, 0, block, 0)
					
				* Gap controlling for parent income and tract
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' if gender=="`g'", absorb(par_geo_tract)
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 0, wealth, 0, tract, 1, block, 0)
					
				* Gap controlling for parent income and block
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' if gender=="`g'", absorb(par_geo_block)
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 0, wealth, 0, tract, 0, block, 1)
					
				* Gap controlling for parent income and block and two parents
				reg `v' kid_mnrty pr_d`p' km_pr_d`p' two_par if gender=="`g'", absorb(par_geo_block)
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 1, edu, 0, two_par, 1, wealth, 0, tract, 0, block, 1)
		
				* Gap controlling for education only
				reg `v' kid_mnrty i.par_edu if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 1, two_par, 0, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for two parents only
				reg `v' kid_mnrty two_par if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 0, two_par, 1, wealth, 0, tract, 0, block, 0)
					
				* Gap controlling for wealth proxies only
				reg `v' kid_mnrty i.par_homeowner par_mortgage par_homevalue i.par_vehicles if gender=="`g'"
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 0, two_par, 0, wealth, 1, tract, 0, block, 0)
					
				* Gap controlling for tract only
				reg `v' kid_mnrty if gender=="`g'", absorb(par_geo_tract)
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 0, two_par, 0, wealth, 0, tract, 1, block, 0)
					
				* Gap controlling for block only
				reg `v' kid_mnrty if gender=="`g'", absorb(par_geo_block)
				regsave using "${out}/raw_regressions", cmdline append ///
					addlabel(race, `r', ///
					gender, `g', ///
					yvar, `v', ///
					p, `p', ///
					par_inc, 0, edu, 0, two_par, 0, wealth, 0, tract, 0, block, 1)		
			}
			drop kid_mnrty km_pr_d`p'
		}
	}
}

* Clean output file
use "${out}/raw_regressions", clear

* Keep only rows that report the gaps
keep if var=="kid_mnrty"
rename coef gap
drop var

* Sort and order
order race gender yvar p N r2 gap stderr par_inc edu two_par wealth tract block cmdline
sort p race gender yvar  
compress
save "${out}/cond_regressions", replace
