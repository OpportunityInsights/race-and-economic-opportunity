/*

This .do file produces neighborhood quality statistics cut by income percentile. 

*/

set more off

*------------------------------------------------------------------------------
* Tract level has_dad estimates
*------------------------------------------------------------------------------

* Load data 
use ///
	par_state		par_county		par_tract ///
	n_has_dad		has_dad_slope		has_dad_icept ///
	gender 			kid_race ///
	if gender=="P" & (kid_race==1|kid_race==2) & par_state>0 ///
	using "${out}/tract_mobility", clear

*Keep only those with sufficient sample sizes
keep if n_has_dad>=20 & ~mi(n_has_dad)

*Generate p25 estimates
g has_dad_p25=has_dad_slope*.25 + has_dad_icept

*Reshape estimates
g race="_white" if kid_race==1
replace race="_black" if kid_race==2
drop kid_race n_has_dad has_dad_slope has_dad_icept gender
reshape wide has_dad_p25, i(par_state par_county par_tract) j(race) string

*Output
tempfile dads
save `dads'

*------------------------------------------------------------------------------
* Father presence in adult vs. childhood neighborhood
*------------------------------------------------------------------------------

*Read in only those with non-missing childhood neighborhoods and adult neighborhoods
	// Only black males in third decile
	// Note that we are using the full sample (not just 78-83) and then cutting in the regs
use ///
	kid_pik			gender			kid_race ///
	par_rank		cohort			kir ///
	kid_state		kid_county		kid_tract ///
	par_state		par_county		par_tract ///
	kir_everwork 		has_dad			two_par_census ///
	if kid_race==2 & gender=="M" & kid_state>0 & par_state>0 & par_rank>.2 & par_rank<.3 ///
	using "${work}/race_work", clear
	
* Group adult tract
egen kid_geo_tract=group(kid_state kid_county kid_tract)

* Parent deciles
g par_d=ceil(par_rank*10)

* Merge in poverty rates
merge2 m:1 par_state par_county par_tract using "${ext}/covariates", ///
	nogen keep(3) using_keys(state county tract) keepusing(poor_share2000)
		
* Merge in the exposure-weighted has_dad estimates
merge m:1 par_state par_county par_tract using `dads', ///
	nogen keep(3) 
rename (has_dad_p25_black has_dad_p25_white) (has_dad_p25_black_parent has_dad_p25_white_parent)
drop par_state par_county par_tract

merge2 m:1 kid_state kid_county kid_tract using `dads', ///
	nogen keep(3) using_keys(par_state par_county par_tract)
rename (has_dad_p25_black has_dad_p25_white) (has_dad_p25_black_kid has_dad_p25_white_kid)

* Keep only kids who have both values populated
keep if ~mi(has_dad_p25_black_parent) & ~mi(has_dad_p25_black_kid)

foreach y in kir kir_everwork {
	if "`y'"=="kir" local opt replace
	else local opt append
	
	reg `y' has_dad_p25_black_parent if cohort<=1983, absorb(kid_geo_tract)
	regsave using "${out}/dad_regressions", cmdline `opt' ///
		addlabel(race, 2, ///
		gender, M, ///
		yvar, `y', has_dad, .)
	
	reg `y' has_dad_p25_black_parent has_dad_p25_black_kid if cohort<=1983
	regsave using "${out}/dad_regressions", cmdline append ///
		addlabel(race, 2, ///
		gender, M, ///
		yvar, `y', has_dad, .)
}

* Check for measurement error in the has_dad variable
forvalues i=0/1 {
	reg two_par_census has_dad_p25_black_kid if has_dad==`i' & cohort>1983
	regsave using "${out}/dad_regressions", cmdline append ///
		addlabel(race, 2, ///
		gender, M, ///
		yvar, two_par_census, has_dad, `i')
}
	
*------------------------------------------------------------------------------
* Neighborhood quality collapse
*------------------------------------------------------------------------------

* Read in only those with non-missing childhood neighborhoods
use ///
	kid_pik			gender			kid_race ///
	par_rank		cohort			kir ///
	kid_state		kid_county		kid_tract ///
	kii ///
	if (kid_race==1 | kid_race==2) & kid_state>0 ///
	using "${work}/race_work_78_83${suf}", clear

* Generate income percentiles for the kids
g kir_pctile=ceil(kir*100)

* Merge on poverty rates
merge2 m:1 kid_state kid_county kid_tract using "${ext}/covariates", ///
	nogen keep(1 3) using_keys(state county tract) keepusing(poor_share2000 singleparent_share2000)
	
* Merge in the exposure-weighted has_dad estimates
merge2 m:1 kid_state kid_county kid_tract using `dads', ///
	nogen keep(1 3) using_keys(par_state par_county par_tract) 
	
*Produce collapse 
collapse ///
	(mean) kii poor_share2000 has_dad* singleparent_share2000 ///
	(count) count=cohort, ///
	by(kir_pctile kid_race gender)
	
*Output
order kir_pctile kid_race gender count
sort kir_pctile kid_race gender count
compress
save "${out}/nbhd_quality", replace