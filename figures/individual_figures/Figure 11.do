/*

This .do file creates Figure 11. 

*/

* ------------------------------------------------------------------------------
* Load data 
* ------------------------------------------------------------------------------

* load correlations in low-poverty tracts 
use "${final}/sig_corr_male_lowpov_mskd", clear 
order covariate

* keep correlations only
replace covariate = regexr(covariate, " corr", "")
drop if regex(covariate, " se")
drop if covariate == ""

* rename correlations
renvars kir*, presub("kir" "corr_kir")
renvars black*, presub("black_white_gap" "corr_kir_gap_male")

* destring
destring corr*, replace float

* pick covariates 
local covs ///
	poor_share2000 hhinc_mean2000 emp_rate_pooled_pooled ///
	gsmn_math_g3_2013 gsmn_math_g8_2013 total_rate_suspension ///
	nohs_share2000 college_share2000 ///
	rent_twobed2015 share_owner2010  ///
	married_share2000 singleparent_share2000 ///
	has_dad_black_pooled_p25 has_dad_white_pooled_p25 ///
	has_mom_black_pooled_p25 has_mom_white_pooled_p25 ///
	median_value_black2000 median_value_white2000 ///
	poor_share_black2000 poor_share_white2000

* tag variables to graph
gen tag = .
foreach cov of local covs{
	replace tag = 1 if regex(covariate, "`cov'")
}
keep if tag == 1 | covariate_name == ""
drop tag

* drop variables that have different signs for corr_kir_black_male_p25 v. p75
gen sign_tag = .
replace sign_tag = 1 if ///
	(corr_kir_black_male_p25 > 0 & corr_kir_black_male_p75 > 0) | ///
	(corr_kir_black_male_p25 < 0 & corr_kir_black_male_p75 < 0) 
keep if sign_tag == 1

* flip the sign if corr_kir_black_male_p25 is negative
gen flip_tag = .
replace flip_tag = 1 if corr_kir_black_male_p25 < 0
replace corr_kir_gap_male_p25 = -1 * corr_kir_gap_male_p25 if flip_tag == 1

* flip the sign of corr_gap_male_p25 (so that gap = white - black)
replace corr_kir_gap_male_p25 = -1 * corr_kir_gap_male_p25

* sort by size of gap
gsort - corr_kir_gap_male_p25
gen order = _n

* generate labels
gen cov_label = ""
replace cov_label = "Share College Grad."		if regex(covariate, "college")
replace cov_label = "Employment Rate"			if regex(covariate, "emp_rate")
replace cov_label = "Mean 3rd Grade Math Score" if regex(covariate, "gsmn_math_g3")
replace cov_label = "Mean 8th Grade Math Score" if regex(covariate, "gsmn_math_g8")
replace cov_label = "Black Father Presence (p25)" if regex(covariate, "has_dad_black")
replace cov_label = "White Father Presence (p25)" if regex(covariate, "has_dad_white")
replace cov_label = "Black Mother Presence (p25)" if regex(covariate, "has_mom_black")
replace cov_label = "White Mother Presence (p25)" if regex(covariate, "has_mom_white")
replace cov_label = "Mean Household Income"		if regex(covariate, "hhinc_mean")
replace cov_label = "Implicit Bias for Whites"	if regex(covariate, "iat_total_white")
replace cov_label = "Implicit Bias for Blacks"	if regex(covariate, "iat_total_black")
replace cov_label = "Share Married"				if regex(covariate, "married")
replace cov_label = "Median Black Home Value"	if regex(covariate, "median_value_black")
replace cov_label = "Median White Home Value"	if regex(covariate, "median_value_white")
replace cov_label = "Share HS Graduate" 		if regex(covariate, "nohs_share")
replace cov_label = "Share Above Poverty Line" 	if regex(covariate, "poor_share2000")
replace cov_label = "Share Black Above Poverty Line" if regex(covariate, "poor_share_black")
replace cov_label = "Share White Above Poverty Line" 	if regex(covariate, "poor_share_white")
replace cov_label = "Median Rent (2BR)"			if regex(covariate, "rent")
replace cov_label = "Share Homeowners"			if regex(covariate, "share_owner")
replace cov_label = "Share Two Parents"			if regex(covariate, "singleparent")
replace cov_label = "Fraction Not Suspended from School"	if regex(covariate, "suspension")
replace cov_label = "Share Black Insured (18-64)" if regex(covariate, "share_insured_18_64_black")
replace cov_label = "Share White Insured (18-64)" if regex(covariate, "share_insured_18_64_white")
replace cov_label = "Share Insured (18-64)" if regex(covariate, "share_insured_18_64_all")
replace cov_label = "White Median Household Income" if regex(covariate, "med_hhinc_white")
replace cov_label = "Black Median Household Income" if regex(covariate, "med_hhinc_black")
replace cov_label = cov_label + "  "

* replace mother presence as mother absence
replace cov_label = "Black Mother Absence (p25)  " if ///
	cov_label == "Black Mother Presence (p25)  " 
	
* make graph
drop order
* sort by size of gap
gsort - corr_kir_gap_male_p25
gen order = _n
* label order
labmask order, values(cov_label)
qui: su order
local num_cov = `r(max)'
twoway ///
	(bar corr_kir_gap_male_p25 order, horizontal color(navy) barwidth(0.8)) ///
	, ///
	legend(off) ///
	xtitle("Correlation with White Minus Black Rank for Men with Parents at p=25", just(right)) ///
	ytitle("") ///
	ylabel(1(1)`num_cov', valuelabel angle(horizontal) nogrid labsize(small)) ///
	xlabel(-0.15 "-0.15" -0.1 "-0.1" -0.05 "-0.05" 0 "0" 0.05 "0.05" 0.1 "0.1" 0.15 "0.15") ///
	title(${title_size})
graph export "${output}/bar_corr_kir_gap_covar_pos.${img}", replace