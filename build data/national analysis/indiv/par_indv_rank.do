/*

This .do file produces rank-rank slopes using parent individual income. 

*/

set more off

*Read in the skinny data (only one row per kid required for this collapse)
	// Use only the 1978-1983 cohorts
use ///
	kid_pik			kid_race		gender ///
	cohort			par_rank		mom_rank ///
	dad_rank 		kir				kfr ///
	using "${work}/race_work_78_83", clear

* Expand to capture a pooled race row
expand 2, gen(id)
replace kid_race=0 if id==1
drop id

* Store a local of the races
levelsof kid_race, local(race_list)
local first_r `: word 1 of `race_list''

* Run regressions by gender and pooled
quietly foreach g in M F P {

	*If doing pooled regressions make everybody a P
	if "`g'"=="P" replace gender="P"

	foreach r of local race_list {
		foreach v in kir {	
			noi di "Gender: `g' Race: `r' Outcome: `v'"

			*Replace output on first pass
			if "`v'"=="kir" & "`g'"=="M" & `r'==`first_r' local opt replace
			else local opt append
				
			*Reg on mom and dad				
			reg `v' mom_rank dad_rank if gender=="`g'" & kid_race==`r'
			regsave using "${out}/par_indv_regressions", cmdline `opt' ///
				addlabel(race, `r', ///
				gender, `g', ///
				yvar, `v')
		}
	}
}

* Clean output file
use "${out}/par_indv_regressions", clear
order race gender yvar N var coef stderr r2 cmdline
sort race gender yvar cmdline var
save "${out}/par_indv_regressions", replace