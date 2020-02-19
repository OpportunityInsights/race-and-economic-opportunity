/*

This .do file builds the results for the national/geographic analysis of racial gaps. 

*/

clear
set more off

*------------------------------------------------------------------------------
* Set convenient globals
*------------------------------------------------------------------------------

* Set cohorts to be included in the data
global fcohort 1978
global lcohort 1991

* Set by variables to produce the geographic collapse at
#delimit ;
global geoby 
	`""par_state par_county par_tract gender kid_race"
	"par_cz gender kid_race""';
#delimit cr

* Variables to set to -9 if missing in build
global setmiss ///
	par_state		par_county		par_tract ///
	par_block		kid_state		kid_county ///
	kid_tract		kid_race
	
* Variables to include in the national percentile collapse
global pctilevars ///
	par_married			kfr					kir ///
	kfi					kii					kid_working ///
	mom_teen			has_mom				has_dad ///
	two_par				two_par_census		kid_teenbirth ///
	par_inc				kir_inrace			kfr_inrace ///
	par_rank_inrace		kid_somecoll		kid_hs ///
	kid_jail			dad_jail			kid_hours ///
	kid_pos_hours		kid_wage			kid_wage_rank ///
	mom_native			kir_2par			kir_2par25 ///
	kir_1par			kir_somecoll		kir_native ///
	kfr_native 			kid_married			kir_par_nohome ///
	kir_working			kir_everwork		spouse_rank ///
	kir_everwork_1par	kir_everwork_2par 	kir_everwork_nodad ///
	kir_dad				kir_nodad			kir_everwork_dad ///
	kid_wageflex		kid_wageflex_rank	kid_weeks_worked ///
	kid_hours_yr

* Continuous variables for masking
global pctilecont ///
	par_married			kfr					kir ///
	kfi					kii					par_inc ///
	kir_inrace			kfr_inrace 			par_rank_inrace ///
	kid_hours 			kid_wage			kid_wage_rank ///
	kir_2par			kir_2par25 			kir_1par ///
	kir_somecoll		kir_native 			kfr_native ///
	kir_par_nohome 		spouse_rank 		kir_everwork_nodad ///
	kir_dad				kir_nodad			kir_everwork_dad ///
	kid_wageflex		kid_wageflex_rank	kid_weeks_worked ///
	kid_hours_yr

* Rate variables for masking
local v1 ${pctilevars}
local v2 ${pctilecont}
local v3: list v1-v2
global pctilerate `v3'

* Outcome variables to run gap regressions on
global regvars ///
	kir		kfr		kir_native
	
* List of outcome variables to appear in the tract data
global geovars ///
	kfr					kir					kir_working ///
	kid_working			has_mom				has_dad ///
	two_par				two_par_census		kid_jail ///
	kir_2par			kir_1par			kir_everwork ///
	par_married			kir_everwork_1par	kir_everwork_2par ///
	kir_dad				kir_nodad			kir_everwork_dad ///
	kir_everwork_nodad	kid_married
	
* List of continuous outcome variables to appear in the tract data
global geocont ///
	kfr					kir					kir_working ///
	kir_2par			kir_1par			kir_everwork ///
	par_married			kir_everwork_1par	kir_everwork_2par ///
	kir_dad				kir_nodad			kir_everwork_dad ///
	kir_everwork_nodad	
	
* Rate variables for masking
local v1 ${geovars}
local v2 ${geocont}
local v3: list v1-v2
global georate `v3'
	
*------------------------------------------------------------------------------
* Individual files
*------------------------------------------------------------------------------

* Make work data to be used to produce main results
do "${code}/build data/national analysis/indiv/make_work.do"

* Produce national collapse by parent percentile
do "${code}/build data/national analysis/indiv/pctile_collapse.do"

* Produce regressions on earnings gaps by race
do "${code}/build data/national analysis/indiv/conditional_gaps.do"

* Produce geographic level data
do "${code}/build data/national analysis/indiv/geo_collapse.do"

* Mask tract-level mobility
do "${code}/build data/national analysis/indiv/mask_tract_mobility.do"

* Build tract race gender dataset 
do "${code}/build data/national analysis/indiv/build_tract_race_gender.do"

* Summary statistics
do "${code}/build data/national analysis/indiv/sum_stats.do"

* Produce occupation distribution among blacks and whites
do "${code}/build data/national analysis/indiv/occupation.do"

* National rank-rank slopes by cohort
do "${code}/build data/national analysis/indiv/rank_rank.do"

* Kid neighborhood quality collapse
do "${code}/build data/national analysis/indiv/nbhd_quality.do"

* Produce national transition matrix by race
do "${code}/build data/national analysis/indiv/transition_matrix.do"

* Produce education transition matrix by race
do "${code}/build data/national analysis/indiv/edu_transition_matrix.do"

* Percentile cutoffs
do "${code}/build data/national analysis/indiv/pctile_cutoffs.do"

* Tract gender counts
do "${code}/build data/national analysis/indiv/gender_count.do"

* Parent individual income regressions
do "${code}/build data/national analysis/indiv/par_indv_rank.do"

* Produce appendix data quality tables
do "${code}/build data/national analysis/indiv/data_quality.do"

* Rank-rank slopes for immigrants by place of birth 
do "${code}/build data/national analysis/indiv/robustness_par_immig.do"

* Check robustness of has_dad results for blacks with native-born mothers and with fathers present in data 
do "${code}/build data/national analysis/indiv/check_black_imm_native_has_dad.do"

* Check robustness of tract-level correlations restricting to native-born mothers 
do "${code}/build data/national analysis/indiv/check_black_native_corrs.do"

* Masking
do "${code}/build data/national analysis/indiv/masking.do"

* SCF correction 
do "${code}/build data/national analysis/indiv/scf_correction.do"

* Prepare CZ estimates for mapping 
do "${code}/build data/national analysis/indiv/cz_maps.do"

* Prepare CZ-level variables  
do "${code}/build data/national analysis/indiv/cz_collapse.do"

* Run tract-level correlations
do "${code}/build data/national analysis/indiv/tract_correlations.do"
