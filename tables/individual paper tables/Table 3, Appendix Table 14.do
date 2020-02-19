/*

This .do file creates the racial bias regressions in Table III and Appendix Table XIV. 

*/ 

* -------------------------------------------------------------
* Arrange data for IAT measures at county level
* -------------------------------------------------------------

*Assemble County Level Data Set (similar to correlations table)

use tract county state kir_white_*male_* kir_black_*male_* ///
		kir_ewrk_white_*male_* kir_ewrk_black_*male_* ///
		kid_jail_white_*male_* kid_jail_black_*male_* ///
		using "${final}/tract_race_gender_mskd", clear

*Get these estimates to the county level
merge 1:1 tract county state using "${ext}/tract_covars", nogen keepusing(poor_share2000 pop2000)

*get the poor share by each geography
preserve

collapse poor_share_county = poor_share2000 [w=pop2000], by(state county)
tempfile county_poor
save `county_poor'
restore
merge m:1 state county using `county_poor', nogen


foreach race in white black {
	foreach gender in male female {
		foreach outc in kir kir_ewrk kid_jail {
		
				*make the total n
				bys state county: egen `outc'_`race'_`gender'_county_n = total(`outc'_`race'_`gender'_n)
				replace  `outc'_`race'_`gender'_county_n =. if  `outc'_`race'_`gender'_county_n==0
				
			foreach j in 25 75 {
				
				*make the total kir
				bys state county: egen `outc'_`race'_`gender'_p`j'_county = total(`outc'_`race'_`gender'_p`j' * `outc'_`race'_`gender'_n)
				replace `outc'_`race'_`gender'_p`j'_county = `outc'_`race'_`gender'_p`j'_county / `outc'_`race'_`gender'_county_n
			}
		}
	}
}

*Now get down to the county level
bys state county: keep if _n==1

*merge on IAT outcomes
merge 1:1 state county using "${ext}/iat_county", keep(match master) nogen

*Generate diffs between blacks and whites
g iat_diff_raw = iat_total_white-iat_total_black // higher value means more racial bias (among whites) relative to reference of blacks
g kir_p25_m_diff = kir_black_male_p25_county-kir_white_male_p25_county
g kir_work_p25_m_diff = kir_ewrk_black_male_p25_county-kir_ewrk_white_male_p25_county
g kid_jail_p25_m_diff = kid_jail_black_male_p25_county-kid_jail_white_male_p25_county

* clear saved estimates
eststo clear

*Standardize IAT variables on relevant sample
su iat_diff_raw [w=kir_black_male_county_n]
g iat_diff = (iat_diff_raw-r(mean))/r(sd)

su iat_total_white [w=kir_black_male_county_n]
g iat_total_white_sd = (iat_total_white-r(mean))/r(sd)

su iat_total_black [w=kir_black_male_county_n]
g iat_total_black_sd = (iat_total_black-r(mean))/r(sd)

* -------------------------------------------------------------
* Run IAT regressions in Table III
* -------------------------------------------------------------

*1. reg kir black m p25 on diff_iat with poor_share<10% for this and all specs below
eststo spec_1 : reg kir_black_male_p25_county iat_diff [w=kir_black_male_county_n] if poor_share_county<.1

*2. reg kir black m p25 on iat_white and iat_black
eststo spec_2 : reg kir_black_male_p25_county iat_total_white_sd iat_total_black_sd [w=kir_black_male_county_n] if poor_share_county<.1

*3. reg kir black m p25 on iat_white and iat_black
eststo spec_3 : reg kir_black_male_p25_county iat_diff [w=kir_black_male_county_n] if poor_share_county<.1, absorb(state)

*4. reg kir black f p25 on diff_iat
eststo spec_4 : reg kir_black_female_p25_county iat_diff [w=kir_black_male_county_n] if poor_share_county<.1

*5.	reg kir white m p25 on diff_iat
eststo spec_5 : reg kir_white_male_p25_county iat_diff [w=kir_black_male_county_n] if poor_share_county<.1

* -------------------------------------------------------------
* Run IAT regressions in Table XIV 
* -------------------------------------------------------------

*6. reg kir_work m p25 on diff_iat
eststo spec_6 : reg kir_ewrk_black_male_p25_county iat_diff [w=kir_ewrk_black_male_county_n] if poor_share_county<.1

*7. reg kid_jail m p25 on diff_iat
eststo spec_7 : reg kid_jail_black_male_p25_county iat_diff [w=kir_ewrk_black_male_county_n] if poor_share_county<.1

* make table
estout spec* using "${tables}/racial_bias_A.txt" , ///
	cells(b(star fmt(%9.4f)) se(par)) ///
	starlevels(* 0.1 ** 0.05 *** 0.001) ///
	stats(r2 N wtsum, fmt(3 0) labels("R2" "N")) replace

* -------------------------------------------------------------
* Assemple data for racial animus regressions
* -------------------------------------------------------------

*Assemble County Level Data Set (similar to correlations table)

use tract county state kir_white_*male_* kir_black_*male_* ///
		kir_ewrk_white_*male_* kir_ewrk_black_*male_* ///
		kid_jail_white_*male_* kid_jail_black_*male_* ///
		using "${final}/tract_race_gender_mskd.dta", clear

*Get these estimates to the county level
merge 1:1 tract county state using "${ext}/tract_covars.dta", nogen keepusing(poor_share2000 pop2000 dmaindex)

*DMA
preserve

collapse poor_share_dma = poor_share2000 [w=pop2000], by(dmaindex)
tempfile dma_poor
save `dma_poor'
restore
merge m:1 dmaindex using `dma_poor', nogen

foreach race in white black {
	foreach gender in male female {
		foreach outc in kir kir_ewrk kid_jail {
				*make the total n
				bys dmaindex: egen `outc'_`race'_`gender'_dma_n = total(`outc'_`race'_`gender'_n)
				replace  `outc'_`race'_`gender'_dma_n =. if  `outc'_`race'_`gender'_dma_n==0
			foreach j in 25 75 {
				*make the total kir
				bys dmaindex: egen `outc'_`race'_`gender'_p`j'_dma = total(`outc'_`race'_`gender'_p`j' * `outc'_`race'_`gender'_n)
				replace `outc'_`race'_`gender'_p`j'_dma = `outc'_`race'_`gender'_p`j'_dma / `outc'_`race'_`gender'_dma_n
				
			}
		}
	}
}

*Now get down to the county level
bys dmaindex: keep if _n==1

preserve
use dmaindex racialanimus_raw using "${ext}/tract_covars.dta", clear
collapse (mean) racialanimus_raw, by(dmaindex)
tempfile animus
save `animus'
restore

merge 1:m dmaindex using `animus', keepusing(dmaindex racialanimus_raw)

*Generate diffs between blacks and whites
g kir_p25_m_diff = kir_black_male_p25_dma-kir_white_male_p25_dma
g kir_work_p25_m_diff = kir_ewrk_black_male_p25_dma-kir_ewrk_white_male_p25_dma
g kid_jail_p25_m_diff = kid_jail_black_male_p25_dma-kid_jail_white_male_p25_dma

* clear saved estimates
eststo clear

* standardize racial animus variable on relevant sample
su racialanimus_raw [w=kir_black_male_dma_n]
g racialanimus = (racialanimus_raw-r(mean))/r(sd)


* -------------------------------------------------------------
* Run racial animus regressions for Table III 
* -------------------------------------------------------------

*1. reg kir black m p25 on racial animus with poor_share<10% for this and all specs below
eststo spec_1 : reg kir_black_male_p25_dma racialanimus  [w=kir_black_male_dma_n] if poor_share_dma<.1

*2. reg kir black f p25 on racial animus
eststo spec_2 : reg kir_black_female_p25_dma racialanimus  [w=kir_black_male_dma_n] if poor_share_dma<.1

*3.	reg kir white m p25 on racial animus
eststo spec_3 : reg kir_white_male_p25_dma racialanimus  [w=kir_black_male_dma_n] if poor_share_dma<.1

* -------------------------------------------------------------
* Run racial animus regressions for Table XIV  
* -------------------------------------------------------------

*4.	reg kir_work m p25 on racial animus
eststo spec_4 : reg kir_ewrk_black_male_p25_dma racialanimus  [w=kir_ewrk_black_male_dma_n] if poor_share_dma<.1

*5. reg kid_jail m p25 on racial animus
eststo spec_5 : reg kid_jail_black_male_p25_dma racialanimus  [w=kid_jail_black_male_dma_n] if poor_share_dma<.1

* make table
estout spec* using "${tables}/racial_bias_B.txt" , ///
	cells(b(star fmt(%9.4f)) se(par)) ///
	starlevels(* 0.1 ** 0.05 *** 0.001) ///
	stats(r2 N wtsum, fmt(3 0) labels("R2" "N")) replace