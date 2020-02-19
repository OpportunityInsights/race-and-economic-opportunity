/*

This .do file creates Figures 6C-D, 7A-B, and Appendix Figure 5A-D. 

*/

*set the varlist that will be looped over
local loop_vars kid_hours_yr kid_no_hs spouse_rank kfr

*set the non-var specific graph specs
local msize 0.75

*loop over gender
foreach g in M F {

	*loop over selected outcome variables
	foreach var of local loop_vars {

	use "${final}/bin_`var'_par_rank_`g'", replace
		
	* Graph settings 
		local gapnumlist 25 75 //specify where to calculate the gap
		if "`var'"=="kid_hours_yr" {
			local ytitle "Weekly Hours Worked in ACS (Age >= 30)"
			local ymin 0
			local ymax 50
			local step 10
			local xtext_1 30
			local xtext_2 80
			if "`g'"=="M" {
				local ytext_1 18.5
				local ytext_2 43
			}
			if "`g'"=="F" {
				local ytext_1 21.5
				local ytext_2 37
			}		
			local textunit "Hours"
			local legpos 4 //position of the legend
			local var_label `var'
			local gapnum1 25
		}
		
		if "`var'"=="kid_no_hs" {
			replace kid_no_hs = 100-kid_no_hs
			local ytitle "Pct. of Children with High School Degree (Age >= 19)"
			local ymin 50
			local ymax 100
			local step 10
			local xtext_1 32
			if "`g'"=="M" local ytext_1 64
			if "`g'"=="F" local ytext_1 76
			local xtext_2 80
			if "`g'"=="M" local ytext_2 82
			if "`g'"=="F" local ytext_2 87
			local textunit ""
			local legpos 4 //position of the legend
			local var_label kid_hs
			}
		
		if "`var'"=="spouse_rank" {
			local ytitle "Mean Spouse's Individual Income Rank"
			local ymin 20
			local ymax 80
			local step 20
			local xtext_1 30
			if "`g'"=="M" local ytext_1 25
			if "`g'"=="F" local ytext_1 32
			local xtext_2 77
			if "`g'"=="M" local ytext_2 58
			if "`g'"=="F" local ytext_2 70
			local textunit ""
			local legpos 4 //position of the legend
			local var_label `var'
		}
		
			if "`var'"=="kfr" {
			local ytitle "Mean Child Household Income Rank"
			local ymin 20
			local ymax 80
			local step 20
			local xtext_1 30
			if "`g'"=="M" local ytext_1 25
			if "`g'"=="F" local ytext_1 30
			local xtext_2 77
			if "`g'"=="M" local ytext_2 68
			if "`g'"=="F" local ytext_2 70
			local textunit ""
			local legpos 4 //position of the legend
			local var_label `var'
		}
		

	*Do the set up for making the p25 gap and plotting a line to show the gap
	foreach p in 25 75 {
		gen pline`p'_val =.
		gen pline`p' =`p'
		}
	
	foreach race in 1 2 { 
		qui: reg `var' par_pctile if gender=="`g'" & kid_race ==`race'
		predict pred_`var'_`race'
		foreach p in 25 75 {
			if "`var'" == "kid_hours_yr" | "`var'" == "kid_no_hs" {
				qui: su pred_`var'_`race' if par_pctile == `p' & kid_race ==`race' ///
					& gender=="`g'" 
				local pred_`var'_`race'_p`p' = `r(mean)'	
				replace pline`p'_val = `pred_`var'_`race'_p`p'' in `race'	
				}
			else {
				qui: su `var' if par_pctile == `p' & kid_race ==`race' ///
					& gender=="`g'" 
				local `var'_`race'_p`p' = `r(mean)'	
				replace pline`p'_val = ``var'_`race'_p`p'' in `race'	
				}
			}
		}
		
	foreach p in 25 75 {		
		if "`var'" == "kid_hours_yr" | "`var'" == "kid_no_hs" {
			local gap`p' = `pred_`var'_1_p`p'' - `pred_`var'_2_p`p''
			local gap`p' : di %3.1f `gap`p''
			}
		else {
			local gap`p' = ``var'_1_p`p'' - ``var'_2_p`p''
			local gap`p' : di %3.1f `gap`p''
			}
		}
		
	* Make graphs 
	tw  (scatter `var' par_pctile if gender=="`g'" & kid_race==1, msize(`msize') mcolor(navy) msymbol(${sym_white})) ///
		(scatter `var' par_pctile if gender=="`g'" & kid_race==2, msize(`msize') mcolor(maroon) msymbol(${sym_black})) ///
		(lfit `var' par_pctile if gender=="`g'" & kid_race==2, lcolor(maroon)) ///
		(lfit `var' par_pctile if gender=="`g'" & kid_race==1, lcolor(navy)) ///
		(line pline25_val pline25, lcolor(black) lwidth(medthick)) ///
		(line pline75_val pline75, lcolor(black) lwidth(medthick)) ///
		,ytitle(`ytitle') xtitle("Parent Household Income Rank") ///
		ylabel(`ymin'(`step')`ymax', gmax gmin) ///
		legend(order(1 "White" 2 "Black") rows(2) ring(0) pos(`legpos') bm(b=3 t=3)) ///
		title(${title_size}) ///
		text(`ytext_1' `xtext_1' "Diff. at p=25: `gap25'", size(small)) ///
		text(`ytext_2' `xtext_2' "Diff. at p=75: `gap75'", size(small))
		graph export "${figures}/bin_`var_label'_par_rank_`g'.${img}", replace
	}
}