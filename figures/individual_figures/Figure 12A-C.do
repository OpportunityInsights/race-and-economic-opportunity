/*

This .do file creates Figure 12A-C. 

*/ 

* local varlist variables to be plotted
local varlist kir kir_ewrk kid_jail

* choose if gaps should be displayed for predicted values or dots
local gap predict

* local gender
local gender male 

local xvar has_dad_black_pooled_p25
foreach yvar in `varlist' {
	use "${final}/bin_`yvar'_hasdad", clear 
	
	* save standard errors of slope
	foreach race in white black {
		qui: su se_`race' 
		local se_`race' : di %4.3f `r(mean)'
	}
		                                                                        	
	* compute slope predicted values
	foreach race in white black {
		reg `yvar'_`race'_`gender'_p25 has_dad_black_pooled_p25
		predict pred_`yvar'_`race'_`gender'_p25
		local slope_`race' : di %3.2f _b[has_dad_black_pooled_p25]
		local icpt_`race' : di %3.2f _b[_cons]
	}
	
	* compute gaps for selected bins (either for dots or for predicted values)
	foreach bin in 1 50{ 
		local n = 1
		gen yax_`bin' = .
		foreach race in white black{
			local n = `n'+1
			if "`gap'" == "predict" local prefix "pred_"
			if "`gap'" == "dots" local prefix ""
			sum `prefix'`yvar'_`race'_`gender'_p25 if _n == `bin'
			local `yvar'_`race'_`bin' = `r(mean)'
			replace yax_`bin' = ``yvar'_`race'_`bin'' if _n == `n'
		}
		local gap_`bin' : di %3.1f ///
			`=abs((``yvar'_white_`bin'')-(``yvar'_black_`bin''))'
		di "gap_`bin': `gap_`bin''"
		sum `xvar' if _n == `bin', meanonly
		gen xax_`bin' = `r(mean)'
	}
	
	* define yvar specific locals 
	if "`yvar'" =="kir" {
		local ytitle "Mean Child Individual Income Rank"
		local text1 "45.0 19.0"
		local text2 "46.5 74.0"
		local text_slope1 "51.5 70.0"
		local text_slope2 "41.5 70.0"
		local legloc 1
		local ymin 40
		local ymax 54
		local step 2
		}
	if "`yvar'" =="kir_ewrk" {
		local ytitle "Percentage of Children Working"
		local text1 "83 19.0"
		local text2 "85 74.0"
		local text_slope1 "70 69.0"
		local text_slope2 "75.5 69.0"
		local legloc 4
		local ymin 78
		local ymax 90
		local step 2
		}
	if "`yvar'" =="kid_jail" {
		local ytitle "Percentage of Children Incarcerated"
		local text1 "7.0 20.0"
		local text2 "5 73.0"
		local text_slope1 "4 60.0"
		local text_slope2 "9 61.0"
		local legloc 1
		local ymin 2
		local ymax 12
		local step 2
		}	
	
	if "`gender'" == "male" local gender_label "Male" 
	if "`gender'" == "female" local gender_label "Female" 

	* make graphs
	tw (scatter `yvar'_white_`gender'_p25 has_dad_black_pooled_p25, m(${sym_white})) ///
		(scatter `yvar'_black_`gender'_p25 has_dad_black_pooled_p25, m(${sym_black})) ///
		(lfit `yvar'_white_`gender'_p25 has_dad_black_pooled_p25, color(navy)) ///
		(lfit `yvar'_black_`gender'_p25 has_dad_black_pooled_p25, color(maroon)) ///
		(line yax_1 xax_1, lc(black)) (line yax_50 xax_50, lc(black)), ///
		text(`text1' "Diff: `gap_1'", size(small)) ///
		text(`text2' "Diff: `gap_50'", size(small)) ///
		ylabel(`ymin'(`step')`ymax', gmax) ///
		legend(order(1 "White; Slope: `slope_white' (`se_white')" ///
				 2 "Black; Slope: `slope_black' (`se_black')") ///
			pos(`legloc') ring(0) col(1) bmargin(t=3 b=3 r=-3)) ///
		xtitle("Percentage of Black Children in Low-Income (p25) Families whose Father is Present", just(right)) ///
		ytitle("`ytitle'") title(${title_size}) xscale(range(10 80)) xlabel(20(20)80)
	graph export "${figures}/bin_`yvar'_hasdad.${img}", replace
	
}