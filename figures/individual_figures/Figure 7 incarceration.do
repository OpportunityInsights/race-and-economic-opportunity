/*

This .do file creates the incarceration graphs in Figure 7. 

*/

foreach g in M F  {

* Load in the data
	use "${final}/bin_incarcerated_par_rank_bw_`g'", clear
		
	* Compute statistics
	forvalues race = 1/2{
		* Slopes
		reg kid_jail par_pctile if kid_race == `race'
		local slope_`race'  : di %4.3f _b[par_pctile]
		local se_`race' 	: di %4.3f _se[par_pctile]
		di "Slope `race': `slope_`race''"
		di "SE `race': `se_`race''"
		* Ranks at percentiles
		di "check1"
		if "`g'" =="M" {
				foreach perc in 25 75{
					summarize kid_jail if par_pctile == `perc'  & kid_race == `race', meanonly
					local p`perc'_`race' = `r(mean)'
					di "p`perc' `race': di %3.1f `p`perc'_`race''"
				}
				
	}
	}

	if "`g'" =="M" {
			* Gaps
			foreach perc in 25 75{
				di `p`perc'_1'
				di `p`perc'_2'
				local gap_p`perc' : di %3.1f (`p`perc'_1' - `p`perc'_2' )
				di "Black-White gap at p`perc': `gap_p`perc''"
			}
			
			*plot the lines on the gaps
			foreach p in 25 75 {
				gen pline`p' = `p' if _n<=2
				gen pline`p'_val=.
				replace pline`p'_val = `p`p'_1' if _n==1
				replace pline`p'_val = `p`p'_2' if _n==2
				
			}
	}
	
	* set the location of the text box
		if "`g'"=="M" {
			local xtext25 30
			local ytext25 13
			local xtext75 83
			local ytext75 5.5
			local textbox 	text(`ytext25' `xtext25' "Diff. at p=25: `gap_p25'", size(small)) ///
							text(`ytext75' `xtext75' "Diff. at p=75: `gap_p75'", size(small))
			local line 		(line pline25_val pline25, lcolor(black) lwidth(medthick)) ///
							(line pline75_val pline75, lcolor(black) lwidth(medthick)) 
		}
		if "`g'"=="F" {
			local xtext25 20
			local ytext25 3
			local xtext75 90
			local ytext75 3
			local textbox ""
			local line ""
		}
		
	* Plot 
	local psize 0.75
	twoway ///
		(scatter kid_jail par_pctile if kid_race == 1, ///
			msize(`psize') mcolor(navy) msymb(${sym_white})) ///
		(scatter kid_jail par_pctile if kid_race == 2, ///
			mcolor(maroon) msize(`psize') msymb(${sym_black})) ///
		`line' ///
		, xtitle("Parent Household Income Rank") ///
		ytitle("Pct. of Children Incarcerated on April 1, 2010 (Ages 27-32)", ///
			margin(t=3)) ///
		ylabel(0(5)22, gmax gmin) ///
		xlabel(0(20)100) ///	
		`textbox' ///
		legend(order( 1 "White" ///
			2 "Black") col(1) ring(0) pos(1)) ///
		title(${title_size}) 
	graph export "${figures}/bin_incarcerated_par_rank_bw_`g'.${img}", replace
}