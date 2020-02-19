/*

This .do file produces counts of men in each census tract in the year 2000. 

*/

*------------------------------------------------------------------------------
* 2000 Census and tax data
*------------------------------------------------------------------------------

* Begin with the Databank spine
use ///
	pik		gender		cohort ///
	fam_inc		fr		fil_stat ///
	if gender~="0" ///
	using "${in}/tax_2000${suf}", clear

* Merge to the 2000 Census file
	// Keep only matched set of people who are correct age and appear in Databank
merge 1:1 pik using "${in}/2000_short${suf}", keep(3) nogen ///
	keepusing(cohabitate married race mafid)
	
* Merge on the tract from the MAF
merge m:1 mafid using "${raw}/maf_tract${suf}", keep(1 3) nogen

* Make gender lower case
rename gender tmp
g gender="m" if tmp=="M"
replace gender="f" if tmp=="F"
drop tmp

* Generate an age variable and a binning of the age variable
g age=2000-cohort
g age_bin=floor(age/10)

* Generate dependent variables
g filed=~mi(fil_stat)
g cohab=cohabitate==1
g inc="h" if fr>.5
replace inc="l" if fr<=.5

* Generate rows pooling ages and income status
expand 4
bysort pik: g row_id=_n

* Pooled estimates
replace inc="p" if row_id==1
replace age_bin=0 if row_id==1

* Pooling income by age
replace inc="p" if row_id==2

* Pooling age by income
replace age_bin=0 if row_id==3

* Remove row IDs 
drop row_id

* Produce datasets of counts of men at the tract-race-gender level
collapse (sum) married cohab filed (count) count=cohort, ///	
	by(state county tract race age_bin inc gender)
	
* Put gender wide
ds gender race county tract state age_bin inc, not
foreach i in `r(varlist)' {
	rename `i' `i'_
}

ds gender race county tract state age_bin inc, not
reshape wide `r(varlist)', i(state county tract race age_bin inc) j(gender) string

* Put race wide
rename race tmp
g race=""
replace race="w" if tmp==1
replace race="b" if tmp==2
replace race="a" if tmp==3 
replace race="h" if tmp==4
replace race="i" if tmp==5
replace race="o" if tmp==6
drop tmp
ds race county tract state age_bin inc, not
foreach i in `r(varlist)' {
	rename `i' `i'_
}
ds race county tract state age_bin inc, not
reshape wide `r(varlist)', i(state county tract age_bin inc) j(race) string

* Put income wide
ds inc county tract state age_bin, not
foreach i in `r(varlist)' {
	rename `i' `i'_
}
ds inc county tract state age_bin, not
reshape wide `r(varlist)', i(state county tract age_bin) j(inc) string

* Put age wide
ds county tract state age_bin, not
foreach i in `r(varlist)' {
	rename `i' `i'_
}
ds county tract state age_bin, not
reshape wide `r(varlist)', i(state county tract) j(age_bin)

* Output
compress
save "${out}/tract_gender", replace

*------------------------------------------------------------------------------
* Counts of fathers in our data
*------------------------------------------------------------------------------

* Use the year 2000
use ///
	kid_race		has_dad			par_rank ///
	par_state		par_county		par_tract ///
	year ///
	if year==2000 & par_rank<.5 & par_state>0 & (kid_race==1 | kid_race==2) ///
	using "${work}/race_work_long_78_83", clear

* Execute collapse	
collapse (sum) dads=has_dad (count) kids=par_rank, ///
	by(par_state par_county par_tract kid_race)
	
* Dads per below median kid
g dads_kid=dads/kids

* Reshape wide
reshape wide dads kids dads_kid, i(par_state par_county par_tract) j(kid_race)
rename (*1 *2) (*_2000_white *_2000_black)

* Output
save "${out}/tract_dad_counts", replace
