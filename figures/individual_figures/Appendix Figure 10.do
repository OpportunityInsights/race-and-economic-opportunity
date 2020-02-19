/*

This .do file creates Appendix Figure 10. 

*/

use "${online_tables}/cz_collapse.dta", clear

keep cz kfr* cz*
local i = 0
foreach race in _black _white ""{
	local ++i
    replace kfr`race'_pooled_p25 =. if cz_pop`race'2000 < 500
	rename kfr`race'_pooled_p25 s`i'
}

reshape long s, i(cz) j(t)
replace cz = cz + 0.5 if t != 3
maptile2 s, geo(cz) colorscheme("mikeSpecialOne") ///
	nq(15) savegraph("${figures}/map_kfr_pooled_p25_15bins.png") nolegend legdecimals(1)
replace cz = cz - 0.5 if t != 3
replace cz = cz + 0.5 if t != 2
maptile2 s, geo(cz) colorscheme("mikeSpecialOne") ///
	nq(15) savegraph("${figures}/map_kfr_white_p25_15bins.png") nolegend legdecimals(1)
replace cz = cz - 0.5 if t != 2
replace cz = cz + 0.5 if t != 1
maptile2 s, geo(cz) colorscheme("mikeSpecialOne") ///
 nq(15) savegraph("${figures}/map_kfr_black_p25_15bins.png") legdecimals(1)