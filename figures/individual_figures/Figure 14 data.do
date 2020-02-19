/*

This .do file rearranges the data for graphing in Figure 14. 

*/

* ------------------------------
* Setting up
* ------------------------------

* Read in the data 
use "${final}/tract_race_gender_mskd", clear


* Covariates
merge 1:1 tract county state using /// 
	"${ext}/tract_covars", nogen keep(match) /// 
	keepusing(poor_share2000)

local wt all 
local wt_var kir 

* ------------------------------
* Add information for graph
* ------------------------------

* Want to weight by the number of low-income black kids
foreach race in white black {
	gen low_inc_`race'_male_n = (1-par_rich_`race'_male)*kir_`race'_male_n

	*round to the nearest integer to use freq weights
	replace low_inc_`race'_male_n = round(low_inc_`race'_male_n)
}
		
* Data for bar charts 
g lowpov = poor_share2000<.1 if poor_share2000<.
foreach race in black white {
	g highhasdad_`race'50 = has_dad_`race'_pooled_p25>0.5 /// 
		if has_dad_`race'_pooled_p25<.
	tab lowpov highhasdad_`race'50 [w=`wt_var'_`race'_male_n], cell nof matcell(`race')
}
			
gen order = _n
gen race = . 
foreach i of numlist 1(2)7 {
	replace race = 1 in `i'
	local u=`i'+1
	replace race = 2 in `u'
}
gen has_dad = . 
foreach i of numlist 1(1)2 5(1)6 {
	replace has_dad = 1 in `i'
	local u=`i'+2
	replace has_dad = 2 in `u' 
}
gen pov = "high_pov"
replace pov = "low_pov" if order>4 & order <=8
gen xaxis = .
replace xaxis = 1.1 in 2
replace xaxis = 1.7 in 4 
replace xaxis = 2.55 in 6 
replace xaxis = 3.15 in 8
replace xaxis = 4.6 in 1
replace xaxis = 5.2 in 3
replace xaxis = 6.05 in 5
replace xaxis = 6.65 in 7

matrix list black
foreach race in black white {
	forval row=1/2 {
		forval column=1/2 {
			scalar `race'_`row'_`column' = `race'[`row',`column']
				}
			}
		scalar total_`race'= `race'_1_1 + `race'_1_2 + `race'_2_1 + `race'_2_2
		forval row=1/2 {
			forval column=1/2 {
				scalar sh_`race'_`row'_`column' =`race'_`row'_`column'/total_`race'
				di sh_`race'_`row'_`column'
			}
		}
}

gen value = . 
replace value = sh_white_1_1 in 1 
replace value = sh_white_1_2 in 3
replace value = sh_white_2_1 in 5
replace value = sh_white_2_2 in 7 
replace value = sh_black_1_1 in 2 
replace value = sh_black_1_2 in 4
replace value = sh_black_2_1 in 6
replace value = sh_black_2_2 in 8 
replace value = value*100

* Add value labels at the bottom
gen val_lab=round(value, 0.1) if !missing(xaxis)
format val_lab %4.1f

*all labels at a certain height
local lab_ht_bottom 6.4
gen val_lab_ht=`lab_ht_bottom' if !missing(xaxis)

*the ones where this is < ht of bar should be white, else black
gen lab_color_white=(val_lab>val_lab_ht) if !missing(xaxis)

*make the vertical lines
sort xaxis
local lab_ht 78

gen xline=.
gen yline=.
local i=0
gen line_tag=.
gen bar_line_above=.
foreach n in 1 2 5 6 {
	local ++i
	local n2=`n'+2

	replace line_tag=`i' if inlist(_n,`n',`n'+2)
	summ xaxis if _n==`n'
	replace xline=`r(mean)' if inlist(_n,`n',`n'+2)
	summ value if _n==`n'
	local val `r(mean)'
	
	if `val'>`lab_ht_bottom' {
		replace bar_line_above=1 if inlist(_n,`n',`n2')
	}

else if `val'<=`lab_ht_bottom' {
	replace bar_line_above=0 if inlist(_n,`n',`n2')
	}

	*top height of line
	replace yline=`lab_ht'-3.5 if _n==`n'
	
	*bottom height of line
	summ bar_line_above if _n==`n'+2
	if `r(mean)'==0 in `n2' {
	replace yline=`lab_ht_bottom'+1.5 if _n==`n'+2
	}
	if `r(mean)'==1 in `n2' {
		replace yline=`val'+1.5 if _n==`n'+2
	}

}

* ------------------------------
* Export 
* ------------------------------
keep race has_dad pov xaxis value val_lab val_lab_ht lab_color_white xline yline line_tag bar_line_above
chopper, vars(value yline) 
drop if missing(race)
save "${final}/bar_has_dad_by_pov_wt`wt'", replace