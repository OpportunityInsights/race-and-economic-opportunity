/*

This .do file correlates predicted individual income for children growing up in p25 
families with various tract-level characteristics. 
It splits children by gender, and tracts by poverty. 

*/

set more off

*loop over gender
foreach gender in male female {

	*loop over poverty share	
	forval poor=0/1 {
	
		* -------------------------------
		* Load mobility data
		* -------------------------------
		*outcomes of interest
		global outcomes ///
			kir_white_`gender'_p25 	kir_black_`gender'_p25	///
			kir_white_`gender'_p75	kir_black_`gender'_p75	///
			black_white_gap_p25 	black_white_gap_p75 

		*load in the tract mobility data
		use tract county state kir_white_`gender'* kir_black_`gender'_* ///
			has_dad_black_pooled_p25 has_dad_white_pooled_p25 ///
			has_mom_black_pooled_p25 has_mom_white_pooled_p25 has_dad_pooled_pooled_p25 ///
				using "${final}/tract_race_gender_mskd.dta", clear

		* -------------------------------
		* Calculate relevant variables 
		* -------------------------------
		*define the black minus white gap
		foreach p in 25 75 {
			gen black_white_gap_p`p' = kir_black_`gender'_p`p' - kir_white_`gender'_p`p'
			
			*generate the SE (assume the noise in white and black is independent (so cov==0)
			gen black_white_gap_p`p'_se = sqrt(kir_black_`gender'_p`p'_se^2 + kir_white_`gender'_p`p'_se^2)
		}


		*construct the n in an easy way for each of these
		foreach var of global outcomes {
			di "`var'"
			if regex("`var'", "kir_black")==1 {
				gen `var'_n=kir_black_`gender'_n 
			}
			else if regex("`var'", "black_white_gap")==1 {
				gen `var'_n=kir_black_`gender'_n 
			}
			else {
				gen `var'_n=kir_white_`gender'_n
			}
		}
		
		* -------------------------------
		* Merge in other variables  
		* ------------------------------
		*merge in the covariates at the tract level
		merge 1:1 tract county state using "${ext}/tract_covars.dta", nogen
		rename share_insured_18_64 share_insured_18_64_all
		
		*generate the gap
		gen insured_gap = share_insured_18_64_black - share_insured_18_64_white

		*merge in the new by race variables
		preserve
		use "${ext}/racevars.dta", clear
		rename (state10 county10 tract10) (state county tract)
		
		*clean up long var names
		rename singlepar* sp*
		rename twoparwork* tpwork*
		ds state county tract, not
		local racevars `r(varlist)'
		tempfile race
		save `race'
		restore

		merge 1:1 state county tract using `race', nogen

		*merge in the poor share by race
		merge 1:1 tract county state using "${ext}/poor_share_race.dta", keep(match master) nogen
		drop poor_share_asian* poor_share_hisp* poor_share_white2010 poor_share_black2010

		*merge in the median home value by race
		merge 1:1 tract county state using "${ext}/home_value_race.dta", keep(match master) nogen
		drop median_value_hisp* median_value_asian*

		*merge in the composite test scores
		merge 1:1 tract county state using "${ext}/test_score_composite", keep(match master) nogen

		*merge in the more complete set of IAT measures
		merge m:1 state county using "${ext}/iat_county", keep(match master) nogen
		gen iat_total_diff = iat_total_white - iat_total_black

		* -------------------------------
		* Get poor shares for each geography   
		* ------------------------------
		*COUNTY
		preserve

		collapse poor_share_county = poor_share2000 [w=pop2000], by(state county)
		tempfile county_poor
		save `county_poor'
		restore
		merge m:1 state county using `county_poor', nogen

		*STATE
		preserve

		collapse poor_share_state = poor_share2000 [w=pop2000], by(state)
		tempfile state_poor
		save `state_poor'
		restore
		merge m:1 state using `state_poor', nogen

		*DMAINDEX
		preserve 

		collapse poor_share_dmaindex = poor_share2000 [w=pop2000], by(dmaindex)
		tempfile dmaindex_poor
		save `dmaindex_poor'
		restore
		merge m:1 dmaindex using `dmaindex_poor', nogen

		* -------------------------------
		* Aggregate mobility for county, state, DMA    
		* ------------------------------
		*COUNTY AGGREGATION
		*first aggregate white and black separately and then do the gap
		foreach j in 25 75 {
			foreach race in white black {
				
				*make the total n
				bys state county: egen kir_`race'_`gender'_p`j'_county_n = total(kir_`race'_`gender'_p`j'_n)
				replace  kir_`race'_`gender'_p`j'_county_n =. if  kir_`race'_`gender'_p`j'_county_n==0
			
				*make the total kir
				bys state county: egen kir_`race'_`gender'_p`j'_county = total(kir_`race'_`gender'_p`j' * kir_`race'_`gender'_p`j'_n)
				replace kir_`race'_`gender'_p`j'_county = kir_`race'_`gender'_p`j'_county / kir_`race'_`gender'_p`j'_county_n
			}
		gen black_white_gap_p`j'_county_n =  kir_black_`gender'_p`j'_county_n
		gen black_white_gap_p`j'_county = kir_black_`gender'_p`j'_county - kir_white_`gender'_p`j'_county
		}

		*STATE AGGREGATION
		foreach j in 25 75 {
			foreach race in white black {
				
				*make the total n
				bys state: egen kir_`race'_`gender'_p`j'_state_n = total(kir_`race'_`gender'_p`j'_n)
				replace  kir_`race'_`gender'_p`j'_state_n =. if  kir_`race'_`gender'_p`j'_state_n==0
				
				*make the total kir
				bys state: egen kir_`race'_`gender'_p`j'_state = total(kir_`race'_`gender'_p`j' * kir_`race'_`gender'_p`j'_n)
				replace kir_`race'_`gender'_p`j'_state = kir_`race'_`gender'_p`j'_state / kir_`race'_`gender'_p`j'_state_n
			}
			gen black_white_gap_p`j'_state_n =  kir_black_`gender'_p`j'_state_n
			gen black_white_gap_p`j'_state = kir_black_`gender'_p`j'_state - kir_white_`gender'_p`j'_state
		}

		*DMA INDEX AGGREGATION
		foreach j in 25 75 {
			foreach race in white black {
		
				*make the total n
				bys dmaindex: egen kir_`race'_`gender'_p`j'_dmaindex_n = total(kir_`race'_`gender'_p`j'_n)
				replace  kir_`race'_`gender'_p`j'_dmaindex_n =. if  kir_`race'_`gender'_p`j'_dmaindex_n==0
			
				*make the total kir
				bys dmaindex: egen kir_`race'_`gender'_p`j'_dmaindex = total(kir_`race'_`gender'_p`j' * kir_`race'_`gender'_p`j'_n)
				replace kir_`race'_`gender'_p`j'_dmaindex = kir_`race'_`gender'_p`j'_dmaindex / kir_`race'_`gender'_p`j'_dmaindex_n
			}
			gen black_white_gap_p`j'_dmaindex_n =  kir_black_`gender'_p`j'_dmaindex_n
			gen black_white_gap_p`j'_dmaindex = kir_black_`gender'_p`j'_dmaindex - kir_white_`gender'_p`j'_dmaindex
		}

		* -------------------------------
		* Prepare correlations     
		* ------------------------------
		*drop the covariates we no longer use 
			*health vars
			drop *cancer* *no_insurance* *obese* *health*
			*lead
			drop *lead*

		*get the list of the things we want to correlate 
		ds kir_b* kir_wh* black_white_gap* tract *county* *state* iat* racialanimus* race_attitude* *dmaindex* pop2*, not
		local corr_vars `r(varlist)' has_dad_pooled_pooled_p25 `racevars'

		*get the length
		local count_corr: word count of corr_vars

		*get the list of outcomes for each column
		ds ${outcomes}
		local kir_vars `r(varlist)'
		
		*get the length
		local count_kir: word count of kir_vars

		if `poor'==0 {
			local pov ""
			tempfile base`poor'
			save `base`poor''
		}
		if `poor'==1 {
			local pov "_lowpov"
			keep if poor_share2000<0.1
			tempfile base`poor'
			save `base`poor''
		}

		*loop over the combinations of these things
		local c=0
		local k=0

		foreach kir of local kir_vars {
			local ++k
			
			*clear out the old scalar out files
			cap erase "${scalar}/`kir'_signal_corr`pov'.csv"
			
			di "-------------------------------------------------"
			di "`kir'"
			di "-------------------------------------------------"
			foreach corr of local corr_vars {
				local ++c
			

				
				qui use `base`poor'', clear
				
				di "`corr'"
				
				
				*keep only the places that appear with non-missing vals of each
				qui keep if !missing(`corr')  & !missing(`kir')
				
				*test: drop the places that would get masked
				drop if `kir'_n<20
				
				*calculate the reliability of kir
				*-----------------------------------------
				*total variance
				gen se2=`kir'_se^2
				qui summ `kir' [w=1/se2]
				local totvar=`r(Var)'
				
				*noise variance
				qui summ se2 [w=1/se2]
				local noisevar =`r(mean)'
				
				*signal variance
				local sigvar = `totvar'-`noisevar'
				
				*reliability
				local reliability=`sigvar'/`totvar'
				di "`reliability'
				
				*standardize each of these
				qui summ `corr' [w=1/se2]
				gen st_`corr'=(`corr'-`r(mean)')/`r(sd)'
				
				qui summ `kir' [w=1/se2]
				gen st_`kir'=(`kir'-`r(mean)')/`r(sd)'
				qui corr `kir' `corr'  [w=1/se2]
				local raw_corr: di %6.4f `r(rho)'
				
				
				*calculate the raw correlation
				qui regress st_`kir' st_`corr' [w=1/se2]
				local rho:di %6.4f _b[st_`corr']
				local se=_se[st_`corr']
				
				assert `raw_corr'==`rho'
				*calculate signal corr
				di "`rho'
				local sig_rho = `rho'/sqrt(`reliability')
				di "`sig_rho'"
				*save this output
				local sigcorr_`c'_`k'=`sig_rho'
				local sigcorrse_`c'_`k'=`se'
				
				*export these to a scalar out file
				scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id (`corr' corr) num(`sig_rho')
				scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id (`corr' se) num(`se')
				
			}
			
			*outside of the normal covariate loop, need to do the racial IAT, animus, attitude measures
			*these are not at the tract level, so need to be calculated at the county, state, or media market level
			*NOTE: THESE ARE REGULAR CORRELATIONS, NOT SIGNAL CORRELATIONS
			
			*Implicit association test
			*-------------------------
			*use the non-restricted version since have to do low pov and coarser geography
			
			*three variables of interest, so loop over them
			foreach iat in white black diff {
				use `base0', clear

				*keep if not missing either
				drop if missing(`kir'_county) | missing(iat_total_`iat')

				bys state county: keep if _n==1

				*low pov restriction
				if `poor'==1 {
					keep if poor_share_county<0.1
				}
					

				*standardize using the county n
				summ iat_total_`iat' [w=`kir'_county_n]
				gen st_iat_total_`iat' = (iat_total_`iat' - `r(mean)')/`r(sd)'
				summ `kir'_county [w=`kir'_county_n]
				gen st_`kir'_county = (`kir'_county - `r(mean)') / `r(sd)'

				*correlate
				corr iat_total_`iat' `kir'_county [w=`kir'_county_n]
				local corr_manual : di %6.4f `r(rho)'
				regress st_`kir'_county st_iat_total_`iat' [w=`kir'_county_n]
				local corr : di %6.4f _b[st_iat_total_`iat']
				local se =_se[st_iat_total_`iat']

				assert `corr_manual' == `corr'
				di "`corr'"
				di "`se'"
				count
				local count =`r(N)'

				scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
						id(iat_total_`iat' corr) num(`corr')
				scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
						id(iat_total_`iat' se) num(`se')

			}
			
			*Racial Attitudes
			*-------------------------
			*use the non-restricted version since have to do low pov and coarser geography
			use `base0', clear
			*state level so need to aggregate to the state level (take the weighted mean of p25 kir)

			
			*keep if not missing either
			drop if missing(`kir'_state) | missing(race_attitude)
			
			bys state: keep if _n==1
			
			*low pov restriction
			if `poor'==1 {
				keep if poor_share_state<0.1
				}
				
			*keep if not missing either
			drop if missing(`kir'_state) | missing(race_attitude)
			*standardize using the county n
			summ race_attitude [w=`kir'_state_n]
			gen st_race_attitude = (race_attitude - `r(mean)')/`r(sd)'
			summ `kir'_state [w=`kir'_state_n]
			gen st_`kir'_state = (`kir'_state - `r(mean)') / `r(sd)'
			
			*correlate
			corr race_attitude `kir'_state [w=`kir'_state_n]
			local corr_manual : di %6.4f `r(rho)'
			regress st_`kir'_state st_race_attitude [w=`kir'_state_n]
			local corr : di %6.4f _b[st_race_attitude]
			local se =_se[st_race_attitude]
			
			assert `corr_manual' == `corr'
			di "`corr'"
			di "`se'"
			count
			local count =`r(N)'
			
			scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id(race_attitude corr) num(`corr')
			scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id(race_attitude se) num(`se')

					
			*Racial Animus
			*-------------------------
			*use the non-restricted version since have to do low pov and coarser geography
			use `base0', clear
			*media market level so need to aggregate to the dma level (take the weighted mean of p25 kir)

			*keep if not missing either
			drop if missing(`kir'_dmaindex) | missing(racialanimus_raw)
			
			bys dmaindex: keep if _n==1
			
			*low pov restriction
			if `poor'==1 {
				keep if poor_share_dmaindex<0.1
				}
				

			*standardize using the county n
			summ racialanimus_raw [w=`kir'_dmaindex_n]
			gen st_racialanimus_raw = (racialanimus_raw - `r(mean)')/`r(sd)'
			summ `kir'_dmaindex [w=`kir'_dmaindex_n]
			gen st_`kir'_dmaindex = (`kir'_dmaindex - `r(mean)') / `r(sd)'
			
			*correlate
			corr racialanimus_raw `kir'_dmaindex [w=`kir'_dmaindex_n]
			local corr_manual : di %6.4f `r(rho)'
			regress st_`kir'_dmaindex st_racialanimus_raw [w=`kir'_dmaindex_n]
			local corr : di %6.4f _b[st_racialanimus_raw]
			local se =_se[st_racialanimus_raw]
			
			assert `corr_manual' == `corr'
			di "`corr'"
			di "`se'"
			
			count
			local count =`r(N)'
			scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id(racialanimus_raw corr) num(`corr')
			scalarout using "${scalar}/`kir'_signal_corr`pov'.csv", ///
					id(racialanimus_raw se) num(`se')

		}


		*merge these files together in order to create the table
		foreach kir of local kir_vars {
			
			import delimited "${scalar}/`kir'_signal_corr`pov'.csv", clear
			rename v1 covariate
			rename v2 `kir'
			
			tempfile `kir'_corrs
			save ``kir'_corrs'
			
			erase "${scalar}/`kir'_signal_corr`pov'.csv"
		}

		*get to use get token!

		gettoken first kir_vars:kir_vars
		di "`first'"
		di "`kir_vars'"

		use ``first'_corrs', clear

		foreach kir of local kir_vars {
			merge 1:1 covariate using ``kir'_corrs', assert(3) nogen

		}
			

		*clean up the variable names
		gen covariate_name=""

		replace covariate_name="Share Black (2010)" if regex(covariate, "black_share2010")==1
		replace covariate_name="Share College Educated (2000)" if regex(covariate, "college_share2000")==1
		replace covariate_name="Share Divorced (2000)" if regex(covariate, "divorced_share2000")==1
		replace covariate_name="Employment Rate" if regex(covariate, "emp_rate_pooled_pooled")==1
		replace covariate_name="Share Foreign Born (2000)" if regex(covariate, "foreign_share2000")==1

		replace covariate_name="Average Math Score (2013)" if regex(covariate, "gsmn_math")==1
		replace covariate_name="3rd Grade Math Score (2013)" if regex(covariate, "gsmn_math_g3_2013")==1
		replace covariate_name="8th Grade Math Score (2013)" if regex(covariate, "gsmn_math_g8_2013")==1
		replace covariate_name="Average ELA Score (2013)" if regex(covariate, "gsmn_ela")==1
		replace covariate_name="Average Test Score (2013)" if regex(covariate, "gsmn_avg")==1
		replace covariate_name="Average STD Test Score (2013)" if regex(covariate, "gsmn_std_avg")==1

		replace covariate_name="Mean Household Income (2000)" if regex(covariate, "hhinc_mean2000")==1
		replace covariate_name="IAT Score for White" if regex(covariate, "iat_total_white")==1
		replace covariate_name="IAT Score for Black" if regex(covariate, "iat_total_black")==1
		replace covariate_name="IAT Score White - Black " if regex(covariate, "iat_total_diff")==1
		replace covariate_name="Lead Share in Housing Stock (2010)" if regex(covariate, "lead_share2010")==1
		replace covariate_name="Share Married (2000)" if regex(covariate, "married_share2000")==1
		replace covariate_name="Share Less Than HS Educatued (2000)" if regex(covariate, "nohs_share2000")==1
		replace covariate_name="Share Working in Manufacturing (2010)" if regex(covariate, "pct_manufacturing2010")==1
		replace covariate_name="Share in Poverty (2010)" if regex(covariate, "poor_share2010")==1
		replace covariate_name="Share in Poverty (2000)" if regex(covariate, "poor_share2000")==1
		replace covariate_name="Population Density (2000)" if regex(covariate, "popdensity2000")==1
		replace covariate_name="Population (2000)" if regex(covariate, "pop2000")==1
		replace covariate_name="Interracial Marriage Attitudes" if regex(covariate, "race_attitude")==1
		replace covariate_name="Racial Animus Index" if regex(covariate, "racialanimus")==1
		replace covariate_name="Median 2 Bedroom Rent (2015)" if regex(covariate, "rent_twobed")==1
		replace covariate_name="Share Married (2000)" if regex(covariate, "married_share2000")==1

		replace covariate_name="Share of Population Younger than 18 (2000)" if regex(covariate, "share_kids2000")==1

		replace covariate_name="Share who Own Home (2010)" if regex(covariate, "share_owner2010")==1
		replace covariate_name="Share Single Parents (2000)" if regex(covariate, "singleparent_share2000")==1
		replace covariate_name="HS Suspension Rate (2013)" if regex(covariate, "total_rate_suspension")==1
		replace covariate_name="Black Father Presence (p25)" if regex(covariate, "has_dad_black_pooled_p25")==1
		replace covariate_name="White Father Presence (p25)" if regex(covariate, "has_dad_white_pooled_p25")==1
		replace covariate_name="Black Mother Presence (p25)" if regex(covariate, "has_mom_black_pooled_p25")==1
		replace covariate_name="White Mother Presence (p25)" if regex(covariate, "has_mom_white_pooled_p25")==1

		replace covariate_name="Share Black in Poverty (2000)" if regex(covariate, "poor_share_black2000")==1
		replace covariate_name="Share White in Poverty (2000)" if regex(covariate, "poor_share_white2000")==1
		replace covariate_name="Median Home Value Black (2000)" if regex(covariate, "median_value_black2000")==1
		replace covariate_name="Median Home Value White (2000)" if regex(covariate, "median_value_white2000")==1

		replace covariate_name="Share Adults 18-64 Insured Black (2008-2012)" if regex(covariate, "share_insured_18_64_black") == 1
		replace covariate_name="Share Adults 18-64 Insured White (2008-2012)" if regex(covariate, "share_insured_18_64_white")==1
		replace covariate_name="Share Adults 18-64 Insured Black-White (2008-2012)" if regex(covariate, "insured_gap")==1
		replace covariate_name="Share Adults 18-64 Insured (2008-2012)" if regex(covariate, "share_insured_18_64_all") == 1

		replace covariate_name = covariate if missing(covariate_name)

		replace covariate_name = covariate_name + " SE" if regex(covariate, " se")==1



		*format these for the table
		foreach var of varlist kir_* black_* {
			format `var' %5.3f
			tostring `var', replace force format(%5.3f)
			replace `var'="("+`var'+")" if regex(covariate_name, "SE")
			}
		order covariate_name kir_white_`gender'_p25 kir_black_`gender'_p25 black_white_gap_p25 ///
					kir_white_`gender'_p75 kir_black_`gender'_p75 black_white_gap_p75
		order covariate, last



		export delimited "${final}/sig_corr_`gender'`pov'_mskd.txt", replace
	}
}