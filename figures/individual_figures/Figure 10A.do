/*

This .do file produces Figure 10A. 

*/

* Define categories of variables
local economy poor_share2000 ///
	hhinc_mean2000 emp_rate_pooled_pooled 
local school gsmn_math_g3_2013 gsmn_math_g8_2013 total_rate_suspension
local education nohs_share2000 college_share2000
local housing rent_twobed2015 share_owner2010 
local family married_share2000 singleparent_share2000
local health share_insured_18_64_all

* Set parameters
local outcomes kir_white_male kir_black_male
local covars `economy' "" `school' ""  ///
		`education' "" `housing'  "" `family' "" `health' 
local parrank 25
local symbsize medium
local textsize small
local version 

* Load data 
use "${final}/sig_corr_male_mskd", clear 

rename *_gap* *_m_gap*
gen std_err = regexm(covariate_name," SE")
replace covariate = regexr(covariate, " se", "")
replace covariate_name = regexr(covariate_name, " SE", "")
replace covariate = regexr(covariate, " corr", "")
replace covariate_name = regexr(covariate_name, " corr", "")
reshape wide kir* *gap*, i(covariate) j(std_err) 
rename *0 *
rename *1 *_se

* Generate x and y axes
ds covariate*, not
foreach outcome of local outcomes	{
	foreach p of local parrank		{
		local var `outcome'_p`p'
		destring(`var'), replace
		replace `var'_se = regexr(`var'_se, "\(", "")
		replace `var'_se = regexr(`var'_se, "\)", "")
		destring(`var'_se), replace
		gen neg_`var' = `var' < 0
		replace `var' = abs(`var')
	}
}
local i = 0
local yline
gen yaxis = .
foreach word of local covars{
	local i = `i' + 2
	replace yaxis = `i' if covariate == "`word'"
	if "`word'" == "" {
		local yline `yline' `i'
	}
}

* label covariates
gen label = regexr(covariate_name, " \(20[0-9][0-9]\)","")
replace label = regexr(label, " \(2008-2012\)","")
replace label = "Share Less Than HS Educated" if label == "Share Less Than HS Educatued"
replace label = "Share Manufacturing" if label == "Share Working in Manufacturing"
replace label = "Mean Household Income" if label == "Mean Household Income"
replace label = "Share No Insurance" if label == "Share without Health Insurance"
replace label = "Divorce Rate" if label == "Share Divorced"
replace label = "Share Kids" if label == "Share of Population Younger than 18"
replace label = "Share Foreigners" if label == "Share Foreign Born"
replace label = "Share Adults Insured" if label == "Share Adults 18-64 Insured"
replace label = "Share College Grad." if label == "Share College Educated"
replace label = "Median Rent (2BR)" if label == "Median 2 Bedroom Rent"
replace label = "Share Homeowners" if label == "Share who Own Home"
replace label = "Implicit Bias" if label == "IAT Score for White"
replace label = "Google Racial Animus Index" if label == "Racial Animus Index"
replace label = "GSS Racial Bias Index" if label == "Interracial Marriage Attitudes"
replace label = "Mean 3rd Grade Math Score" if label == "3rd Grade Math Score"
replace label = "Mean 8th Grade Math Score" if label == "8th Grade Math Score"

* Inverse labeling
replace label = "Share Two-Parent" if label == "Share Single Parents"
replace label = "Share Above Poverty Line" if label == "Share in Poverty"
replace label = "Share High School Grad." if label == "Share Less Than HS Educated"
replace label = "Share HS Students Not Suspended" if label == "HS Suspension Rate"

levelsof yaxis, local(covtoplot)
labmask yaxis if yaxis !=., values(label)

* Make corrplots
foreach p of local parrank	{
	local var1 kir_white_male_p`p' 
	local var2 kir_black_male_p`p' 
	twoway scatter yaxis `var1' if `var1'>0, ///
		mcolor(green) msymbol(circle) msize(`symbsize') || ///
		scatter yaxis `var2' if `var2'>0, ///
		mcolor(green) msymbol(circle_hollow) msize(`symbsize') || ///
		ylabel(`covtoplot', value angle(0) nogrid labsize(`textsize')) ///
		ytitle("") title(${title_size}) ///
		yline(`yline', lpattern(dash)	lcolor(gs10)) /// 
		xtitle("Correlation") ///
		yscale(reverse) ///
		legend(off) xlabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6", grid) xsize(7) ysize(5)
	graph export "${figures}/corrplot_paper_kirmale_p`p'.${img}", replace
}