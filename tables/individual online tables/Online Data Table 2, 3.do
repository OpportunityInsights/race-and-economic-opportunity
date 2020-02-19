/*

This .do file creates Online Data Table 2: National Child and Parent Income Transition Matrices by Race and Gender, 
and Online Data Table 3: National Child and Parent Income Transition Matrices by Race and Gender for Children 
with Mothers Born in the U.S.

*/

* Online Data Table 2
use "${final}/transition_matrix_mskd"

qui: ds par_pctile count*, not
foreach var in `r(varlist)' {
	format `var' %4.2f
	tostring `var', replace force
	replace `var' =substr(`var', 1, 5) 
}

save "${online_data_tables}/transition_matrix_table", replace	
export delimited "${online_data_tables}/transition_matrix_table.csv", replace