/*

This .do file produces  non-parametric hockey sticks for black and white male one-time movers

*/

local outcomevars kir_24 kfr_24 kir_30 kid_married_30 kid_jail

* Load data (only white and black male one-time movers)
use ///
	kid_pik		gender		cohort ///
	kid_race	kid_aam1	imputed_aam1 ///
	par_cz0		par_cz1		dist ///
	`outcomevars' 	par_rank ///
	if gender == "M" & inlist(kid_race,1,2) using "${out}/movers", clear

* Drop movers who don't meet move distance requirement
drop if dist < ${mindist} | dist==.

* Keep only if observed for at least two years in destination
gen year_of_move = cohort + kid_aam1

* Kids are only observed until age 30 or 2015
gen max_year = cohort + 30

* For some kids the following variable doesn't make sense: e.g 1991 cohort only observed until age 24
drop if min(max_year,2015)-year_of_move < 2

* Randomly age at move for kids with imputed age at move to nearest integer 
replace kid_aam1 = floor(kid_aam1) if imputed_aam1==1 & inlist(substr(kid_pik,9,1),"0","1","2","3","4")
replace kid_aam1 = ceil(kid_aam1) if imputed_aam1==1 & inlist(substr(kid_pik,9,1),"5","6","7","8","9")

* Save this as tempfile
tempfile basefile
save `basefile'

* Now make hockey sticks for different outcome variables
foreach y of local outcomevars {
	use `basefile', clear

	di "Doing outcome `y'"
	
	if "`y'"=="kid_jail" {
		gen age_of_outcome = 2010-cohort
		keep if age_of_outcome>23
	}
	
	* Keep only important variables
	keep kid_pik kid_race gender cohort `y' par_cz0 par_cz1 par_rank kid_aam1
	
	* Drop kids who are missing outcome e.g. due to cohort
	drop if mi(`y')
	
	* Merge on raw and predicted intercept and slope
	forvalues p=0/1 {
		rename par_cz`p' par_cz 
		merge m:1 par_cz cohort kid_race gender using ${raw}/xw_estimates${suf}, ///
			nogen keep(1 3) keepusing(`y'_*)
		
		* Raw Exposure-weighted estimate
		gen e_`p'=`y'_icept+par_rank*`y'_slope
		replace e_`p'=. if  `y'_count<${mincount}  | ~inrange(e_`p',0,1)
		
		* Drop merged vars before next iteration of loop
		drop `y'_*
		
		rename par_cz par_cz`p'
	}
	
	*Now do hockey sticks

	*Move quality variable
	gen d_e = e_1 - e_0
	
	*Now do analysis for binned age variable 
	su kid_aam1
	local amin `r(min)'
	local amax `r(max)'
	forvalues i=`amin'/`amax' {
		gen byte age_`i' = (kid_aam1==`i')
		gen d_e_age_`i' = d_e * age_`i'	
		gen par_rank_age_`i' = par_rank * age_`i'
	}
		
	su cohort
	local cmin `r(min)'
	local cmax `r(max)'
	forvalues c=`cmin'/`cmax' {
		gen byte cohort_`c' = (cohort == `c')
		gen e_0_cohort_`c'  = e_0 * cohort_`c'
	}

	*Drop some variables to avoid collinearity 
	drop cohort_`cmax' age_`amax'

	*Local controls for parametric spec (eq 6 movers 1)
	local controls "cohort_* e_0_cohort_* age_* par_rank_age_*"

	*Parametric movers spec
	statsby _b _se n=(e(N)), by(kid_race gender) clear: reg `y' d_e_age_* `controls' 
	keep _b_d_e_age_* _se_d_e_age_* _eq2_n kid_race gender

	*Reshape long
	reshape long _b_d_e_age_ _se_d_e_age_, i( _eq2_n kid_race gender) j(age)
	rename (_b_d_e_age_ _se_d_e_age_ _eq2_n) (coeff se count)
	
	*Save outcome variable
	gen yvar = "`y'"
	
	*Save as tempfile
	tempfile `y'
	save ``y''
}

*Now append the hockey stick output files for all variables
clear
foreach y of local outcomevars {
	append using ``y''
}

*Order data
order kid_race gender yvar age coeff se

*Sort data
sort kid_race gender yvar age

*Save data
save "${out}/hs_standard", replace