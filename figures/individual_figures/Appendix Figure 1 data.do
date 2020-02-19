/*

This .do file rearranges the data for graphing in Appendix Figure 1. 

*/

* select variables to be plotted (e.g. kfr)  
local varlist_rr kfr

* load national mobility data 
use "${final}/pctile_clps_mskd", clear

drop if kid_race == -9

* collapse over parent percentile (drop kid_race gender dimension)
collapse (mean) `varlist_rr' (rawsum) count [w=count], ///
	by(par_pctile)
		
	* rearrange for graphing 
	foreach var in `varlist_rr' {
		
	keep par_pctile kfr
	rename kfr kfr_pooled
	chopper, vars(kfr_pooled)
	save "${final}/bin_`var'_par_rank_pooled_notmissingrace", replace
}