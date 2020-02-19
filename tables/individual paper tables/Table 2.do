/*

This .do file explores the effects of father presence. 
It makes the majority of Table II. 
The last column of Table II is estimated on the micro data; see dad_regressions_mskd.txt. 

*/

set more off

use "${final}/tract_race_gender_mskd.dta", clear

*Merge on the covariates
merge 1:1 tract county state using "${ext}/tract_covars", keep(match master) keepusing(poor_share2000) nogen

*Merge on the gender counts
merge 1:1 tract county state using "${final}/tract_gender", keep(match master) keepusing(filed_m_b_l_0) nogen

*Merge on the number of dads per kid in 2000 
rename (state county tract) (par_state par_county par_tract)
merge 1:1 par_state par_county par_tract using "${final}/tract_dad_counts", keep(match master) keepusing(dads_kid_2000_black kids_2000_black) nogen
rename (par_state par_county par_tract) (state county tract)

*Generate variable for number of low income filers per kid
g linc_filers_kid=filed_m_b_l_0/kids_2000_black

tempfile base 
save `base'

local outc kir

estimates drop _all

if "`outc'"=="kir" {
	local 1par  _1par
	local 2par  _2par 
	local dad   _f
	local nodad _nf
}

*do the manual masking
foreach var in `outc'_black_male `outc'_black_female `outc'_white_male  ///
			`outc'_white_female has_dad_black_pooled has_dad_white_pooled {
				
				replace `var'_p25 = . if `var'_n <20
				
}

*Spec 1- regress outcome on low-income black father presence, only in low poverty places
regress `outc'_black_male_p25 has_dad_black_pooled_p25 if poor_share2000<0.1 [w=kir_black_male_n], r
eststo spec1_bmale_bdad_lowpov
	
*Spec 2- regress outcome on low-income black father presence and low-income white father presence, only in low poverty places
regress `outc'_black_male_p25 has_dad_black_pooled_p25 has_dad_white_pooled_p25 if poor_share2000<0.1 [w=kir_black_male_n], r
eststo spec2_bmale_bdad_wdad_lpov

*Spec 3- regress outcome on low-income black father presence, including state FEs, only in low poverty places
regress `outc'_black_male_p25 has_dad_black_pooled_p25 if poor_share2000<0.1 [w=kir_black_male_n], r a(state)
eststo spec3_bmale_bdad_lowpov_st		

*Spec 4- regress outcome on low-income black father presence, for children with fathers absent, only in low-poverty places 
regress `outc'`nodad'_black_male_p25 has_dad_black_pooled_p25 if poor_share2000<0.1 [w=kir_black_male_n], r
eststo spec4_bmale_bdad_all_nodad

*Spec5- regress outcome on low-income black father presence, for children with two parents 
regress `outc'`2par'_black_male_p25 has_dad_black_pooled_p25 if poor_share2000<0.1 [w=kir_black_male_n], r
eststo spec5_bmale_bdad_lpov_2par

*Spec6- regress outcome on low-income black father presence, all tracts 
regress `outc'_black_male_p25 has_dad_black_pooled_p25 [w=kir_black_male_n], r
eststo spec6_bmale_bdad_all

*Define variables for specifications 7 and 8 
su linc_filers_kid [w=kir_black_male_n], d
g in_samp=linc_filers_kid<`r(p99)' & ~mi(linc_filers_kid) & ~mi(dads_kid_2000_black)

*Spec7 - regress outcome on number of dads/kids in 2000, only in low-poverty tracts 
regress `outc'_black_male_p25 dads_kid_2000_black if poor_share2000<0.1 & in_samp==1 [w=kir_black_male_n], r
eststo spec7_bmale_bdad_count

*Spec8 - regress outcome on number of dads/kids in 2000 and number of low-income-filing blackmen, only in low-poverty tracts
regress `outc'_black_male_p25 dads_kid_2000_black linc_filers_kid if poor_share2000<0.1 & in_samp==1 [w=kir_black_male_n], r
eststo spec8_bmale_bdad_fil_count

*Spec9 - regress outcome on low-income black father presence, all tracts, current tract FEs 
// calculated on micro data: see dad_regressions_mskd.txt  
				
estout spec* using "${tables}/has_dad_ols_`outc'_mskd.txt" , ///
	cells(b(star fmt(%9.4f)) se(par)) ///
	starlevels(* 0.1 ** 0.05 *** 0.001) ///
	stats(r2 N, fmt(3 0) labels("R2" "N")) replace