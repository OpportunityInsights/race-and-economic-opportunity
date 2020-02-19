/*

This .do file rearranges the data for Appendix Figures 14-15. 

*/

*loop over parent percentile
foreach p in 25 75 {
	foreach gender in male female {
	
	*gender specific specs
	if "`gender'"=="male" {
		local sign - 
		}
	if "`gender'"=="female" {
		local sign -
	}
	
	*percentile specific specs
	if `p'==25 {
		local min 20
	}
	if `p'==75 {
		local min 40
	
	}
	
	* load data 
	use "${final}/tract_race_gender_mskd", clear
	
	* make gap
	gen white_black_gap = kir_white_`gender'_p`p' - kir_black_`gender'_p`p'
	replace white_black_gap = white_black_gap * 100
	keep if kir_white_`gender'_n>50
	keep if kir_black_`gender'_n>50
	keep if white_black_gap>-40

	*get the mean gap
	summ white_black_gap [w = kir_black_`gender'_n]
	local gap_mean: di %3.1f `r(mean)'

	*get the fraction below 0
	gen less_0 = (white_black_gap < 0)
	replace less_0 = . if missing(white_black_gap)
	summ less_0 [w = kir_black_`gender'_n]

	local pct_less_0 = `r(mean)' * 100
	local pct_less_0 = string(`pct_less_0', "%5.1f")

	*noise variance
	foreach race in black white {
		gen var_kir_`race'_`gender'_p`p' = kir_`race'_`gender'_p`p'_se^2
		replace var_kir_`race'_`gender'_p`p'=. if ///
			kir_black_`gender'_p`p' ==. | kir_white_`gender'_p`p' ==.
		su var_kir_`race'_`gender'_p`p' /// 
			[w=kir_black_`gender'_n]
		local noise_var_`race' = `r(mean)'
		}
	local noise_var_gap = `noise_var_black' + `noise_var_white' 
	di `noise_var_gap'

	*total variance gap and mean gap
	gen white_black_gap2 = white_black_gap/100
	su white_black_gap2 [w=kir_black_`gender'_n]
	local tot_var =`r(Var)'
	local mean_gap =`r(mean)'

	local tot_var_gap = `tot_var'
	di `tot_var_gap'

	*signal sd gap
	local sig_sd = sqrt(`tot_var_gap' -`noise_var_gap')
	local sig_sd_round = round(sqrt(`tot_var_gap' -`noise_var_gap'),0.001)*100
	local sig_sd_round=string(`sig_sd_round',"%5.1f")

	local frac_less_0_zscore=(1-normal(`mean_gap'/`sig_sd'))*100
	local frac_less_0_zscore=string(`frac_less_0_zscore', "%5.1f")

	di "`pct_less_0'"
	di "`frac_less_0_zscore'"

	*true fraction less than 0
	gen gap = (white_black_gap<0)
	replace gap = . if missing(white_black_gap)
	summ gap [w=kir_black_`gender'_n]
	local trueless0: di %4.1f `r(mean)'*100
		
	noi twoway__histogram_gen white_black_gap2 [fw=kir_black_`gender'_n] if inrange(white_black_gap2, -.`min', .4 ), bin(50) gen(h x) display
	noi return list 
	gen width = `r(width)'
			

	keep white_black_gap2 normal_gap_sig_sd h x width
	chopper, vars(white_black_gap2 normal_gap_sig_sd h x width)
	save "${final}/hist_white_black_gap_histogram_`gender'_p`p'", replace
	}
}
