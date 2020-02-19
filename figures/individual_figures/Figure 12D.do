/*

This .do file creates Figure 12D. 

*/

* Choose if gaps should be displayed for predicted values or dots
local gap predict

* Load data 	
use "${final}/bin_kir_ewrk_black_male_female_hasdad", clear 
	
* compute predicted values
foreach g in male female {
	qui: su slope_`g' 
	local slope_`g' : di %4.3f `r(mean)'
	qui: su se_`g' 
	local se_`g' : di %4.3f `r(mean)'
	reg kir_ewrk_black_`g'_p25 has_dad_black_pooled_p25
	predict pred_kir_ewrk_black_`g'_p25
	local slope_`g' : di %3.2f _b[has_dad_black_pooled_p25]
	local icpt_`g' : di %3.2f _b[_cons]
}
	
* compute gaps for selected bins (either for dots or for predicted values)
foreach bin in 1 50{ 
	local n = 1
	gen yax_`bin' = .
	foreach g in male female{
		local n = `n'+1
		if "`gap'" == "predict" local prefix "pred_"
		if "`gap'" == "dots" local prefix ""
		sum `prefix'kir_ewrk_black_`g'_p25 if _n == `bin'
		local kir_ewrk_`g'_`bin' = `r(mean)'
		replace yax_`bin' = `kir_ewrk_`g'_`bin'' if _n == `n'
	}
	local gap_`bin' : di %3.1f ///
		`=abs((`kir_ewrk_female_`bin'')-(`kir_ewrk_male_`bin''))'
	di "gap_`bin': `gap_`bin''"
	sum has_dad_black_pooled_p25 if _n == `bin', meanonly
	gen xax_`bin' = `r(mean)'
	}


* define yvar specific locals 
local ytitle "Percentage of Children Working "
local text1 "84 21.0"
local text2 "87 72.5"
local text_slope1 "70 69.0"
local text_slope2 "75.5 69.0"
local legloc 4
local ymin 75
local ymax 95
local step 5

* make graphs
twoway (scatter kir_ewrk_black_male_p25 has_dad_black_pooled_p25, m(${sym_white}) mcolor(black)) ///
	(scatter kir_ewrk_black_female_p25 has_dad_black_pooled_p25, m(${sym_black}) mcolor("235 102 0")) ///
	(lfit kir_ewrk_black_male_p25 has_dad_black_pooled_p25, color(black)) ///
	(lfit kir_ewrk_black_female_p25 has_dad_black_pooled_p25, color("235 102 0")) ///
	(line yax_1 xax_1, lc(black)) (line yax_50 xax_50, lc(black)), ///
	text(`text1' "Diff: `gap_1'", size(small)) ///
	text(`text2' "Diff: `gap_50'", size(small)) ///
	ylabel(`ymin'(`step')`ymax', gmax gmin) ///
		legend(order(1 "Black Male; Slope: `slope_male' (`se_male')" ///
				 2 "Black Female; Slope: `slope_female' (`se_female')") ///
			pos(`legloc') ring(0) col(1) bmargin(b=3)) ///
	xtitle("Percentage of Black Children in Low-Income (p25) Families whose Father is Present", just(right)) ///
	ytitle("`ytitle'") title(${title_size}) xscale(range(10 80)) xlabel(20(20)80)
graph export "${figures}/bin_kir_ewrk_black_male_female_hasdad.${img}", replace