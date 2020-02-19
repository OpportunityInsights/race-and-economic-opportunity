/*

Calculates mean kid and parental income in each bin, i.e. a crosswalk 
between ranks and dollars. 

*/

set more off

* Read in the ranks and income amounts
	// Use only the 1978-1983 cohorts
use ///
	cohort			par_rank		par_inc ///
	kir			kii			kfr ///
	kfi ///
	using "${work}/race_work_78_83${suf}", clear
	
* Rename the parent income concept for loops
rename (par_rank par_inc) (pr pi)

* For each income concept, produce percentiles and get the min, mean, and max
foreach i in kf ki p {
	preserve
	g pctile=ceil(`i'r*100)
	collapse (mean) `i'i_mean=`i'i (count) `i'i_count=`i'i, by(pctile)
	
	tempfile `i'
	save ``i''
	restore
}

* Merge together resulting output
use `kf', clear
merge 1:1 pctile using `ki', nogen
merge 1:1 pctile using `p', nogen

* Clean and output
order pctile *count*
sort  pctile 
compress
save "${out}/pctile_cutoffs", replace