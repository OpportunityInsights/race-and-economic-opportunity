/*

This .do file creates Appendix Figure 9. 

*/

foreach p in 25 75 {
foreach race in 3 4 5 {

	* race labels	
	if `race' == 3{
		local race_name "Asian"
		local race_label "asian_nativemom"
		local load "bar_nativemom_sequential_controls_asian_p`p'"
		if `p'==25 {
			local ymin -12
			local ymax 2
			local step 2
		}	
		if `p'==75 {
			local ymin -12
			local ymax 2
			local step 2
		}
		local leg_pos 5
	}

	if `race' == 4{
		local race_name "Hispanic"
		local race_label "hisp"
		local ymin -5
		local ymax 10
		local step 5
		local leg_pos 1
		local ylab_pos 12
		replace ylab = 0 if gap < 0
		local control_text = `ymin'-2 
		local load "bar_sequential_controls_hisp_p`p'" 
	}
	
	if `race'== 5 {
		local race_name "American Indian"
		local race_label "natam"
		local ymin -5
		local ymax 20
		local step 5
		local leg_pos 1
		local load "bar_sequential_controls_natam_p`p'" 
	}
	*/

	local ylab_pos 12
	
	* load census code
	use "${final}/`load'", clear
	if `race' == 3 replace ylab = ylab - 1 if ylab < 0
	
	* Male and Female
	twoway ///
		(bar gap xaxis if gender == "M" & order<6, ///
			barw(0.3) fcolor("32 32 32") lcolor("32 32 32") fint(100) ) ///
		(bar gap xaxis if gender == "F" & order<6, ///
			barw(0.3) fcolor("235 102 0") lcolor("235 102 0") fint(100) ) ///
		(scatter ylab xaxis if gender == "M" & order<6, ///
			m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
		(scatter ylab xaxis if gender == "F" & order<6, ///
			m(i) mlabcolor(black) mlabposition(`ylab_pos') mlab(gap)) ///
		, ///
		xlabel(	1 `"None"' ///
				2 "Par. Inc." ///
				3 `""Par Inc." "+Mar. Status ""' ///
				4 `""Par Inc." "+Mar. Status" "+Educ.""' ///
				5 `""Par Inc." "+Mar. Status" "+Educ." "+Partial Wealth" "Proxies""', labcolor(black) tlcolor(black)) ///		
		ylabel(`ymin'(`step')`ymax', gmax gmin format(%4.0f) labcolor(black) tlcolor(black)) ///
		legend(col(1) ring(0) pos(`leg_pos') order(1 "Male" 2 "Female") bm(b=3 t=3)  color(black)) ///
		title(${title_size}) xtitle(" ") ytitle("Mean Rank of White Minus `race_name'",  color(black))
	graph export "${figures}/bar_kir_`race_label'_white_gap_controls_seq_paper_p`p'.${img}", replace
	}
}