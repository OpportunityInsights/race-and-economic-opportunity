/*

This .do file rearranges the non-SCF data for Figure 8 and Appendix Figure 9. 

*/

*loop over parent income percentile
foreach p in 25 75 {

* loop through each race (black = 2, asian = 3, hispanic = 4, native american = 5)
	foreach race in 2 5 4 {


	* load data
	use "${final}/cond_regressions_mskd", clear
	keep if yvar == "kir" & gender != "P" & race == `race'
	keep gender gap par_inc edu two_par wealth tract block cmdline p
	sort gap
	gen order = .

	* loop through both genders and order regressions that are relevant for figure
	*now the controls are defined in indicator variables
	foreach gender in M F{

		* none
		replace order = 1 if gender=="`gender'" & p==`p' ///
			& par_inc == 0 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 0 

		* par inc	
		replace order = 2 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 0 

		* par inc + two par
		replace order = 3 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 1 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 0 
			
		* par inc + two par + edu
		replace order = 4 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 1 ///
			& two_par == 1 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 0 

		* par inc + two-par + edu + wealth
		replace order = 5 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 1 ///
			& two_par == 1 ///
			& wealth == 1 ///
			& tract == 0 ///
			& block == 0 

		* par inc + tract
		replace order = 6 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 1 ///
			& block == 0 

		* par inc + block	
		replace order = 7 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 1 
	}

	* keep relevant gaps 
	keep if ~missing(order)

	* make xaxis (shifts bars left and right based on gender)
	gen xaxis = .
	replace xaxis = order - 0.15 if gender == "M"
	replace xaxis = order + 0.15 if gender == "F"

	* format labels
	replace gap = gap * -1 * 100
	format gap %4.1f
	gen ylab = gap
		

	drop if order>=6
	gen race=`race'
	gen race_name="`race_label'"
	chopper, vars(gap ylab)
	save "${final}/bar_sequential_controls_`race_label'_p`p'", replace			
	}
}