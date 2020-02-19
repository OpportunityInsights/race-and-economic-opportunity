/*

This .do file creates tables of summary statistics. 

*/

set more off

*------------------------------------------------------------------------------
* Summary statistics for kids' outcomes and parents' incomes
*------------------------------------------------------------------------------

use ///
	kid_pik			kid_race			gender ///
	cohort			kir					kii ///
	kfr				kfi					par_rank ///
	kid_pos_hours	kir_working 		kid_hours_yr ///
	kid_wageflex	kid_wageflex_rank 	kid_married ///
	kid_hs			kid_somecoll		kid_jail ///
	mom_native ///
	using "${work}/race_work_78_83", clear
	
*Generate dropout variable
g kid_dropout=1-kid_hs
	
*Dummy for being in q5 and q5|q1 for both income defs
foreach i in kir kfr {
	g `i'_q5=`i'>.8
	g `i'_q5_cond_par_q1=`i'_q5 if par_rank<=.2
}

*Generate string version of the mom_native variable
rename mom_native tmp
g mom_native="Native" if tmp==1
replace mom_native="Immig" if tmp==0
drop tmp

*Expand the dataset to 3 rows per kid - one for each set of by variables
expand 6
bysort kid_pik: g row_id=_n

*Pooling race, gender, and mom's native status
replace kid_race=0 if row_id==1
replace gender="P" if row_id==1
replace mom_native="xx" if row_id==1

*By gender pooling race and mom's native status
replace kid_race=0 if row_id==2
replace mom_native="xx" if row_id==2

*By race pooling gender and mom's native status
replace gender="P" if row_id==3
replace mom_native="xx" if row_id==3

*By race and gender pooling mom's native status
replace mom_native="xx" if row_id==4

*Pooling race and gender - keep only those with native moms
replace kid_race=0 if row_id==5
replace gender="P" if row_id==5
drop if row_id==5 & mom_native!="Native"

*By race pooling gender - keep only those with native moms
replace gender="P" if row_id==6
drop if row_id==6 & mom_native!="Native"

drop row_id	

*Produce collapse
collapse ///
	(mean)		mean_kir=kir		mean_kfr=kfr			*_q5_cond_par_q1 ///
				mean_kii=kii		mean_kfi=kfi			kid_pos_hours ///
				kir_working			kid_hours=kid_hours_yr	mean_kid_wageflex=kid_wageflex ///
				mean_kid_wageflex_rank = kid_wageflex_rank	kid_married ///
				kid_dropout			kid_somecoll			kid_jail ///
				kir_q5				kfr_q5 ///
	(median)	med_kii=kii			med_kfi=kfi				med_kid_wageflex=kid_wageflex ///
	(count)		count=cohort		acs_count=kid_dropout, ///
	by(kid_race gender mom_native)
	
*CLean and output
order kid_race gender mom_native count acs_count
sort kid_race gender mom_native count acs_count
compress	
save "${out}/baseline_sum_stats", replace

*------------------------------------------------------------------------------
* Summary statistics for parents and their neighborhoods
*------------------------------------------------------------------------------

*Make an extract of our tract-level data for a later merge 
use ///
	par_state		par_county		par_tract ///
	par_rank		gender 			kid_race ///
	two_par ///
	if kid_race==0 & gender=="P" ///
	using "${out}/tract_mobility", clear
rename (par_rank two_par) (par_rank_tract two_par_tract)
tempfile pooled
save `pooled'

use ///
	par_state		par_county		par_tract ///
	kid_race		two_par			kid_race ///
	gender ///
	if kid_race!=0 & gender=="P" ///
	using "${out}/tract_mobility", clear
rename two_par two_par_tract_race
tempfile byrace
save `byrace'

use ///
	kid_pik			kid_race		gender ///
	cohort			par_rank		par_inc ///
	has_dad			has_mom			two_par ///
	dad_hs			dad_somecoll		mom_hs ///
	mom_somecoll		par_homeowner ///
	par_homevalue		par_mortgage		par_vehicles ///
	mom_native		dad_native		par_state ///
	par_county		par_tract ///
	using "${work}/race_work_78_83", clear
	
*Generate high school dropout rates
g mom_dropout=1-mom_hs
g dad_dropout=1-dad_hs
		
* Merge in tract single parent share and mean parent rank
merge m:1 par_state par_county par_tract using `pooled', nogen keep(1 3) ///
	keepusing(par_rank_tract two_par_tract)

* Merge in race-specific single parent share
merge m:1 par_state par_county par_tract kid_race using `byrace', nogen keep(1 3) ///
	keepusing(two_par_tract_race)

* Merge in poverty rate and share white from external covariates 
merge2 m:1 par_state par_county par_tract using "${ext}/covariates", nogen keep(1 3) ///
	using_keys(state county tract) keepusing(poor_share2000 share_white2000)
	
* Expand to include a pooled race row
expand 2, gen(id)
replace kid_race=0 if id==1
drop id

* Produce collapse
collapse ///
	(mean) mean_par_inc=par_inc mean_par_rank=par_rank two_par has_dad has_mom ///
		dad_dropout mom_dropout dad_somecoll mom_somecoll par_homeowner ///
		mean_mortgage=par_mortgage mean_homevalue=par_homevalue mean_vehicles=par_vehicles ///
		mom_native dad_native par_rank_tract poor_share2000 share_white2000 ///
		two_par_tract two_par_tract_race ///
	(median) med_par_inc=par_inc med_mortgage=par_mortgage med_homevalue=par_homevalue ///
		med_vehicles=par_vehicles ///
	(p25) p25_par_inc=par_inc ///
	(p75) p75_par_inc=par_inc ///
	(p99) p99_par_inc=par_inc ///
	(count) count=cohort acs_count=mom_native , ///
	by(kid_race)
	
* Clean and output
order kid_race count acs_count
sort kid_race count acs_count
compress	
save "${out}/par_sum_stats", replace