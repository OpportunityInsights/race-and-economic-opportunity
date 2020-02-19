/*

This .do file rearranges the data for graphing in Appendix Figure 4. 

*/

* loop over parent decile of interest
foreach par_dec in 3 8 {

	* load data 
	use if kid_race>0 using "${final}/occupation_histogram_mskd", clear

	* focus on parent decile of interest
	keep if par_d ==`par_dec'

	*drop the missing occupations
	drop if missing(kid_1occ)

	* collapse over parent decile 
	collapse (rawsum) count, by(kid_race gender kid_1occ)

	* compute fraction
	bys kid_race gender : egen total = total(count)
	gen frac = (count/total)*100
	drop count total

	* reshape wide on kid race
	reshape wide frac, i(kid_1occ gender) j(kid_race)

	keep gender kid_1occ frac1 frac2
	chopper , vars(frac1 frac2)
		
	save "${final}/bar_occ_by_gender_pardec`par_dec'", replace
}