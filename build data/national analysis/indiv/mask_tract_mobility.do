/*

This .do file masks the tract mobility output.  

*/

set more off
cap program drop mask

*------------------------------------------------------------------------------
* Define count masking program
*------------------------------------------------------------------------------
* Program that rounds counts 
cap program drop rounder
program define rounder

	syntax , vars(varlist)
	
	quietly foreach v in `vars' {
		replace `v' = 14 if `v'<15	
		replace `v' = round(`v', 10) if inrange(`v',15,99)
		replace `v' = round(`v', 50) if inrange(`v',100,999)
		replace `v' = round(`v', 100) if inrange(`v',1000,9999)
		replace `v' = round(`v', 500) if inrange(`v',10000,99999)
		replace `v' = round(`v', 1000) if inrange(`v',100000,999999)
		replace `v' = round(`v', 1000) if inrange(`v',1000000,9999999)
		replace `v' = round(`v', 10000) if inrange(`v',10000000,99999999)
	}
	
end

* Program that rounds the results
cap program drop chopper
program define chopper

	syntax , vars(varlist) [round(real 4)]
	
	quietly {
	
		*get the number of obs
		if `round' != 0 {
		count 
		local obsmax `r(N)'
				
		foreach var in `vars' {
		
			g temp=abs(`var')
			su `var'
			if `r(N)'>0 {
				local varmax `=abs(`r(max)')'
			}
			else {
				local varmax=0
			}
			if `varmax'>1 replace `var' = `var'/100000000
				forval i = 1/`obsmax' {
					sigdig `var'[`i'] `round'
					replace `var' = `r(value)' in `i'
				}
			if `varmax'>1 replace `var'=`var'*100000000
			drop temp
			}
		}
	}
end 

* ----------------------------------
* Mask tract mobility
* ----------------------------------

use "${out}/tract_mobility", clear

*Round extra count variables
ds n_*
rounder, vars(`r(varlist)' tot_count)

*Suppress continous variables
foreach i in $geocont $georate par_rank par_rich {
	replace `i'=. if n_`i'<20
	replace n_`i'=. if n_`i'<20
}

foreach i in $georate par_rich {
	g mask=1  if (n_`i'*`i'<20) | (n_`i'*(1-`i')<20) | mi(`i')
	replace `i'=. if mask==1
	replace n_`i'=. if mask==1
	drop mask
}


*Mask slopes and intercept when count is masked
foreach i of global geovars {
	foreach stem in icept slope slope_se icept_se cov {
		replace `i'_`stem'=. if n_`i'==.
	}
}
	
*Output masked version
save "${final}/tract_mobility_mskd", replace
