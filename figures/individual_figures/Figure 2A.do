/*

This .do file creates Figure 2A. 

*/

* settings
graph set window fontface default
local psize 0.7

* load data
use "${final}/bin_kfr_par_rank", clear

* add mean ranks (from Appendix Table IX)
local mean_rank_white = 55.7
local mean_rank_black = 34.8 
local mean_rank_pooled = 50.0
foreach race in white black pooled {
	local mean_rank_`race' : di %2.1f `mean_rank_`race''
}
	
* generate x variable to make lines touch 0
gen x = _n - 1

* steady state
foreach race in white black{
	regress kfr_`race' par_pctile
	local slope_`race' = _b[par_pctile]
	local int_`race' = _b[_cons]
	local yss_`race': di %4.1f `int_`race'' / (1 - `slope_`race'')
	gen yss_`race' = `yss_`race'' if x <= `yss_`race''
}

* make gap arrows
local gap: di %4.1f `yss_white' - `yss_black'
gen gap_ss_black = `yss_black' if _n == 1
gen gap_ss_white = `yss_white' if _n == 1
gen gap_ss_pos = 18 if _n == 1

* compute gaps and slope of rank rank graph
foreach race in white black {
	reg kfr_`race' par_pctile 
	local natslope_`race' : di %4.2f _b[par_pctile]
	local naticept_`race' : di %4.1f _b[_cons]
	}

* calculate gaps at p25 and p100
foreach p in 25 75 100{
	gen kfr_white_p`p' = kfr_white if par_pctile == `p'
	gen kfr_black_p`p' = kfr_black if par_pctile == `p'
}

* create pline variables
foreach p in 25 75 100{
	gen pline_val_`p' = .
	gen pline`p' = `p' if inrange(par_pctile, 2, 3)
	summ kfr_black_p`p'
	replace pline_val_`p' = `r(mean)' if par_pctile == 2
	summ kfr_white_p`p'
	replace pline_val_`p' = `r(mean)' if par_pctile == 3
}	

* rank-rank + 45-degree + parent steady-state + kids' steady-state + gap
twoway ///
	(scatter kfr_white par_pctile , ///
		msize(*0.5) mcolor(navy) msymbol($sym_white)) ///
	(scatter kfr_black par_pctile , ///
		mcolor(maroon) msize(*0.5) msymbol($sym_black)) ///
	(lfit kfr_white par_pctile , lcolor(navy)) ///
	(lfit kfr_black par_pctile , lcolor(maroon)) ///
	(line x yss_white,  lcolor(black) lpattern(dash)) ///
	(line x yss_black,  lcolor(black) lpattern(dash)) ///
	(line pline_val_25 pline25, lcolor(black) lwidth(medthick)) ///
	(line pline_val_75 pline75, lcolor(black) lwidth(medthick)) ///
	(line pline_val_100 pline100, lcolor(black) lwidth(medthick)) ///
	(pcbarrow gap_ss_pos gap_ss_black gap_ss_pos gap_ss_white, ///
		lcolor(black) mcolor(black)) ///
	(function y = x, range(0 100) lcolor(gs8) lpattern(dash)) ///
	, xtitle("Parent Household Income Rank") ///
	ytitle("Mean Child Household Income Rank", margin(t=3)) ///
	ylabel(0(20)100, gmax) ///
	xlabel(0(20)100)  ///
	legend(order(  ///
			1 "White (Int.: {&alpha}{subscript: w} = `naticept_white'; Slope: {&beta}{subscript: w} = `natslope_white')" ///
			2 "Black (Int.: {&alpha}{subscript: b} = `naticept_black'; Slope: {&beta}{subscript: b} = `natslope_black')") ///   
		col(1) ring(0) pos(4) size(small) bm(r = -4)) ///
	title(${title_size}) ///
	text(49 17 "Diff. at p=25: `gap_p25'", size(small)) ///
	text(40 83 "Diff. at p=75: `gap_p75'", size(small)) ///
	text(77 92 "Diff. at p=100: `gap_p100'", size(small)) ///
	text(-3 `yss_black' "{bf}`yss_black'", size(small) color(maroon)) ///
	text(-3 `yss_white' "{bf}`yss_white'", size(small) color(navy)) ///
	text(13 45 "{bf}Steady-State" "{bf}Gap = `gap'", size(small)) ///
	plotregion(margin(zero))
graph export "${figures}/bin_theory_bw_ss_mean.${img}", replace