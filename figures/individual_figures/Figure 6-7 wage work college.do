/* 

This .do file creates Figures 6A, 6B, 6E, 6F, 7C and 7D. 

*/

* Set variables to graph 
local loop_vars kid_wageflex_rank kid_pos_hours kid_somecoll
local msize 0.75

*loop over gender
foreach g in F M {
	
	*loop over selected outcome variables
	foreach var of local loop_vars {
		use "${final}/bin_`var'_par_rank_`g'", clear
				
		if "`var'"=="kid_wageflex_rank" {
			local ytitle "Mean Child Wage Rank (Age >= 30)"
			local ymin 20
			local ymax 80
			local step 20
			local xtext25 30
			if "`g'"=="M" local ytext25 28
			if "`g'"=="F" local ytext25 30
			if "`g'"=="M" local xtext75 80
			if "`g'"=="M" local ytext75 42
			if "`g'"=="F" local xtext75 70
			if "`g'"=="F" local ytext75 57
			local textunit ""
			local gapnumlist 25 75 //specify where to calculate the gap
			local legpos 4 //position of the legend
			
		}
		
		if "`var'"=="kid_pos_hours" {
			local ytitle "Percent of Children Working in ACS (Age >= 30)"
			local ymin 50
			local ymax 100
			local step 10
			local xtext25 40
			if "`g'"=="M" local ytext25 81.5
			if "`g'"=="F" local ytext25 72
			local xtext75 80
			if "`g'"=="M" local ytext75 75
			if "`g'"=="F" local ytext75 77
			local textunit ""
			local gapnumlist 25 75 //specify where to calculate the gap
			local legpos 4 //position of the legend
		}
		
		if "`var'"=="kid_somecoll" {
			local ytitle "College Attendance Rate for Children (%)"
			local ymin 20
			local ymax 100
			local step 20
			if "`g'"=="F" local xtext25 30
			if "`g'"=="F" local ytext25 48
			if "`g'"=="M" local xtext25 20
			if "`g'"=="M" local ytext25 50
			
			local xtext75 64
			if "`g'"=="M" local ytext75 73
			if "`g'"=="F" local ytext75 83
			local textunit ""
			local gapnumlist 25 75 //specify where to calculate the gap
			local legpos 4 //position of the legend
		}

	*Do the set up for making the p25 gap and plotting a line to show the gap

		*define the black white gap at pX on the predicted line
			reg `var' par_pctile if gender=="`g'" & kid_race==1
			predict white_pred
			reg `var' par_pctile if gender=="`g'" & kid_race==2
			predict black_pred
			
			local gapvar1 white_pred
			local gapvar2 black_pred
		
		local lfit "(line white_pred par_pctile if gender=="`g'" & kid_race==1, lcolor(navy)) (line black_pred par_pctile if gender=="`g'" & kid_race==2, lcolor(maroon))" 
				
		local vertline
		local textbox
		
		*calculate the lines and gaps at various locations
		foreach gapnum of local gapnumlist {
				local gaploc `gapnum'
				*Using the predicted values for the pX gap
				summ `gapvar1' if gender=="`g'" & kid_race==1 & par_pctile==`gapnum'
				local white_p`gapnum' `r(mean)'
				summ `gapvar2' if gender=="`g'" & kid_race==2 & par_pctile==`gapnum'
				local black_p`gapnum' `r(mean)'
				local gap`gapnum': di %4.1f `white_p`gapnum''-`black_p`gapnum''		
				
				*make a series that will plot the black line at pX
				*only need two points
				gen pline`gapnum'=`gapnum' if _n<=2
				gen pline`gapnum'_val=.
				replace pline`gapnum'_val=`white_p`gapnum'' if _n==1
				replace pline`gapnum'_val=`black_p`gapnum'' if _n==2
			
			*make the tw code for the vertical lines
			local vertline `vertline' ///
				(line pline`gapnum'_val pline`gapnum', lcolor(black) lwidth(medthick)) 
			
			*make the tw code for the text (so that it adjusts when number of lines changes)
			local textbox `textbox' ///
				text(`ytext`gapnum'' `xtext`gapnum'' "Diff. at p=`gaploc': `gap`gapnum'' `textunit'", size(small))
		}
		tw  (scatter `var' par_pctile if gender=="`g'" & kid_race==1, msize(`msize') mcolor(navy) msymbol(${sym_white})) ///
			(scatter `var' par_pctile if gender=="`g'" & kid_race==2, msize(`msize') mcolor(maroon) msymbol(${sym_black})) ///
			`lfit' ///
			`vertline' ///
			,ytitle("`ytitle'") xtitle("Parent Household Income Rank") ///
			ylabel(`ymin'(`step')`ymax', gmax gmin) ///
			legend(order(1 "White" 2 "Black") rows(2) ring(0) pos(`legpos') bm(b=3)) ///
			title(${title_size}) ///
			`textbox'
			
		graph export "${figures}/bin_`var'_par_rank_`g'.${img}", replace
		}
}