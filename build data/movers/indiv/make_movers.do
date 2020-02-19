/*

This .do file produces a dataset of one-time movers. 

*/

*------------------------------------------------------------------------------
* Setting up 
*------------------------------------------------------------------------------

* Set invariant variables to add to one-time movers file
local invariantvars ///
	kid_race		gender			par_rank ///
	kir_24 			kfr_24 			kir_30 ///
	kid_married_30 	kid_jail		kii_24 ///
	kfi_24			kii_30			par_inc

*Load data
use ///
	kid_pik			cohort			par_cz ///
	year 			numallmoves 	moved ///
	missingmoveyear lat				lon ///
	if numallmoves==1 using "${out}/movers_long", clear
	
*------------------------------------------------------------------------------
* Create age at move data  
*------------------------------------------------------------------------------

* Age variable
gen kid_age = year - cohort 

* Create age at move; initialize to missing
gen kid_aam = .

* If move was observed simply use kid age in year of move
replace kid_aam = kid_age if moved ==1 & missingmoveyear == 0

* If move was in missing year use the mean age of closest two years
	// Note that in the case where we want to exclude missing-year moves this next condition will never be triggered
by kid_pik (year): replace kid_aam = (kid_age + kid_age[_n-1])/2 if moved == 1 & missingmoveyear == 1

* Age at first move variable
egen kid_afm = min(kid_aam), by(kid_pik)

* First move indicator
gen firstmove = kid_aam == kid_afm if ~mi(kid_afm)

* Age before first move (have to do it this way to get origin from missing year moves where age of move is inferred) 
by kid_pik (year): replace kid_aam = 0 if firstmove[_n+1] == 1

* Drop non-move years (except origin)
drop if mi(kid_aam)

* Imputed move age flag 
gen imputed_aam = missingmoveyear == 1

* Generate chronological place variable with 0 for the origin
by kid_pik: egen place = rank(year)
replace place = place - 1

* Save maximum values of place in a local; this will simplify code later on for 
multiple vs one-time movers. Should be 1 for one-time movers and
3 for multiple movers (non-tract)*/	
su place, d
local pmax `r(max)'

* Keep relevant variables 
keep ///
	kid_pik			cohort		kid_aam ///
	imputed_aam 	par_cz 		lat ///
	lon				place

* Reshape into wide form
reshape wide kid_aam imputed_aam par_cz lat lon, i(kid_pik cohort) j(place)

* Now calculate move distance using latitude and longitude of origin and destination
geodist lat0 lon0 lat1 lon1, generate(dist) miles sphere

* Only want to keep distance variable, not latitude and longitude
drop lat0 lon0 lat1 lon1

*------------------------------------------------------------------------------
* Merge to invariant vars 
*------------------------------------------------------------------------------
* Merge on outcomes, parent income rank and family ID 
	// Note some people with missing gender will be in master but not in using data; drop them
merge 1:1 kid_pik using "${raw}/movers_invariant${suf}", assert(1 2 3) nogen keep(3) ///
	keepusing(`invariantvars')

*------------------------------------------------------------------------------
* Save  
*------------------------------------------------------------------------------
compress
save "${out}/movers", replace
