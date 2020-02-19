/*

This .do file creates Appendix Figure 1. 

*/

* local point size
local psize 0.75

* load national mobility data 
use "${final}/bin_kfr_par_rank_pooled_notmissingrace", clear

reg kfr_pooled par_pctile
	local slope : di %4.2f _b[par_pctile]
	local icept : di %4.2f _b[_cons]
twoway ///
	scatter kfr_pooled par_pctile , mcolor(black) msize(`psize') msymbol($sym_pool) || ///
	lfit kfr_pooled par_pctile , lcolor(black) ///
	xtitle("Parent Household Income Rank") ///
	ytitle("Mean Child Household Income Rank", margin(t=3)) ///
	ylabel(20(20)80, gmin gmax) ///
	xlabel(0(20)100) /*xmtick(##5)*/ ///
	title(${title_size}) ///
	legend(off) ///
	text(23 83 "Int.: {&alpha} = `icept'; Slope: {&Beta} = `slope'", size(small))
graph export "${figures}/bin_kfr_par_rank_pooled_notmissingrace.${img}", replace