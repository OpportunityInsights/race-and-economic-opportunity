/*

This .do file constructs geographic collapses that store key variables. 

*/

set more off

*Local that stores first and number of outcome vars
local tot `: word count ${geovars}'

*Loop over by variables for estimates
quietly foreach by of global geoby {

	* Store name of by variables
	if "`by'"=="par_cz gender kid_race" local dat "cz"
	if "`by'"=="par_state par_county par_tract gender kid_race" local dat "tract"	
	noi di "Beginning `dat' level data"

	* Read in long data for exposure weigthed estimates
	use ///
		kid_pik			`by'		par_rank ///
		par_rich		${geovars} ///
		using "${work}/race_work_long_78_83${suf}", clear
	
	* Reduce to one row per kid*geography
	noi di "	Reducing `dat' level data to one row per kid-geo"
	bysort `by' kid_pik: g count=_N
	by `by' kid_pik: keep if _n==1
		
	* Expand the dataset to 3 rows per kid - one for each set of by variables
	expand 3
	bysort `by' kid_pik: g row_id=_n
	
	* Tract level estimates
	replace kid_race=0 if row_id==1
	replace gender="P" if row_id==1
	
	* Tract-race level estimates
	replace gender="P" if row_id==2
	
	* Tract-race-gender estimates are good as is
	drop row_id	
	
	* Sort the data - e-ranks rely on this sort
	noi di "	Sorting `dat' level data for regressions"
	sort `by' kid_pik		
	tempfile reginput
	save `reginput', replace
	
	* Produce tract level e-ranks
	foreach y of global geovars {
		noi di "		Running `dat' level e-ranks for `y'"
		use ///
			kid_pik		par_rank	count ///
			`y'		`by' ///
			if ~mi(`y') using `reginput', clear
		
		* Drop geographies with fewer than 4 kids
		by `by': g distinctkids=_N
		drop if distinctkids<4
		drop distinctkids

		* Produce the estimates
		regressby3 `y' par_rank , by(`by') weightby(count) robust
		rename (_b_cons _b_par_rank _se_cons _se_par_rank cov) ///
			(`y'_icept `y'_slope `y'_icept_se `y'_slope_se `y'_cov)
		keep `by' `y'_icept `y'_slope `y'_icept_se `y'_slope_se `y'_cov

		tempfile `y'
		save ``y'', replace
	}
	
	*Produce a collapse that includes tract level means, unique, and total counts
		// Start by counting number of non-missing variables for each y
		// tot_count gives total number of kid*yr rows included in estimate
		// n_* gives unique non-missing count for each variable
	use `reginput', clear
	foreach y in ${geovars} par_rank par_rich {
		g n_`y'=~mi(`y')
	}
	collapse (mean) ${geovars} par_rank par_rich ///
		(rawsum) tot_count=count n_* [w=count], by(`by') 
	
	*Merge on the e-ranks
	forvalues i=1/`tot' {
		merge 1:1 `by' using ``: word `i' of ${geovars}'', nogen assert(1 3) 
	}
	
	*Clean and output
	noi di "	Outputting `dat' level data"
	order `by' tot_count
	sort `by' 
	compress
	save "${out}/`dat'_mobility", replace
}