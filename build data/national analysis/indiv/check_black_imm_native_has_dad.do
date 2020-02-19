/*

This .do file replicates the analysis of the has_dad variable using non-immigrants. 

*/

set more off

use 	kid_pik 	par_state 		par_county ///
		par_tract 	kid_race 		gender ///
		kfr			kir				kir_native ///
		kfr_native	par_rank		mom_native	  ///
		has_dad							///
		if kid_race >0 & par_state>0 ///
		using "${work}/race_work_long_78_83", clear
	
gen has_dad_native = has_dad if mom_native == 1

*make a group for below and above median parent rank
gen above_med = (par_rank>0.5)

*flag first ob by kid tract
bys kid_pik par_state par_county par_tract: gen flag = 1 if _n == 1

*make a count variable
foreach var in kfr kir kfr_native kir_native {
	gen n_`var' = 1 if !missing(`var') & flag == 1
}

*keep long on count, which generates the XW weighting
collapse (mean) kfr* kir* has_dad* (sum) n_*, by(par_state par_county par_tract kid_race gender above_med)

*save results 
save "${out}/mean_kfr_kir_natives", replace

*reshape wide on race and gender
reshape wide kir* kfr* has_dad* n_*, i(par_state par_county par_tract above_med gender) j(kid_race)
reshape wide kir* kfr* has_dad* n_*, i(par_state par_county par_tract above_med) j(gender) string

*merge on the has dad variables
rename (par_state par_county par_tract) (state county tract)
merge m:1 state county tract   ///
	using "${final}/tract_race_gender_mskd", nogen keep(3) ///
	keepusing(has_dad*)
	
*merge on poverty share
merge m:1 state county tract using "${ext}/tract_covars", nogen keep(1 3) keepusing(poor_share2000)

*merge on the gender counts
merge m:1 tract county state using "${out}/tract_gender", keep(match master) keepusing(filed_m_b_l_0) nogen

*merge on the number of dad per kid in 2000
rename  (state county tract) (par_state par_county par_tract)
merge m:1 par_state par_county par_tract using "${out}/tract_dad_counts", keep(match master) keepusing(dads_kid_2000_black kids_2000_black) nogen	

*Generate variable for number of low income filers per kid
g linc_filers_kid=filed_m_b_l_0/kids_2000_black

*------------------------------------------------------
*Run the regressions both for kfr and kfr_native
*------------------------------------------------------

*1) kir_black_male on has_dad in low poverty tracts

*all 
reg kir2M has_dad_black_male_p25 [w=n_kir2M] if poor_share<0.1  & n_kir2M>=20 & above_med == 0
reg kir2M has_dad2M [w=n_kir2M] if poor_share<0.1  & n_kir2M>=20 & above_med == 0

*native
reg kir_native2M has_dad_black_male_p25 [w=n_kir2M] if poor_share<0.1  & n_kir_native2M>=20 & above_med == 0
reg kir_native2M has_dad_native2M [w=n_kir2M] if poor_share<0.1  & n_kir_native2M>=20 & above_med == 0

*2) kir_black_male on has_dad_black and has_dad white in low poverty tracts

*all 
reg kir2M has_dad_black_male_p25 has_dad_white_male_p25 [w=n_kir2M] if poor_share<0.1  & n_kir2M>=20 & above_med == 0
reg kir2M has_dad2M has_dad1M [w=n_kir2M] if poor_share<0.1  & n_kir2M>=20 & above_med == 0

*native
reg kir_native2M has_dad_black_male_p25 has_dad_white_male_p25 [w=n_kir2M] if poor_share<0.1  & n_kir_native2M>=20 & above_med == 0
reg kir_native2M has_dad2M has_dad1M [w=n_kir2M] if poor_share<0.1  & n_kir_native2M>=20 & above_med == 0
reg kir_native2M has_dad_native2M has_dad1M [w=n_kir2M] if poor_share<0.1  & n_kir_native2M>=20 & above_med == 0

*3) black fathers per child compared to black male filers

*all
reg kir2M dads_kid_2000_black linc_filers_kid [w=n_kir2M] if n_kir2M>=20 & above_med == 0

*natives
reg kir_native2M dads_kid_2000_black linc_filers_kid [w=n_kir2M] if n_kir_native2M>=20 & above_med == 0