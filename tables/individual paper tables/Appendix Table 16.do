/*

This .do file creates Appendix Table 16, using tract-level data reported in the 
Opportunity Atlas. 

*/

clear
set more off

qui {

*Start by preparing a base file with all the information we need

*Read in tract-race-gender collapse
use ///	
		state		county		tract ///
		cz			czname ///
		kir_black_male_p25 	///
		kir_white_male_p25 ///
		has_dad_black_male_p25 	 ///
		frac_below_median_black_male ///
		kir_black_male_n ///
		using "${ext}/tract_outcomes", clear


*Keep only tracts with sufficient low-income children
gen low_inc_black_male = frac_below_median_black_male*kir_black_male_n
keep if low_inc_black_male>50 & ~mi(low_inc_black_male)
		
*Merge on neighborhood names
merge 1:1 state county tract using "${ext}/tract_nhbd_wide", nogen keep(1 3) keepusing(nhbd_name)

*Merge on poverty share (2000 Census)
merge2 1:1 state county tract using "${ext}/tract_covars", nogen keep(1 3) using_keys(state10 county10 tract10) keepusing(poor_share2000)

*Require tracts to have all variables of interest
keep if ~mi(kir_black_male_p25) & ~mi(has_dad_black_male_p25) & ~mi(poor_share2000)

tempfile base
save `base'

*Now identify three different types of places: Best, Average, Worst

*-------------------------------------------------------------------------------
*Places with high mean income, high mean father presence, low poverty
*-------------------------------------------------------------------------------

*Get p95 of outcomes
su kir_black_male_p25 [w=kir_black_male_n],d
local inc=`r(p90)'

*Keep the places in the set
keep if kir_black_male_p25>`inc' & has_dad_black_male_p25>0.5 & poor_share2000<0.1

/*
noi di ""
noi di "Best places for p25 kids"
noi {
tab czname
tab nhbd_name if czname=="New York", m
tab nhbd_name if czname=="Washington DC", m
}
*/

*Need to label Silver Spring manually
replace nhbd_name="Silver Spring" if state==24 & county==31 & tract==704000

*Use: NY Queens, Laurelton, Wakefield DC: Silver Spring, New Carrolton
keep if ///
	(nhbd_name=="Silver Spring" & czname=="Washington DC") | ///
	(nhbd_name=="Alexandria West" & czname=="Washington DC") | ///
	(nhbd_name=="Queens Village" & czname=="New York") | ///
	(nhbd_name=="Laurelton" & czname=="New York") | ///
	(nhbd_name=="East Flatbush" & czname=="New York")  
	
gen type="best"

tempfile best
save `best'

*-------------------------------------------------------------------------------
*Places with aveage mean income, average mean father presence, average poverty
*-------------------------------------------------------------------------------

use `base', clear

*Get p40-p60 of outcomes
*Note we need to use xtile here because p40 and p60 are not available after su, d
xtile inc_pctile =kir_black_male_p25 [w=kir_black_male_n], nq(100)
su kir_black_male_p25 if inc_pctile==40
local inc_low = `r(mean)'
su kir_black_male_p25 if inc_pctile==60
local inc_high = `r(mean)'

*Get p40-p60 of dad presence
xtile dad_pctile= has_dad_black_male_p25 [w=kir_black_male_n], nq(100)
su has_dad_black_male_p25 if dad_pctile==40
local dad_low=`r(mean)'
su has_dad_black_male_p25 if dad_pctile==60
local dad_high=`r(mean)'

*Get p40-p60 of poor_share
xtile poor_pctile=poor_share2000 [w=kir_black_male_n], nq(100)
su poor_share2000 if poor_pctile==40
local poor_low = `r(mean)'
su poor_share2000 if poor_pctile==60
local poor_high = `r(mean)'

*Keep the places in the set
keep if inrange(kir_black_male_p25,`inc_low', `inc_high') & inrange(has_dad_black_male_p25,`dad_low',`dad_high') ///
	& inrange(poor_share2000,`poor_low', `poor_high')

*Need to replace some labels
replace nhbd_name="East Little York/Homestead" if nhbd_name=="East Little York - Homestead"

*Need to replace some labels
replace nhbd_name="Capitol View" if nhbd_name=="Sylvan Hills + Capitol View"

*Use: Houston: Sunnyside, South Union, Memphis: Coro Lake, White Haven 
keep if ///
	(nhbd_name=="East Little York/Homestead" & czname=="Houston") | ///
	(nhbd_name=="Sunnyside" & czname=="Houston") | ///
	(nhbd_name=="North Charlotte" & czname=="Charlotte") | ///
	(nhbd_name=="Capitol View" & czname=="Atlanta") | ///
	(nhbd_name=="Olney" & czname=="Philadelphia")

gen type="average"

tempfile average
save `average'

*-------------------------------------------------------------------------------
*Places with low mean income, low mean father presence, high poverty
*-------------------------------------------------------------------------------

use `base', clear

*Get p10 of outcomes
su kir_black_male_p25 [w=kir_black_male_n],d
local inc=`r(p10)'

*Get p25 of dad presence
su has_dad_black_male_p25 [w=kir_black_male_n],d
local dad =`r(p10)'

*Get p85 of poor_share
xtile tmp= poor_share2000 [w=kir_black_male_n], nq(100)
su poor_share2000 if tmp==85
local poor =`r(mean)'
drop tmp

*Keep the places in the set
keep if kir_black_male_p25<`inc' & has_dad_black_male_p25<`dad' & poor_share2000>`poor'

*Need to replace some labels
replace nhbd_name="Chandler Park" if state==26 & county==163 & tract==512400

*Use: Chicago, Detroit, Cincinnati, LA
keep if ///
	(nhbd_name=="South Loop" & czname=="Chicago") | ///
	(nhbd_name=="Englewood" & czname=="Chicago") | ///	
	(nhbd_name=="Chandler Park" & czname=="Detroit") | ///	
	(nhbd_name=="West End" & czname=="Cincinnati") | ///
	(nhbd_name=="South Los Angeles" & czname=="Los Angeles") 
	
gen type="worst"

tempfile worst
save `worst'

*Now we need to append the different sets of tracts and output
clear
foreach t in best average worst {
	append using ``t''
}

*Merge on county name
gen cty=string(state,"%02.0f")+string(county,"%03.0f")
destring cty, replace
merge m:1 cty using "${ext}/cty_cz_st_names", assert(2 3) keep(3) keepusing(county_name) nogen

*Make a place name that combines the neighborhood and county names
gen place=nhbd_name+", " + county_name + " County"

*Make a tract FIPS code
gen tract_fips=string(state,"%02.0f")+string(county,"%03.0f")+string(tract,"%06.0f")

*Keep only variables of interest
keep ///
	type 		tract_fips 		czname	///
	place 		///
	kir_black_male_p25 ///
	has_dad_black_male_p25 ///
	poor_share2000 ///
	kir_black_male_n ///
	kir_white_male_p25

*Some neighborhoods appear twice -- de-duplicate
gen temp=.
replace temp=1 if type=="best"
replace temp=2 if type=="average"
replace temp=3 if type=="worst"

bys temp czname place: keep if _n==1
drop temp

*Replace ranks to be between 0-100
replace kir_black_male_p25=kir_black_male_p25*100
replace kir_white_male_p25=kir_white_male_p25*100
replace race_gap=race_gap*100

order ///
	type 		tract_fips 		czname	///
	place 		///
	kir_black_male_p25 ///
	has_dad_black_male_p25 ///
	poor_share2000 ///
	race_gap

export delimited using "${tables}/list_of_places.txt", replace
}

