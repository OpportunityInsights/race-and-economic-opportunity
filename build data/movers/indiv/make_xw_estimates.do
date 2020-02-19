/*

This .do file makes exposure-weighted estimates for movers race results. 

*/

local outcomevars kir_24 kfr_24 kir_30 kid_married_30 kid_jail

* Load permanent residents and many-time movers 
use if numallmoves == 0 | numallmoves > 1 using "${out}/movers_long", clear

* Keep only kid-age rows
keep if (year-cohort)<=23

* Merge on outcomes, parent income rank 
	// Note some people with missing gender will be in master but not in using data, drop them
merge m:1 kid_pik using ${raw}/movers_invariant${suf}, assert(1 2 3) nogen keep(3) ///
	keepusing(kid_race gender par_rank `outcomevars')

* Gen observation count of kid in each cz they lived in
bys kid_pik cohort kid_race gender par_cz: gen count = _N

* Keep only first row for each kid and cz
by kid_pik cohort kid_race gender par_cz: keep if _n == 1

* Keep only necessary variables
keep kid_pik cohort kid_race gender par_cz `outcomevars' par_rank count

* Make pooled race row
expand 2, gen(duplicate)
replace kid_race = 0 if duplicate == 1
drop duplicate

* Keep only pooled race, whites, and blacks
keep if inlist(kid_race,0,1,2)

* Make pooled gender row
expand 2, gen(duplicate)
replace gender = "P" if duplicate == 1
drop duplicate

* Sort data here so we don't need to do it for each iteration of following loop
sort par_cz cohort kid_race gender

* Save dataset in tempfile 
tempfile basefile
save `basefile'

foreach y of local outcomevars {

	use `basefile', clear
	
	* For regressby3 to work we need to drop groups with too few observations to start with
	drop if mi(`y')
	by par_cz cohort kid_race gender: gen distinctkids = _N
	drop if distinctkids < 4
	drop distinctkids
	
	regressby3 `y' par_rank , by(par_cz cohort kid_race gender) weightby(count) robust
	
	* Rename variables
	rename (_b_cons _b_par_rank _se_cons _se_par_rank cov N) (`y'_icept `y'_slope `y'_icept_se `y'_slope_se `y'_cov `y'_count)
	keep par_cz cohort kid_race gender ///
		`y'_icept `y'_slope `y'_icept_se `y'_slope_se `y'_cov `y'_count
	
	* Save
	tempfile `y'
	save ``y''
}

* Merge estimates for all outcomes together
clear
local i=0
foreach y of local outcomevars {
	local ++ i
	 if `i'==1 use ``y'', clear
	 else merge 1:1 par_cz cohort kid_race gender ///
		using ``y'', nogen
}

sort par_cz cohort kid_race gender

* Save this dataset for reference
save "${out}/xw_estimates", replace