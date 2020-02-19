/*

This .do file creates Appendix Figures 14-15. 
The values displayed in the figure are taken from the results that are read in. 
For ease of reading, some of the values are hard-coded into the .do file. 

*/

local def white_minus_black

*loop over parent percentile and gender
foreach p in 25 75 {
	foreach gender in male female {
	
		* set values for numbers in chart manually
		if "`p'" == "25" & "`gender'" == "male"{
			local trueless0 11.8
			local frac_less_0_zscore 1.3
			local sig_sd_round 3.4
			local tot_sd_round 6.6
		}
		
		if "`p'" == "25" & "`gender'" == "female"{
			local trueless0 72.5
			local frac_less_0_zscore 83.6
			local sig_sd_round 3.0
			local tot_sd_round 5.9
		}
	
		if "`p'" == "75" & "`gender'" == "male"{
			local trueless0 15.2
			local frac_less_0_zscore 1.9
			local sig_sd_round 4.4
			local tot_sd_round 9.8
		}
	
		if "`p'" == "75" & "`gender'" == "female"{
			local trueless0 60.8
			local frac_less_0_zscore 69.0
			local sig_sd_round 4.3
			local tot_sd_round 9.0
		}
	
		*percentile specific specs
		if `p'==25	local max 0.40
		if `p'==75	local max 0.40
		use "${final}/hist_white_black_gap_histogram_`gender'_p`p'.dta", clear

		* change from white-black gap to black-white gap
		if "`def'" == "black_minus_white" {
			foreach var in x white_black_gap2 {
				qui: replace `var' = (-1)*`var'
				}
			}
		
		* mean gap 
		egen max=max(normal_gap_sig_sd)
		gen match = max==normal
		qui: su white_black_gap2 if match ==1, d
		local mi = `r(min)'
		local ma = `r(max)' 
		local mean_gap = ((`mi'+`ma')/2)*100
		local mean_gap : di %4.1f `mean_gap'
		
		* local barwidth 
		qui: su width
		local width=`r(mean)'
					
		* make graph 	
		twoway (bar h x, barw(`width') color(khaki)), ///
			legend(col(1) ///
				order(1 "Observed Distribution"  /// 
					2 "Normal Dist. w/ Signal SD") ///
					ring(0) pos(2) bm(t=5)) ///
			ytitle("Density") ///
			xlabel(-.4 "-40" -.2 "-20" 0 "0" .2 "20" .4 "40") ///
			ylabel(0 "0" 2 ".02" 4 ".04" 6 ".06" 8 ".08", gmax) ///
			xscale(range(-.45 .45)) ///
			text(1.4 -0.3 "Raw Fraction < 0: `trueless0'%" ///
				"Signal Fraction < 0: `frac_less_0_zscore'%" ///
				"Mean Gap: `mean_gap' pctiles", size(small)) ///
			xtitle("White Minus Black Rank Given Parents at `p'th Percentile") ///
			title(${title_size}) xline(0, lcolor(red))	
		graph export "${figures}/histogram_black_white_gap_`gender'_p`p'.${img}", replace	
	}
}