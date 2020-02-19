/*

This .do file creates the input data for movers analysis

*/

*Need to run the code separately by cohort groups because of server constraints
local grp1
local grp2
forval c=$fcohort/$lcohort {
	if mod(`c',2)==0 local grp1 `grp1' , `c'
	else if mod(`c',2)~=0 local grp2 `grp2' , `c'
}

* Loop over groups 
foreach g in 1 2 {

	*Load data, drop PIKs with missing gender and rows before birth
	use ///
		kid_pik  	cohort		year ///
		par_cz 		par_zip  ///
		if inlist(cohort `grp`g'') & (year-cohort)>=0 & ~mi(par_cz) ///
		using "${in}/long${suf}", clear
	
	*Generate "moved indicator": We observe you switching geographies, not necessarily in consecutive calendar years
	sort kid_pik year
	by kid_pik (year): gen moved = par_cz[_n]~=par_cz[_n-1] if ~mi(par_cz[_n-1])

	*Calendar year of move
	gen yearofmove = year if moved == 1

	*Calendar year observed before move
	by kid_pik (year): gen yearbeforemove = year[_n-1] if moved == 1

	*Flag moves that occur during missing calendar years
	gen missingmoveyear = (yearofmove-yearbeforemove) > 1 if moved == 1

	gen strictmoved = moved * (1-missingmoveyear)

	*How many times did each kid move in the observed years?
	egen nummoves=total(strictmoved), by(kid_pik)
	
	egen numallmoves=total(moved), by(kid_pik)
	
	merge2 m:1 par_zip using "${ext}/zip_latlon${suf}", using_keys(zip) nogen keep(1 3) keepusing(lat lon)

	*Keep only variables of interest
	keep ///
		kid_pik 	year 			par_cz ///
		cohort 	///
		lat 		lon 			moved ///
		nummoves 	numallmoves 	missingmoveyear 

	*Compress
	compress

	tempfile cz`g'
	save `cz`g''
}

* Append results together 
use `cz1', clear
append using `cz2'
sort kid_pik year

* Export 
save "${out}/movers_long", replace