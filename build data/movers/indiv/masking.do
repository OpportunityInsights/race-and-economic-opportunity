/*

This .do file masks the movers results. 

*/

* Mask standard hockey sticks
use "${out}/hs_standard", clear
mask, by(kid_race gender yvar age) countvar(count) minbin(20) round(4) roundcounts

*Save and export
save "${final}/hs_standard_mskd", replace

* Mask placebo hockey sticks 
use "${out}/hs_placebo", clear
ds coef stderr r2 N, not
mask, by(`r(varlist)') countvar(N) minbin(20) round(4) roundcounts

*Save and export
save "${final}/hs_placebo_mskd", replace

* Mask exposure hockey sticks 
use "${out}/hs_exposure_effects", clear
ds coef stderr r2 N, not
mask, by(`r(varlist)') countvar(N) minbin(20) round(4) roundcounts

*Save and export
save "${final}/hs_exposure_effects_mskd", replace