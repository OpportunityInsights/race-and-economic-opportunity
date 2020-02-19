/* 

This .do file rearranges the incarceration data for graphing in Figure 7E-F. 

*/
foreach g in M F {

* Load in the data
	use par_pctile gender kid_race kid_jail count ///
		if gender=="`g'" & (kid_race == 1 | kid_race == 2) ///
		using "${final}/pctile_clps_mskd.dta", clear

	* Rescale 	
	replace kid_jail = kid_jail*100

	* Keep relevant variables 
	keep par_pctile kid_jail kid_race

	* Output 
	ds par_pctile, not
	chopper, vars(`r(varlist)')
	save "${final}/bin_incarcerated_par_rank_bw_`g'", replace
}