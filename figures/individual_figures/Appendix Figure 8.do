/*

This .do file creates Appendix Figure 8. 

*/


* pick year and free-lunch status
local year 2012
local freelunch 1


* loop through ages 
foreach age in 9 17 {

	* load data
	use "${ext}/naep_math", clear

	keep if year == `year' & age == `age' & freelunch == `freelunch'

	* divide scores by standard deviations
	replace math = math - math_nat
	foreach var in math math_nat {
	replace `var' = (`var'/sd_nat)
}	
	
	* make mean label position
	local lab_pos = `math_nat_line' + 4

	* make shifted xaxis
	gen xaxis = .
	replace xaxis = gender - 0.2 if race == 1
	replace xaxis = gender + 0.2 if race == 2

	* make labels
	gen lab = string(math, "%5.2f")
	if `freelunch' == 1 local frl_lab "Free Lunch"
	if `freelunch' == 0 local frl_lab "Non-Free Lunch"

	* bar graph
	list math xaxis race
	twoway ///
		(bar math xaxis if race == 1, barw(0.3) color(navy) fi(50)) ///
		(bar math xaxis if race == 2, barw(0.3) color(maroon) fi(120)) ///
		(scatter math xaxis if race == 1, ///
			mlab(lab) msymb(none) mlabpos(6) mlabc(black)) ///
		(scatter math xaxis if race == 2, ///
			mlab(lab) msymb(none) mlabpos(6) mlabc(black)) ///
		, ///
		ylabel(-1(0.5)0.5, gmax) ///
		xlabel(1 "Boys" 2 "Girls") ///
		xtitle("") ///
		ytitle("Math Test Score at Age `age'" "In SD From National Average") ///
		legend(order(1 2) lab(1 "White") lab(2 "Black")) ///
		title(${title_size}) 
	graph export "${figures}/bar_naep_math_by_race_gender_`age'.${img}", replace
}
