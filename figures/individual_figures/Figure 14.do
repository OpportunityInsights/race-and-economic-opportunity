/*

This .do file creates Figure 14. 

*/

local lab_ht 80

foreach wt in all {
	use "${final}/bar_has_dad_by_pov_wt`wt'", clear 
	
	* make bar graph
	local xtext1 2.125
	local xtext2 5.625
	twoway	(bar value xaxis if race==1, barw(0.5) color(navy) fi(50)) ///
		(bar value xaxis if race==2, barw(0.5) color(maroon) fi(50)) ///
		(bar value xaxis if race==1 & has_dad == 1, barw(0.5) color(navy) fi(120)) ///
		(bar value xaxis if race==2 & has_dad == 1, barw(0.5) color(maroon) fi(120)) ///
		(scatter val_lab_ht xaxis if lab_color_white==1, msymbol(i) mlab(val_lab) mlabpos(0) mlabcolor(white)) ///
		(scatter val_lab_ht xaxis if lab_color_white==0, msymbol(i) mlab(val_lab) mlabpos(0) mlabcolor(black)) ///
		(line yline xline if line_tag==1, lcolor(gs8)) ///
		(line yline xline if line_tag==2, lcolor(gs8)) ///
		(line yline xline if line_tag==3, lcolor(gs8)) ///
		(line yline xline if line_tag==4, lcolor(gs8)) ///
		,legend(off) ///
		ytitle("Share of Children in Neighborhood Type (%)") ylabel(0(10)78, nogrid) ///
		xlabel(1.3 "High Poverty" 2.85 "Low Poverty" 4.9 "High Poverty" 6.35 "Low Poverty") ///
		text(-13 `xtext1' "Black Children") ///
		text(-13 `xtext2' "White Children") ///
		title(${title_size}) xtitle(" ", size(vlarge)) xscale(range(0.5 7)) ///
		text(`lab_ht' 1.1 "Low" "Father" "Presence", size(small)) ///
		text(`lab_ht' 1.7 "High" "Father" "Presence", size(small)) ///
		text(`lab_ht' 4.6 "Low" "Father" "Presence", size(small)) ///
		text(`lab_ht' 5.2 "High" "Father" "Presence", size(small))
		graph export "${figures}/bar_has_dad_by_pov_wt`wt'.${img}", replace
}