/* 

This .do file rearranges the data for Figure 5. 

*/

foreach g in M F {

	* Load in data 
	use par_pctile gender kid_race kir count ///
		if gender=="`g'" & (kid_race == 1 | kid_race == 2) ///
		using "${final}/pctile_clps_mskd", clear
		
	* Rescale KIR 
	replace kir = kir*100

	* Select variables to keep 
	keep par_pctile kir kid_race
	
	* Output 
	ds par_pctile kid_race, not
	chopper, vars(`r(varlist)')
	save "${final}/bin_kir_par_rank_`g'", replace
}