/*

This .do file creates Appendix Figures 12 and 13. 

*/

* load variables
use "${final}/map_cz_estimate", clear

renvars bin_*, presub(bin_)

qui: ds cz, not
foreach var in `r(varlist)' {
	preserve 
		local var `var'
		
		* merge values for bins
		keep cz `var' 
		ren `var' bin 

		merge m:1 bin using "${final}/map_cz_bin_min_max.dta", ///
			keepusing(min_`var' max_`var')

		gen map_val_`var' = (min_`var' + max_`var')/2
		replace map_val_`var' = map_val_`var'*100
			
		* map variables	
		maptile2 map_val_`var' if map_val_`var'!=., geo(cz) geovar(cz)  /// 
			legdecimals(1) savegraph("${figures}/map_`var'.png")	///
			colorscheme("YlOrRd") revcolor
	restore 
}	
