/*

This .do file checks that the key tract-level correlations also hold when 
restricting only to children with native-born mothers

*/

set more off

*--------------------------------------------
* combine tract level covars and mobility
*--------------------------------------------

use 	state			county				tract		///
	married_share2000	poor_share2000			emp_rate_pooled_pooled ///
	singleparent_share2000	iat_total_white			racialanimus_raw	///
	rent_twobed2015		total_rate_suspension		college_share2000	///
	pop2000			dmaindex			race_attitude		///
	gsmn_math_g3_2013	gsmn_math_g8_2013		nohs_share2000		///
	hhinc_mean2000									///
	using "${ext}/tract_covars", clear
	
* merge on by race home values
merge 1:1 state county tract using "${ext}/home_value_race", nogen keepusing(median_value_black2000 median_value_white2000)

* merge on by race poverty rates
merge 1:1 state county tract using "${ext}/poor_share_race", nogen keepusing(poor_share_black2000 poor_share_white2000)


* merge on tract level covariates from the paper
merge m:1 state county tract   ///
	using "${out}/tract_race_gender_mskd", nogen ///
	keepusing(has_dad_black_pooled_p25 has_dad_white_pooled_p25 has_mom_black_pooled_p25 has_mom_white_pooled_p25)

ds state county tract, not
local allvars `r(varlist)'

rename  (state county tract) (par_state par_county par_tract)

tempfile covar
save `covar'


use "${out}/mean_kfr_kir_natives", clear

* reshape wide on race and gender
reshape wide kir* kfr* has_dad* n_*, i(par_state par_county par_tract above_med gender) j(kid_race)
reshape wide kir* kfr* has_dad* n_*, i(par_state par_county par_tract above_med) j(gender) string

keep if above_med == 0

merge 1:1 par_state par_county par_tract using `covar', keep(3)



*------------------------------------------
* Run the correlations
*------------------------------------------


tempfile corrfile
save `corrfile'


qui foreach kr in 1 2 {
	noi di "***** RACE `kr' *****"
	foreach corr of local allvars {
		foreach nat in "" "_native" {
		
			use `corrfile', clear
			drop if n_kir`nat'`kr'M < 20
			drop if missing(n_kir`nat'`kr'M) | missing(`corr')
			
			
			* get the reliability
			tempvar prec 
			gen `prec' = n_kir`nat'`kr'M
			tempvar weight
			gen `weight' = `prec'
			
			* standardize the vars to get the SEs
			qui summ `corr' [w=`weight']
			gen st_`corr' = (`corr' - `r(mean)')/`r(sd)'
			qui summ kir`nat'`kr'M [w=`weight']
			gen st_kir`nat'`kr'M = (kir`nat'`kr'M - `r(mean)')/`r(sd)'
			qui reg st_`corr' st_kir`nat'`kr'M [w=`weight']
			local rawcorr = _b[st_kir`nat'`kr'M]
			local se = _se[st_kir`nat'`kr'M]

			noi di "	var: `corr' `nat': raw " round(`rawcorr',0.0001) "(" round(`se', 0.0001) ")"
		}
	}
}

* take IAT to the county level
use `corrfile', clear
collapse (mean) iat_total_white kir* (rawsum) n_kir* [w=pop2000], by(par_state par_county)

tempfile countycorrfile
save `countycorrfile'

qui foreach kr in 1 2 {
	noi di "***** RACE `kr' *****"
	foreach corr in iat_total_white {
		foreach nat in "" "_native" {
		
			use `countycorrfile', clear
			drop if n_kir`nat'`kr'M < 20
			drop if missing(n_kir`nat'`kr'M) | missing(`corr')
			
			
			* get the reliability
			tempvar prec 
			gen `prec' = n_kir`nat'`kr'M
			tempvar weight
			gen `weight' = `prec'
			
			* standardize the vars to get the SEs
			qui summ `corr' [w=`weight']
			gen st_`corr' = (`corr' - `r(mean)')/`r(sd)'
			qui summ kir`nat'`kr'M [w=`weight']
			gen st_kir`nat'`kr'M = (kir`nat'`kr'M - `r(mean)')/`r(sd)'
			qui reg st_`corr' st_kir`nat'`kr'M [w=`weight']
			local rawcorr = _b[st_kir`nat'`kr'M]
			local se = _se[st_kir`nat'`kr'M]

			noi di "	var: `corr' `nat': raw " round(`rawcorr',0.0001) "(" round(`se', 0.0001) ")"
		}
	}
}

* take the racial_animus measure to the DMA index level
use `corrfile', clear
collapse (mean) racialanimus_raw kir* (rawsum) n_kir* [w=pop2000], by(dmaindex)

tempfile dmacorrfile
save `dmacorrfile'

qui foreach kr in 1 2 {
	noi di "***** RACE `kr' *****"
	foreach corr in racialanimus_raw {
		foreach nat in "" "_native" {
		
			use `dmacorrfile', clear
			drop if n_kir`nat'`kr'M < 20
			drop if missing(n_kir`nat'`kr'M) | missing(`corr')
			
			
			* get the reliability
			tempvar prec 
			gen `prec' = n_kir`nat'`kr'M
			tempvar weight
			gen `weight' = `prec'
			
			* standardize the vars to get the SEs
			qui summ `corr' [w=`weight']
			gen st_`corr' = (`corr' - `r(mean)')/`r(sd)'
			qui summ kir`nat'`kr'M [w=`weight']
			gen st_kir`nat'`kr'M = (kir`nat'`kr'M - `r(mean)')/`r(sd)'
			qui reg st_`corr' st_kir`nat'`kr'M [w=`weight']
			local rawcorr = _b[st_kir`nat'`kr'M]
			local se = _se[st_kir`nat'`kr'M]

			noi di "	var: `corr' `nat': raw " round(`rawcorr',0.0001) "(" round(`se', 0.0001) ")"
		}
	}
}


* take the racial marriage attitude measure to the DMA index level
use `corrfile', clear
collapse (mean) race_attitude kir* (rawsum) n_kir* [w=pop2000], by(par_state)

tempfile statecorrfile
save `statecorrfile'

qui foreach kr in 1 2 {
	noi di "***** RACE `kr' *****"
	foreach corr in race_attitude {
		foreach nat in "" "_native" {
		
			use `statecorrfile', clear
			drop if n_kir`nat'`kr'M < 20
			drop if missing(n_kir`nat'`kr'M) | missing(`corr')
			
			
			* get the reliability
			tempvar prec 
			gen `prec' = n_kir`nat'`kr'M
			tempvar weight
			gen `weight' = `prec'
			
			* standardize the vars to get the SEs
			qui summ `corr' [w=`weight']
			gen st_`corr' = (`corr' - `r(mean)')/`r(sd)'
			qui summ kir`nat'`kr'M [w=`weight']
			gen st_kir`nat'`kr'M = (kir`nat'`kr'M - `r(mean)')/`r(sd)'
			qui reg st_`corr' st_kir`nat'`kr'M [w=`weight']
			local rawcorr = _b[st_kir`nat'`kr'M]
			local se = _se[st_kir`nat'`kr'M]

			noi di "	var: `corr' `nat': raw " round(`rawcorr',0.0001) "(" round(`se', 0.0001) ")"
		}
	}
}

*----------------------------------------------------------
* Replicate figure 13 from the paper
*----------------------------------------------------------

use `corrfile', clear

* restrict to low poverty places
drop if poor_share2000>0.1

* restrict to places with at least 20 white and black kids
drop if n_kir_native2M<5 | n_kir_native1M<5

* generate the white minus black rank for native
gen wb_gap_native = kir_native1M - kir_native2M
gen wb_pop_native = n_kir_native1M + n_kir_native2M

gen wb_gap = kir1M - kir2M
gen wb_pop = n_kir1M + n_kir2M

rename *native* *nat*

* run the correlations for the full pop and for natives and compare the order

foreach corr of local allvars {
	foreach nat in "" "_nat" {
	
		corr wb_gap`nat' `corr' [w=wb_pop`nat']
		local c_`corr'`nat' = `r(rho)'
	}
	
}

* build a file with the results
clear
set obs 50

gen var = ""
gen corr = .
gen corr_native = .

local i = 0
foreach corr of local allvars {
	local ++ i
	replace var = "`corr'" if _n == `i'
	replace corr = `c_`corr'' if _n == `i'
	replace corr_nat = `c_`corr'_nat' if _n == `i'
}

drop if var == "iat_total_white"
drop if var == "racialanimus_raw"
drop if var == "dmaindex"
drop if var == "race_attitude"

drop if missing(var)

sort corr
gen rank = _n
sort corr_nat
gen rank_nat = _n

corr rank rank_nat
corr corr corr_native
