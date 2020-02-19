/*
 
This .do file creates Figure 1B. 
 
*/

* set black and white means in initial generation (t)
local x0_black 35
local x0_white 55

* set slope and intercept
local slope 0.35
local int_w 37.5
local int_b 27.5

* make data for line
clear
set obs 100
gen x = _n
gen y_b = `slope' * x + `int_b'
gen y_w = `slope' * x + `int_w'

* steady state
local yss_b: di %4.1f `int_b' / (1 - `slope')
local yss_w: di %4.1f `int_w' / (1 - `slope')
gen yss_b = `yss_b' if x <= `yss_b'
gen yss_w = `yss_w' if x <= `yss_w'
gen yss_b_dot = `yss_b' if _n == 1
gen yss_w_dot = `yss_w' if _n == 1

* make alpha gap arrow values
local gap_pos = 9
gen gap_a_white = `slope' * `gap_pos' + `int_w' if _n == 1
gen gap_a_black = `slope' * `gap_pos' + `int_b' if _n == 1 
gen gap_a_width = `gap_pos' if _n == 1
gen gap_a = gap_a_white - gap_a_black
summ gap_a
local gap_a: di %4.1f `r(sum)'

* make ss gap arrow values
local gap_ss: di %4.1f `yss_w' - `yss_b'
gen gap_ss_black = `yss_b' if _n == 1 
gen gap_ss_white = `yss_w' if _n == 1
gen gap_ss_height = 22 if _n == 1

* make pointing steady-state arrows for blacks
gen ss_w_arrow_y1 = 74 if _n == 1
gen ss_w_arrow_x1 = 50 if _n == 1
gen ss_w_arrow_y2 = 60 if _n == 1
gen ss_w_arrow_x2 = 56 if _n == 1

* make pointing steady-state arrows for whites
gen ss_b_arrow_y1 = 60 if _n == 1
gen ss_b_arrow_x1 = 35 if _n == 1
gen ss_b_arrow_y2 = 45 if _n == 1
gen ss_b_arrow_x2 = 41 if _n == 1

* same slopes + different intercepts
twoway ///
    (function y = x, range(0 100) lcolor(gs8) lpattern(dash)) ///
	(function y = 0.35 * x + 37.5, range(0 100) lcolor(navy)) ///
	(function y = 0.35 * x + 27.5, range(0 100) lcolor(maroon)) ///
	(line x yss_b, lcolor(black) lpattern(dash) lwidth(thin) ) ///
	(line x yss_w, lcolor(black) lpattern(dash) lwidth(thin)) ///
	(scatter yss_b_dot yss_b_dot, color(maroon) msize(medlarge)) ///
	(scatter yss_w_dot yss_w_dot, color(navy) msize(medlarge)) ///
	(pcbarrow gap_a_white gap_a_width gap_a_black gap_a_width , ///
		lcolor(black) mcolor(black)) ///
	(pcbarrow gap_ss_height gap_ss_black gap_ss_height gap_ss_white , ///
		lcolor(black) mcolor(black)) ///
	(pcarrow ss_b_arrow_y1 ss_b_arrow_x1 ss_b_arrow_y2 ss_b_arrow_x2, ///
		lcolor("91 155 213") mcolor("91 155 213")) ///
	(pcarrow ss_w_arrow_y1 ss_w_arrow_x1 ss_w_arrow_y2 ss_w_arrow_x2, ///
		lcolor("91 155 213") mcolor("91 155 213")) ///
	, ///
	ytitle("Mean Child Rank") ///
	xtitle("Parent Rank") ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, gmin gmax nogrid) ///
	xlabel(0(20)100) ///
	legend(off) ///
	title("	", size(large)) ///
	text(3 7 "45{superscript:o}", size(small)color(gs8)) ///
	text(73 90 "Whites", size(small)) ///
	text(53 90 "Blacks", size(small)) ///
	text(79 50 "Steady State" "for Whites", size(small)) ///
	text(65 35 "Steady State" "for Blacks", size(small)) ///
	text(27 50 "Steady-State" "Gap = `gap_ss'", size(small)) ///
	text(13 77 "Relative Mobility: {&beta}{subscript: b} = {&beta}{subscript: w} =  `slope'", size(small)) ///
	text(8 80 "Absolute Mobility: {&alpha}{subscript: b} = `int_b', {&alpha}{subscript: w} = `int_w'", size(small)) ///
	text(-3.5 45 "`yss_b'", size(small)) ///
	text(-3.5 55 "`yss_w'", size(small)) ///
	text(48 10 "Intergen. Gap" "{&Delta}{&alpha} = `gap_a'", size(small)) ///
	plotregion(margin(zero))
graph export "${figures}/bin_kfr_par_rank_theory_bw.${img}", replace
