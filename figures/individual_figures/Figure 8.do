/* 

This .do file creates Figure 8. 

*/

foreach p in 25 75 {

	* Load sequential controls at individual level 
	use "${final}/bar_sequential_controls_black_p`p'", clear 

	append using "${final}/wealth proxies correction `p'.dta"

	* Load tract-level and block-level  controls 
	append using "${final}/bar_kir_black_white_controls_block_tract_p`p'"

	* Change position for wealth correction 
	replace xaxis = 5.85 if par_inc == 1 & wealth_correction == 1 & gender == "M"
	replace xaxis = 6.15 if par_inc == 1 & wealth_correction == 1 & gender == "F"

	* Change position for tract-level and block-level controls 
	replace xaxis = 6.85 if par_inc == 1 & tract == 1 & gender == "M"
	replace xaxis = 7.15 if par_inc == 1 & tract == 1 & gender == "F"
	replace xaxis = 7.85 if par_inc == 1 & block == 1 & gender == "M"
	replace xaxis = 8.15 if par_inc == 1 & block == 1 & gender == "F"

	replace xaxis = 5.85 if mi(xaxis) & gender == "M"
	replace xaxis = 6.15 if mi(xaxis) & gender == "F"

	* Set labels 
	local race_name "Black"
	local race_label "black"
	local ymin -5
	local ymax 20
	local step 5
	local leg_pos 1
	local ylab_pos 12

	drop if cmdline == `"regress kir kid_mnrty if gender=="M", absorb(par_geo_tract)"'
	drop if cmdline == `"regress kir kid_mnrty if gender=="F", absorb(par_geo_tract)"'
	drop if cmdline == `"regress kir kid_mnrty if gender=="M", absorb(par_geo_block)"'
	drop if cmdline == `"regress kir kid_mnrty if gender=="F", absorb(par_geo_block)"'

	* Male and Female
	twoway ///
		(bar gap xaxis if gender == "M", ///
			barw(0.3) fcolor("32 32 32") lcolor("32 32 32") fint(100) ) ///
		(bar gap xaxis if gender == "F", ///
			barw(0.3) fcolor("235 102 0") lcolor("235 102 0") fint(100) ) ///
		(scatter ylab xaxis if gender == "M", ///
			m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
		(scatter ylab xaxis if gender == "F", ///
			m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
		, ///
		xlabel(	1 `"None"' ///
				2 "Par. Inc." ///
				3 `""Par Inc." "+Mar. Status ""' ///
				4 `""Par Inc." "+Mar. Status" "+Educ.""' ///
				5 `""Par Inc." "+Mar. Status" "+Educ." "+Partial Wealth" "Proxies" "' ///
				6 `""Par Inc." "+Mar. Status" "+Educ." "+Full Wealth" "Control""' ///
				7 `""Par Inc." "+Tract""' ///
				8 `""Par Inc." "+Block""', labcolor(black) tlcolor(black)) ///
			ylabel(`ymin'(`step')`ymax', gmax gmin format(%4.0f) labcolor(black) tlcolor(black)) ///
			legend(col(1) ring(0) pos(`leg_pos') order(1 "Male" 2 "Female") bm(b=3 t=3) color(black)) ///
			title(${title_size}) xtitle(" ") ytitle("Mean Rank of White Minus `race_name'", color(black)) ///
			xsize(12) ///
			xscale(lcolor(black)) yscale(lcolor(black))
		graph export "${figures}/bar_kir_black_white_gap_indiv_tract_block_controls_p`p'.${img}", replace
}