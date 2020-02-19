/*

This .do file calculates hockey sticks in microdata. 

*/

*Load data (blacks and whites, both genders)
use if inlist(kid_race,1,2) using "${out}/movers", clear

*Keep only if observed for at least two years in destination
gen year_of_move = cohort + kid_aam1

*Kids are only observed until age 30 or 2015
	// For some kids the following variable doesn't make sense: e.g 1991 cohort only observed until age 24
gen max_year = cohort + 30
drop if min(max_year,2015)-year_of_move < 2

*Impose distance restriction
if ${mindist}>0 {
	geodist lat0 lon0 lat1 lon1, generate(dist) miles sphere
	drop if dist < ${mindist} | dist==.
}

*Round age at move for kids with imputed age at move
replace kid_aam1 = floor(kid_aam1) if imputed_aam1==1 & inlist(substr(kid_pik,9,1),"0","1","2","3","4")
replace kid_aam1 = ceil(kid_aam1) if imputed_aam1==1 & inlist(substr(kid_pik,9,1),"5","6","7","8","9")

*Generate other kid race variable
rename kid_race own_kid_race
gen other_kid_race = .
replace other_kid_race = 2 if own_kid_race == 1
replace other_kid_race = 1 if own_kid_race == 2

*Save this as tempfile
tempfile basefile
save `basefile'

*Store first outcome of interest in local for regsave output later on
local first `: word 1 of ${hockeystickvars}'

*Now make hockey sticks for different outcome variables

foreach outcome of global hockeystickvars {
	use `basefile', clear

	di "Doing outcome `outcome'"
	
	if "`outcome'"=="incarcerated" {
		gen age_of_outcome = 2010-cohort
		keep if age_of_outcome>23
	}	
	
	*Keep only important variables
	keep kid_pik own_kid_race other_kid_race gender cohort `outcome' par_* kid_aam1
	
	*Drop kids who are missing outcome e.g. due to cohort
	drop if mi(`outcome')
	
	*Merge on raw and predicted intercept and slope, both measured for own and other race
	foreach r in own other {
		rename `r'_kid_race kid_race
		forvalues p=0/1 {
			rename par_cz`p' par_cz 
			merge m:1 par_cz cohort kid_race gender using ${data}/xw_estimates/xw_estimates_cohort, ///
				nogen keep(1 3) keepusing(`outcome'_*)
			
			*Raw Exposure-weighted estimate
			gen `r'_e_`p'=`outcome'_icept+par_rank*`outcome'_slope
			replace `r'_e_`p'=. if  `outcome'_count<${mincount}  | ~inrange(`r'_e_`p',0,1)
			
			*Drop merged vars before next iteration of loop
			drop `outcome'_*
			
			rename par_cz par_cz`p'
		}
		rename kid_race `r'_kid_race 

		*Generate move quality variables
		gen `r'_d_e = `r'_e_1-`r'_e_0
	}
	
	*Now do hockey sticks
	
	*Indicators for age at move range
	gen r_u13 = kid_aam1 <= 13
	gen r_14_23 = inrange(kid_aam1,14,23)
	gen r_a24 = kid_aam1 > 23
	gen r_u23 = kid_aam1 <= 23

	
	*Interact with move quality
	local ages u13 14_23 a24 u23
	foreach a of local ages {
		foreach r in own other {
			gen `r'_m_d_e_r_`a'=kid_aam1*`r'_d_e*r_`a'
			gen `r'_d_e_r_`a'=`r'_d_e*r_`a'
		}
	}
	
	*Other important variables 
	su kid_aam1, d
	local amin `r(min)'
	local amax `r(max)'
	forvalues i=`amin'/`amax' {
		gen byte age_`i' = (kid_aam1==`i')
		gen par_rank_age_`i' = par_rank * age_`i'
	}

				
	su cohort, d
	local cmin `r(min)'
	local cmax `r(max)'
	forvalues c=`cmin'/`cmax' {
		gen byte cohort_`c' = (cohort == `c')
		foreach r in own other {
			gen `r'_d_e_cohort_`c'  = `r'_d_e * cohort_`c'
			gen `r'_e_0_cohort_`c'  = `r'_e_0 * cohort_`c'
		}
	}


	*Drop some variables to avoid collinearity 
	drop own_d_e_cohort_`cmax' other_d_e_cohort_`cmax' cohort_`cmax' age_`amax'
	
	*Loop over different age cuts
	foreach spline of global splines {
	
		*Initialize locals
		*For own race spec
		local fitslope
		local fitcons
		foreach a of local spline {
			local fitslope `fitslope' own_m_d_e_r_`a'
			local fitcons `fitcons' own_d_e_r_`a'
		}
		
		*For placebo spec
		local placebofitslope
		local placebofitcons
		foreach a of local spline {
			local placebofitslope `placebofitslope' own_m_d_e_r_`a' other_m_d_e_r_`a'
			local placebofitcons `placebofitcons' own_d_e_r_`a' other_d_e_r_`a'
		}	

		foreach race in 1 2 {
			foreach gender in M F {
					
				if "`outcome'"=="`first'" & "`spline'"=="u23 a24" & "`gender'"=="M" & "`race'"=="1" local opt replace
				else local opt append
				
				*Parametric movers spec without cohort delta interactions (own race only)
				*Local controls for parametric spec (eq 6 movers 1)
				local controls "cohort_* own_e_0_cohort_* age_* par_rank_age_*"
				reg `outcome' `fitslope' `fitcons' `controls' if own_kid_race==`race' & gender == "`gender'"
				regsave `fitslope' using "${out}/hs_exposure_effects", cmdline `opt' ///
					addlabel(ranges,"`spline'",yvar, "`outcome'", spec, "own race", race, "`race'", gender, "`gender'")			
				
				
				*Parametric movers spec without cohort delta interactions (own and other race)
				*Local controls for parametric spec (eq 6 movers 1)
				local controls "cohort_* other_e_0_cohort_* own_e_0_cohort_* age_* par_rank_age_*"
				reg `outcome' `placebofitslope' `placebofitcons' `controls' if own_kid_race==`race' & gender == "`gender'"
				regsave `placebofitslope' using "${out}/hs_exposure_effects", cmdline append ///
					addlabel(ranges,"`spline'",yvar, "`outcome'", spec, "placebo", race, "`race'", gender, "`gender'")
					
			}
		}
	}
}

*Clean output file
use "${out}/hs_exposure_effects", clear
order ranges race gender yvar spec
sort ranges race gender yvar spec

*Resave
save "${out}/hs_exposure_effects", replace