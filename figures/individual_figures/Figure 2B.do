/* 

This .do file creates Figure 2B. 

As the values in Figure 2B are taken from a large number of other tables, 
they are hard-coded here so that we don't have to read in each table. 

*/ 


clear all
set obs 5


* locals
local symbol_size 1.5

gen race=""
replace race="Black" in 1
replace race="Hispanic" in 2
replace race="American Indian" in 3
replace race="White" in 4
replace race="Asian (US Natives)" in 5


* mean parent rank
gen mean_par_rank=. 
replace mean_par_rank=32.72 in 1 // black
replace mean_par_rank=36.17 in 2 // hispanic
replace mean_par_rank=36.76 in 3 // native american
replace mean_par_rank=57.86 in 4 // white
replace mean_par_rank=63.6 in 5 // asian with native mothers

* mean kfr
gen mean_kfr=. 
replace mean_kfr=34.76 in 1 // black
replace mean_kfr=45.65 in 2 // hispanic
replace mean_kfr=36.73 in 3 // native american
replace mean_kfr=55.65 in 4 // white
replace mean_kfr=58.11 in 5 // asian with native mothers

* slope
gen slope=.
replace slope=0.28 in 1 // black
replace slope=0.26 in 2 // hispanic
replace slope=0.31 in 3 // native american
replace slope=0.32 in 4 // white
replace slope=0.23 in 5 // asian with native mothers

* intercepts
gen icept=.
replace icept=25.43 in 1 // black
replace icept=36.14 in 2 // hispanic
replace icept=25.16 in 3 // native american
replace icept=36.82 in 4 // white
replace icept=43.6 in 5 // asian with native mothers

* compute steady state
gen steady_state=icept/(1-slope)

* mean kfr and par-rank
gen dev = mean_par_rank-steady_state
list dev race
gen x1=.
gen x2=.
gen y1=.
gen y2=.
qui: levelsof race, local(races) 
foreach r in `races' {
	qui: su mean_par_rank if race =="`r'"
	qui: replace y1 = `r(mean)' if race =="`r'" 
	qui: su steady_state if race =="`r'"
	qui: replace x1 = `r(mean)' if race =="`r'" 
	qui: replace y2 = `r(mean)' if race =="`r'" 
	qui: replace x2 = `r(mean)' if race =="`r'"
	}
	
* make graph 
tw (scatter mean_par_rank steady_state if race !="White" & race!="Asian (US Natives)", mlabel(race) /// 
	msymbol(circle_hollow) msize(`symbol_size')) ///
	(pcarrow y1 x1 y2 x2, color(black)) ///
	(scatter mean_kfr steady_state, msymbol(diamond_hollow) msize(`symbol_size') mcolor(maroon)) ///
	(scatter mean_par_rank steady_state if race=="White", mlabel(race) /// 
	msymbol(circle_hollow) msize(`symbol_size') /// 
		mlabpos(9) mcolor(navy) mlabcolor(navy)) ///
	(scatter mean_par_rank steady_state if race=="Asian (US Natives)", mlabel(race) /// 
	msymbol(circle_hollow) msize(`symbol_size') /// 
		mlabpos(12) mcolor(navy) mlabcolor(navy)) ///	
	(function y=x, range(30 65) lpattern(dash) lcolor(gs8)), ///
	ytitle("Empirically Observed Mean Household Income Rank") ///
	xtitle("Steady State Mean Rank") ///
	text(60 63.5 "45 Degree Line", size(small)) xlabel(30(10)65) ///
	ylabel(30(10)65) title(${title_size}) ///
	legend(order(1 "Parents" 3 "Children (born 1978-83)") col(1) ring(0) pos(5) bm(b=3))
graph export "${output}/scatter_kfr_par_rank_steady_state.${img}", replace
