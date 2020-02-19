/*

This .do file creates Appendix Figure 7. 

*/

	
* load data
use "${final}/bar_univariate_controls_black_p25", clear
replace xaxis = xaxis - 1 if xaxis < 2.5

* remove controls for parental income 
drop if par_inc ==1

* race labels
local race 2
if `race' == 2{
	local race_name "Black"
	local race_label "black"
	local ymin -5
	local ymax 20
	local step 5
	local leg_pos 1
	local ylab_pos 12
	replace ylab = 0 if gap < 0
	local control_text = `ymin'-2
}

replace xaxis = xaxis - 2 if xaxis >1

* make scatter
twoway ///
	(bar gap xaxis if gender == "M" & order<6, ///
		barw(0.3) fcolor("32 32 32") fint(100) ) ///
	(bar gap xaxis if gender == "F" & order<6, ///
		barw(0.3) fcolor("235 102 0") lcolor("235 102 0") fint(100) ) ///
	(scatter ylab xaxis if gender == "M" & order<6, ///
		m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
	(scatter ylab xaxis if gender == "F" & order<6, ///
		m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
	, ///
	xlabel(	0 `"None"' ///
			1 `""Marital" "Status""' ///
			2 `""Parent" "Education""' ///
			3 `""Parent" "Wealth""', labsize(small)) ///
	ylabel(`ymin'(`step')`ymax', gmax format(%4.0f)) ///
	legend(col(1) ring(0) pos(`leg_pos') order(1 "Male" 2 "Female") bm(t=3.5)) ///
	title(${title_size}) xtitle(" ") ytitle("Mean Rank of White Minus `race_name'")
graph export "${figures}/bar_kir_`race_label'_white_gap_controls_univar.${img}", replace