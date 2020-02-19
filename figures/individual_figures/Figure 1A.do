/*

This .do file creates Figure 1A. 

*/

* set black and white means in initial generation (t)
local x0_black 35
local x0_white 55

* set slope and intercept
local slope 0.35
local int 32.5

* make data for line
clear
set obs 100
gen x = _n
gen y = `slope' * x + `int'

foreach race in black white{
	
	* save kid's mean in the next generation (t + 1)
	local x1_`race': di %4.1f `slope' * `x0_`race'' + `int'
	
	* save dotted lines in each generation
	gen x0_`race' = `x0_`race'' if x <= `x1_`race''
	gen x1_`race' = `x1_`race'' if x <= `x0_`race''
}

* save size of gap in each generation
forval t = 0/1{
	local gap`t': di %4.1f `x`t'_white' - `x`t'_black'
}

* calculate steady state
local yss = `int' / (1 - `slope')
gen yss = `yss' if x <= 50

* generate dot for the steady state
gen yss_dot = `yss' if _n == 1

* make gap arrows
gen gap0_height = 20 if _n == 1 
gen gap0_black = `x0_black' if _n == 1
gen gap0_white = `x0_white' if _n == 1

gen gap1_height = 15 if _n == 1
gen gap1_black = `x1_black' if _n == 1
gen gap1_white = `x1_white' if _n == 1

* make pointing steady-state arrow
gen ss_arrow_y1 = 70 if _n == 1
gen ss_arrow_x1 = 40 if _n == 1
gen ss_arrow_y2 = 52 if _n == 1
gen ss_arrow_x2 = 49 if _n == 1

* same mobility curve
twoway ///
	(function y = `slope' * x + `int', range(0 100) lcolor(navy)) /// mobility 
	(line x x0_black, lcolor(black) lpattern(dash) lwidth(thin)) ///
	(line x x0_white, lcolor(black) lpattern(dash) lwidth(thin)) ///
	(line x1_black x, lcolor(black) lpattern(dash) lwidth(thin)) ///
	(line x1_white x, lcolor(black) lpattern(dash) lwidth(thin)) ///
	(scatter yss yss, mcolor(navy) msize(medlarge)) /// steady-state line 
	(pcbarrow gap0_height gap0_black gap0_height gap0_white, ///
		lcolor(black)  mcolor(black)) ///
	(pcbarrow gap1_black gap1_height gap1_white gap1_height, ///
		lcolor(black)  mcolor(black) ) ///
	(pcarrow ss_arrow_y1 ss_arrow_x1 ss_arrow_y2 ss_arrow_x2, ///
		lcolor("91 155 213") mcolor("91 155 213")) ///
	(function y = x, range(0 100) lcolor(gs8) lpattern(dash)) /// 45 degree 
	, ///
	ytitle("Mean Child Rank") ///
	xtitle("Parent Rank") ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, gmin gmax nogrid) ///
	xscale(range(0 100)) ///
	xlabel(0(20)100) ///
	legend(off) ///
	title(" ", size(large)) ///
	text(73 40 "Steady State", size(small)) ///
	text(10 85 "Relative Mobility: {&beta} = `slope'", size(small)) ///
	text(5 85 "Absolute Mobility: {&alpha} = `int'", size(small)) ///
	text(-2.5 `x0_black' "`x0_black'", size(small)) ///
	text(-2.5 `x0_white' "`x0_white'", size(small)) ///
	text(`x1_black' -3 "`x1_black'", size(small)) ///
	text(`x1_white' -3 "`x1_white'", size(small)) ///
	text(3 7 "45{superscript:o}", size(small)color(gs8)) ///
	text(26 45 "Gap in Gen. {it}t" "= `gap0'", size(small)) ///
	text(55 18 "Gap in Gen. {it}t+1 = `gap1'", size(small)) ///
	plotregion(margin(zero))
graph export "${figures}/bin_kfr_par_rank_theory_pooled.${img}", replace