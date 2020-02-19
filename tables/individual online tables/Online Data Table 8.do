/*

This .do file creates Online Data Table 8: Intergenerational Transition Matrices 
of Educational Attainment by Race and Gender.  

*/

* Load data
use "${final}/edu_transition_matrix_mskd"

*Prepare labels for educational attainment
local lab1 Less than high school
local lab2 High school
local lab3 Some college/associate deg.
local lab4 Bachelor deg. or higher

*Rename count variable
rename n_rg count

*Label some variables
label var kid_race "Kid race"
label var gender "Kid gender"
label var count "Count of kids in a given cell"


*Reshape 
forval p=1/4 {

	preserve
	keep if par_level==`p'
	drop par_level
	rename par_share par_edu`p'
	
	label var par_edu`p' "P(parent educ. = `lab`p'')"
	
	forval k=1/4 {
		rename cond_p`k' kid_edu`k'_cond_par_edu`p'
		label var kid_edu`k'_cond_par_edu`p' "P(kid educ. = `lab`k'' | parent educ. = `lab`p'')"
	}
	
	tempfile p`p'
	save `p`p''
	restore
}

use `p1', clear
forval p=2/4 {
	merge 1:1 kid_race gender count using `p`p'', assert(3) nogen
}

*Make unconditional probabilities for children
forval k=1/4 {

	local sum 0
	forval p=1/4 {
		local sum `sum' + kid_edu`k'_cond_par_edu`p'*par_edu`p'
	}
	noi di "`sum'"
	gen kid_edu`k'=`sum'
	replace kid_edu`k'=round(kid_edu`k',0.0001)
	
	label var kid_edu`k' "P(kid educ. = `lab`k'')"
}

*Don't want kid_race==other
drop if kid_race=="Other"

*Order variables
order ///
	kid_race	gender		count ///
	kid_edu1	kid_edu2	kid_edu3	kid_edu4 ///
	par_edu1	par_edu2	par_edu3	par_edu4 ///
	kid_edu1_*	kid_edu2_*	kid_edu3_*	kid_edu4_* 


*Need to sort on race in our usual way
gen tmp=.
replace tmp=1 if kid_race=="White"
replace tmp=2 if kid_race=="Black"
replace tmp=3 if kid_race=="Asian"
replace tmp=4 if kid_race=="Hispanic"
replace tmp=5 if kid_race=="AIAN"

sort tmp gender 
drop tmp

* Export 
save "${online_data_tables}/edu_transition_matrix", replace
export delimited using "${online_data_tables}/edu_transition_matrix.csv", replace datafmt