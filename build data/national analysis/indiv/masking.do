/*

This .do files masks each output file 

*/

set more off
cap program drop mask

*------------------------------------------------------------------------------
* Define count masking program
*------------------------------------------------------------------------------
* Program that rounds counts 
cap program drop rounder
program define rounder

	syntax , vars(varlist)
	
	quietly foreach v in `vars' {
		replace `v' = 14 if `v'<15	
		replace `v' = round(`v', 10) if inrange(`v',15,99)
		replace `v' = round(`v', 50) if inrange(`v',100,999)
		replace `v' = round(`v', 100) if inrange(`v',1000,9999)
		replace `v' = round(`v', 500) if inrange(`v',10000,99999)
		replace `v' = round(`v', 1000) if inrange(`v',100000,999999)
		replace `v' = round(`v', 1000) if inrange(`v',1000000,9999999)
		replace `v' = round(`v', 10000) if inrange(`v',10000000,99999999)
	}
	
end

* Program that rounds the results
cap program drop chopper
program define chopper

	syntax , vars(varlist) [round(real 4)]
	
	quietly {
	
		*get the number of obs
		if `round' != 0 {
		count 
		local obsmax `r(N)'
				
		foreach var in `vars' {
		
			g temp=abs(`var')
			su `var'
			if `r(N)'>0 {
				local varmax `=abs(`r(max)')'
			}
			else {
				local varmax=0
			}
			if `varmax'>1 replace `var' = `var'/100000000
				forval i = 1/`obsmax' {
					sigdig `var'[`i'] `round'
					replace `var' = `r(value)' in `i'
				}
			if `varmax'>1 replace `var'=`var'*100000000
			drop temp
			}
		}
	}
end 


*------------------------------------------------------------------------------
* Percentile Collapse
*------------------------------------------------------------------------------

use "${out}/pctile_clps", clear

* Round extra count variables
ds n_*
rounder, vars(`r(varlist)')

* Suppress continous variables with small n 
foreach i of global pctilecont {
	replace `i'=. if n_`i'<10
	replace n_`i'=. if n_`i'<10
}

*Suppress rate variables with small n 
foreach i of global pctilerate {
	g mask=1  if (n_`i'*`i'<10) | (n_`i'*(1-`i')<10)
	replace `i'=. if mask==1
	replace n_`i'=. if mask==1
	drop mask
}
	
* Mask
mask, by(par_pctile kid_race gender) countvar(count) minbin(10) round(4) roundcounts

* Output masked version
save "${final}/pctile_clps_mskd", replace

*------------------------------------------------------------------------------
* Percentile cutoffs
*------------------------------------------------------------------------------

use "${out}/pctile_cutoffs", clear

* Assert counts are all greater than 1000 
foreach c in kfi kii pi {
	assert `c'_count>1000 
	assert `c'_mean==. if mi(`c'_count)
}
	
* Round count variables
rounder, vars(kfi_count kii_count pi_count)

* Round results
ds *mean 
chopper, vars(`r(varlist)') 

* Output
save "${online_data_tables}/pctile_cutoffs_mskd", replace

*------------------------------------------------------------------------------
* Transition Matrix
*------------------------------------------------------------------------------

use "${out}/transition_matrix", clear

* Assert to make sure these data are never problematic
forvalues i=1/5 {
	forvalues j=1/5 {
		foreach y in kir kfr {
			g num=`y'_q`i'_cond_par_q`j'*par_q`j'*count
			g denom=(1-`y'_q`i'_cond_par_q`j')*par_q`j'*count
			assert num>=10
			assert denom>=10
			drop num denom
		}
	}
}

* Mask and round
mask, by(kid_race gender mom_native) countvar(count) minbin(10) round(4) roundcounts

* Output masked version
save "${final}/transition_matrix_mskd", replace

*Neighborhood version
use "${out}/transition_matrix_good_nbhd", clear

*Assert to make sure these data are never problematic
forvalues i=1/5 {
	forvalues j=1/5 {
		foreach y in kir kfr {
			g num=`y'_q`i'_cond_par_q`j'*par_q`j'*count
			g denom=(1-`y'_q`i'_cond_par_q`j')*par_q`j'*count
			assert num>=10
			assert denom>=10
			drop num denom
		}
	}
}

*Mask and round
mask, by(kid_race gender) countvar(count) minbin(10) round(4) roundcounts

*Output masked version
save "${final}/transition_matrix_good_nbhd_mskd", replace

*------------------------------------------------------------------------------
* Education transition matrix 
*------------------------------------------------------------------------------
	// Note that we already checked that the counts are sufficiently large in edu_transition_matrix.do
	
use "${out}/edu_transition_matrix", clear 
	
* Mask and round 	
mask, by(kid_race gender par_level) countvar(n_rg) round(4) minbin(20) roundcounts

*Need to re-order after masking
order ///
	kid_race	gender		n_rg ///	
	par_level 	par_share ///
	cond_p*

* Output masked version 
save "${final}/edu_transition_matrix_mskd", replace

*------------------------------------------------------------------------------
* Rank rank by cohort
*------------------------------------------------------------------------------

use "${out}/rank_rank_cohort", clear

*Mask and round
mask, by(kid_race cohort) countvar(N) minbin(10) round(4) roundcounts

*Output masked version
save "${final}/rank_rank_cohort_mskd", replace

*------------------------------------------------------------------------------
* Occupation histogram
*------------------------------------------------------------------------------

use "${out}/occupation_histogram", clear

*Mask and round
rounder, vars(count)
assert count>=10 & ~mi(count)

*Output masked version
save "${final}/occupation_histogram_mskd", replace

*------------------------------------------------------------------------------
* Conditional regressions
*------------------------------------------------------------------------------

use "${out}/cond_regressions", clear

*Mask and round
mask, by(race gender yvar p par_inc edu two_par wealth tract block cmdline) ///
	countvar(N) minbin(10) round(4) roundcounts
	
*Resort and order data like it was before
order race gender yvar p N r2 gap stderr par_inc edu two_par wealth tract block cmdline
sort p race gender yvar  

*Output masked version
save "${final}/cond_regressions_mskd", replace

*------------------------------------------------------------------------------
* Neighborhood quality collapse
*------------------------------------------------------------------------------

use "${out}/nbhd_quality", clear

*Mask and round
mask, by(kir_pctile kid_race gender) ///
	countvar(count) minbin(10) round(4) roundcounts 

*Output masked version
save "${final}/nbhd_quality_mskd", replace

*------------------------------------------------------------------------------
* Dad regressions
*------------------------------------------------------------------------------

use "${out}/dad_regressions", clear

*Mask and round
mask, by(yvar var cmdline race gender) ///
	countvar(N) minbin(10) round(4) roundcounts

*Output masked version
save "${final}/dad_regressions_mskd", replace

*------------------------------------------------------------------------------
* Parent individual income regressions
*------------------------------------------------------------------------------

use "${out}/par_indv_regressions", clear

*Mask and round
mask, by(race gender yvar var cmdline) ///
	countvar(N) minbin(10) round(4) roundcounts

*Output masked version
save "${final}/par_indv_regressions_mskd", replace 

*------------------------------------------------------------------------------
* Baseline summary statistics
*------------------------------------------------------------------------------

use "${out}/baseline_sum_stats", clear

*Round count variables
rounder, vars(count acs_count)

*Round results
ds kid_race gender mom_native count acs_count, not
chopper, vars(`r(varlist)') 

*Make sure counts are high
assert count>=10 & acs_count>=10 & ~mi(count) & ~mi(acs_count)

*Output masked version
save "${final}/baseline_sum_stats_mskd", replace

*------------------------------------------------------------------------------
* Parent summary statistics
*------------------------------------------------------------------------------

use "${out}/par_sum_stats", clear

*Round count variables
rounder, vars(count acs_count)

*Round results
ds kid_race count acs_count, not
chopper, vars(`r(varlist)') 

*Make sure counts are high
assert count>=10 & acs_count>=10 & ~mi(count) & ~mi(acs_count)

*Output masked version
save "${final}/par_sum_stats_mskd", replace

*------------------------------------------------------------------------------
* Rank-rank slopes for second-generation immigrants 
*------------------------------------------------------------------------------
	// note that we have already restricting to countries with sufficient observations

* Load data
use "${out}/robustness_immig_par.${suf}", clear 

* Mask 
mask, by(outcome par_rank country gender) countvar(N) roundcounts minbin(10) round(4)

* Output masked version  
save "${final}/robustness_immig_par_mskd.${suf}", replace

* Load data 
use "${out}/robustness_immig_nonpar${suf}.dta", clear 

* Mask 
mask, by(country gender par_rank outcome par_ventile) countvar(N) roundcounts minbin(10) round(4)

* Output masked version 
save delimited "${final}/robustness_immig_nonpar_mskd.${suf}", replace

* Load data 
use "${out}/robustness_immig_income_vent_cw.${suf}", clear 

* Mask 
foreach var in kir kfr base dadonly {
	ds `var'*, not
	mask,  by(`r(varlist)') countvar(`var'_count) roundcounts minbin(10) round(4)
}

* Output masked version
save "${final}/robustness_immig_income_vent_cw_mskd.${suf}", clear 

*------------------------------------------------------------------------------
* Appendix tables
*------------------------------------------------------------------------------

*** ACS-Tax transition matrix ***

use "${out}/appdx_acs_tax_matrix", clear

*Round count variables
rounder, vars(count)

*Round results
ds tax_q count, not
chopper, vars(`r(varlist)') 

*Make sure counts are high
assert count>=10 & ~mi(count)

*Output masked version
save "${final}/appdx_acs_tax_matrix_mskd", replace

*** ACS-Tax income comparison ***

use "${out}/appdx_income_quality", clear

*Round count variables
rounder, vars(count)

*Round results
ds samp count, not
chopper, vars(`r(varlist)') 

*Make sure counts are high
assert count>=10 & ~mi(count)

*Output masked version
save "${final}/appdx_income_quality_mskd", replace

*** Linkage counts ***

use "${out}/appdx_linkage_counts", clear

*Counts are already in the thousands and so are rounded by definition

*Output masked version
save "${final}/appdx_linkage_counts_mskd", replace

*** Sample bias ***

use "${out}/appdx_sample_bias", clear

*Round count variables
rounder, vars(count count_dm1 count_final count_miss)

*Round results
ds race count count_dm1 count_final count_miss, not
chopper, vars(`r(varlist)') 

*Make sure counts are high
assert count>=10 & ~mi(count)

*Output masked version
save "${final}/appdx_sample_bias_mskd", replace

*** Data quality numbers ***
import delimited "${out}/data_quality_numbers.csv", clear

*Round results
chopper, vars(v2)

*Output masked version
export delimited "${final}/data_quality_numbers_mskd.csv", replace 

*------------------------------------------------------------------------------
* CZ level data
*------------------------------------------------------------------------------

use "${out}/cz_mobility", clear

*Round extra count variables
ds n_*
rounder, vars(`r(varlist)' tot_count)

*Suppress continous variables
foreach i in $geocont $georate par_rank par_rich {
	replace `i'=. if n_`i'<20
	replace n_`i'=. if n_`i'<20
}

*Mask slopes and intercept when count is masked
foreach i of global geovars {
	foreach stem in icept slope slope_se icept_se cov {
		replace `i'_`stem'=. if n_`i'==.
	}
}
	
*Output masked version
save "${final}/cz_mobility_mskd", replace