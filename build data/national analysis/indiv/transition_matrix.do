/*

This .do files produces national quintile-quintile transition matrices by race. 

*/


*------------------------------------------------------------------------------
* Rearrange data
*------------------------------------------------------------------------------

use ///
	kid_pik			gender			kid_race ///
	par_rank		kfr 			kir ///
	par_state		par_county		par_tract ///
	cohort 			mom_native ///
	using "${work}/race_work_78_83", clear
	
*Generate string version of the mom_native variable
rename mom_native tmp
g mom_native="Native" if tmp==1
replace mom_native="Immig" if tmp==0
drop tmp
	
*Generate quintiles for each income concept
rename par_rank par
foreach v in par kfr kir {
	g `v'_q=ceil(`v'*5)
}

*Generate probabilities conditional on parent income
foreach inc in kir kfr {
	forvalues i=1/5 {
		forvalues j=1/5 {
			g byte `inc'_q`i'_cond_par_q`j'=`inc'_q==`i' if par_q==`j'
		}
	}
}

*Generate marginals
foreach inc in kir kfr par {
	forvalues i=1/5 {
		g byte `inc'_q`i'=`inc'_q==`i'
	}
}
drop par_q kfr_q kir_q

*Expand for pooled rows
expand 3
bysort kid_pik: g row_id=_n

*By race pooling genders
replace gender="P" if row_id==2

*Pooling both
replace gender="P" if row_id==3
replace kid_race=0 if row_id==3

*Row ID 1 is by race and gender
drop row_id

*Save the input data
tempfile matrix
save `matrix'

expand 2, gen(id)
replace mom_native="xx" if id==0
drop if mom_native~="Native" & id==1

*------------------------------------------------------------------------------
* Collapse 
*------------------------------------------------------------------------------

collapse ///
	(mean) kir_q* kfr_q* par_q* ///
	(count) count=cohort, ///
	by(kid_race gender mom_native)
order kid_race gender mom_native count
sort kid_race gender mom_native
compress
save "${out}/transition_matrix", replace
