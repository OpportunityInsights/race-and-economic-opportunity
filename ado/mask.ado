
*------------------------------------------------------------------------------
* Define masking program
*------------------------------------------------------------------------------

cap program drop mask
program define mask

	syntax , by(varlist) countvar(varname) [minbin(real 10) round(real 0) roundcounts]
	
	quietly {
	
	*Verify that file is unique on the varlist
	egen byvar=group(`by'), missing
	isid byvar
	drop byvar
	
	
	
	*Count number of observations if rounding option is specified
	if `round'~=0 {
		count
		local obsmax `r(N)'
	}
	
	*Mask
	ds `by' `countvar', not
	foreach var in `r(varlist)' {
		recast double `var'
		replace `var' = . if `countvar'<`minbin' | mi(`countvar')
		g temp=abs(`var')
		su temp
		if `r(N)'>0 {
			local varmax = `r(max)'
		}
		else {
			local varmax=0
		}
		if `varmax'>1 replace `var' = `var'/1000000
		if `round'~=0 {
			forvalues i=1/`obsmax' {
				sigdig `var'[`i'] `round'
				replace `var' = `r(value)' in `i'
			}
		}
		if `varmax'>1 replace `var'=`var'*1000000
		
		drop temp
	}
	
	*Round observation counts
	replace `countvar'=. if `countvar'<`minbin'
	
	if "`roundcounts'"~="" {
		replace `countvar' = 14 if `countvar'<15	
		replace `countvar' = round(`countvar', 10) if inrange(`countvar',15,99)
		replace `countvar' = round(`countvar', 50) if inrange(`countvar',100,999)
		replace `countvar' = round(`countvar', 100) if inrange(`countvar',1000,9999)
		replace `countvar' = round(`countvar', 500) if inrange(`countvar',10000,99999)
		replace `countvar' = round(`countvar', 1000) if inrange(`countvar',100000,999999)
		replace `countvar' = round(`countvar', 1000) if inrange(`countvar',1000000,9999999)
		replace `countvar' = round(`countvar', 10000) if inrange(`countvar',10000000,99999999)
	}

	
	
	*Sort and order
	sort `by'
	order `by' `countvar'
	
	}
	
end

