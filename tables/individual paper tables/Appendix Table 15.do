/*

This .do file creates Appendix Table 15. 

*/

foreach gender in M {
	*Load in masked data in previous format
	use if gender=="`gender'" using "${final}/hs_exposure_effects_mskd", clear

	*Drop unnecessary vars and rows
	drop r2 cmdline gender
	drop if ranges == "u13 14_23 a24" & spec == "placebo"

	*Reshape long (store stats order variable in local)
	local i = 1 
	foreach var in coef stderr N {
		rename `var' value`var'
		local order`var' = `i'
		local i `=`i'+1'
	}

	reshape long value, i(ranges race yvar spec var) j(stat) string

	*Order differently
	order ranges spec race yvar

	*Order stats variable (want coeff then standard error then N)
	gen orderstats = .
	foreach stat in N coef stderr {
		replace orderstats = `order`stat'' if  stat  =="`stat'"
	}

	gen orderages = .
	local i = 1 
	foreach var in u13 14_23 a24 {
		local order`var' = `i'
		replace orderages = `order`var'' if strpos(var,"`var'") & ranges=="u13 14_23 a24"
		local i `=`i'+1'
	}

	local i = 1 
	foreach var in u23 a24 {
		local order`var' = `i'
		replace orderages = `order`var'' if strpos(var,"`var'") & ranges=="u23 a24"
		local i `=`i'+1'
	}



	*Now rename some vars so final sort works
	foreach age in u23 a24 {
	replace var = "a_own_m_d_e_r_`age'" if var == "own_m_d_e_r_`age'" & spec=="placebo"
	replace var = "b_other_m_d_e_r_`age'" if var == "other_m_d_e_r_`age'" & spec=="placebo"
	}

	*Drop unnecessary repetitions of N
	bysort ranges spec race yvar (orderages var orderstats): drop if _n~=_N & stat=="N"


	*Last sort
	sort ranges spec race yvar orderages var orderstats
	drop orderstats orderages

	*Tostring 
	replace value = round(value,0.001)
	gen value2 = string(value, "%013.3fc")
	replace value2 = subinstr(value2, ".000","",.) if stat=="N"
	gen value3 = "("+value2+")"
	replace value2 = value3 if stat=="stderr"
	drop value value3
	rename value2 value
	if "`gender'"=="M" export delimited "${tables}/movers_exposure_effects_male_mskd.txt", replace
	else if "`gender'"=="F" export delimited "${tables}/movers_exposure_effects_female_mskd.txt", replace
}