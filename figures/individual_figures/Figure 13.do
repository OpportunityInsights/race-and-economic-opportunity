/*

This .do file creates Figure 13. 

*/

* load data
use "${final}/hs_standard_mskd", clear
keep kid_race yvar age coeff

* scatter
foreach var in kir30 incarcerated {
	if "`var'" == "kir30" {
		local ytitle "Coefficient on Predicted Rank in Destination CZ"
		}
	if "`var'" == "incarcerated" {
		local ytitle "Coefficient on Predicted Incarceration Rate in Destination CZ"
		}
	local col1 navy
	local col2 maroon
	preserve
	keep if yvar =="`var'"
	forvalues race = 1/2{
		reg coeff age if age <= 23 & kid_race == `race'
		local slope_bel23_`race' : di %4.3f _b[age]
		local se_slope_bel23_`race' : di %4.3f _se[age]
		predict bel23_`race' if age <= 23 & kid_race == `race'
		sum coeff if age > 23 & kid_race == `race'
		local mean_24plus_`race' = `r(mean)'
		gen mean_24plus_`race' = `r(mean)' if age > 23 & kid_race == `race'
		local di_mean_24plus_`race' :  di %4.3f =`mean_24plus_`race''
	}		
		
	local race = 0
	
	foreach racename in white black{
		local ++race 
		if "`var'" == "kir30" {
			local ydelta = `mean_24plus_`race'' + 0.1
			sum bel23_`race' if age == 10, meanonly
			local yslope = `r(mean)' - 0.22
		}
		if "`var'" == "incarcerated" {
			local ydelta = 0.17
			local yslope = 0.25
		}
		
		* format coefficient
		format coeff %4.1f
		
		* scatter
		twoway ///
			(scatter coeff age if kid_race == `race', color(`col`race'') ms(${sym_`racename'})) ///
			(line bel23_`race' age , lcolor(`col`race'')) ///
			(line mean_24plus_`race' age, lcolor(`col`race'')), ///
			title(${title_size}) ///
			yline(`mean_24plus_`race'', lp(dash) lc(gray)) ///
			yscale(range(0)) ylab(0 "0" .2 "0.2" .4 "0.4" .6 "0.6" .8 "0.8") ///
			ytitle("`ytitle'", just(right)) ylab(,gmax) ///
			xtitle("Age of Child when Parents Move") xlabel(5(5)30) ///
			xline(23.5, lpattern(dash) lc(gray)) ///
			legend(off) ///
			text(`yslope' 10 "Slope: `slope_bel23_`race''" "            (`se_slope_bel23_`race'')") ///
			text(`ydelta' 27 "{&delta}: `di_mean_24plus_`race''")
			graph export "${figures}/bin_hockey_male_`var'_2lines_`racename'.${img}", replace	
	}
	restore
}