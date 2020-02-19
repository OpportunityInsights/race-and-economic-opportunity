/*

This .do file creates Appendix Figure 4. 

*/

* loop over parent decile of interest
foreach par_dec in 3 8 {

	* load data 
	use "${final}/bar_occ_by_gender_pardec`par_dec'", clear
	
	* compute fraction to be reshuffled
	qui: gen diff = abs(frac1-frac2)
	foreach gender in F M {
		su diff if gender =="`gender'" 
		local reshuffle_`gender' = round((`r(sum)'/2),0.1)
		}
	
	*Graph separately for men and women 
	foreach gender in F M {
		if "`gender'" == "F" {
			local pos_title "18 113"
			local title "Female"
			}
		if "`gender'" == "M" {
			local pos_title "12 113"
			local title "Male"
			}
		graph hbar (asis) frac1 frac2 if gender == "`gender'", ///
			over(kid_1occ, relabel( ///
				1 "Business" ///
				2 "STEM" ///
				3 "Social Service" ///
				4 "Healthcare" ///
				5 "Food/Service" ///
				6 "Administrative" ///
				7 "Farming/Construction" ///
				8 "Maintenance/Repair" ///
				9 "Machine Operation" ///
				10 "Transportation" ///
				)) ///
			title(${title_size}) ytitle("Pct. of Workforce") ///
			ylab(0(10)30, gmax) ///
			legend(rows(1) order(1 "White" 2 "Black")) ///
			text(`pos_title' "`title'", size(large)) ///
			bar(1, fcolor(navy)) bar(2, fcolor(maroon%30)) ///
			name(`gender'_occ, replace) ///
			graphr(m(t=10)) ///
			note(" " "Mismatch Fraction = `reshuffle_`gender''%", size(medsmall))
		}

	* combine graph and export	
	grc1leg M_occ F_occ
	graph export "${figures}/bar_occ_by_gender_pardec`par_dec'.${img}", replace
}