/*

This .do file creates Figure 9 and Appendix Figure 11. 

*/
 
* set genders 
local genders male female 

foreach gender in `genders' {

	* set colorscheme
	if "${version}" == "paper"		local colorscheme "mikeSpecialOne"
	if "${version}" == "slides"		local colorscheme "dh1"

	* load data
	use "${online_tables}/cz_collapse.dta", clear
	keep cz cz_name kir*_`gender'* cz*

	* create indicator for race
	local i = 0
	foreach race in _black _white{
		local ++i
		replace kir`race'_`gender'_p25 =. if cz_pop`race'2000 < 500
		rename kir`race'_`gender'_p25 s`i'
	}
	keep s* cz

	* reshape by race (so that full range is still used in maptile)
	reshape long s, i(cz) j(t)

	* white map 
	replace cz = cz + 0.5 if t != 2
	maptile2 s, geo(cz) colorscheme(`colorscheme') ///
		nq(15) savegraph("${figures}/map_kir_white_`gender'_p25_15bins.png") ///
		nolegend legdecimals(1)
		
	* black map
	replace cz = cz - 0.5 if t != 2
	replace cz = cz + 0.5 if t != 1
	maptile2 s, geo(cz) colorscheme(`colorscheme') ///
		nq(15) savegraph("${figures}/map_kir_black_`gender'_p25_15bins.png") ///
		legdecimals(1)

	* convert legend numbers from ranks to dollars
	local rank 46.2
	convert_rank_dollar `rank', kir
	local round_dollar = round(`r(dollar_amount)', 1000)
	di "`round_dollar'"
}