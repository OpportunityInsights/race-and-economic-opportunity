/*

This .do file rearranges the data for graphing in Appendix Figure 16. 

*/

* Read in the data 
use "${final}/tract_race_gender_mskd", clear

* merge on poverty share
merge 1:1 state county tract using "${ext}/tract_covars", keepusing(poor_share2000) nogen

summ kir_white_male_p25 [w=kir_white_male_n],d

gen high_black= kir_black_male_p25>0.5 if kir_black_male_p25 < .

binscatter high_black poor_share2000 if kir_black_male_n>50 & kir_black_male_n<. ///
	[w=kir_black_male_n], ///
	xline(0.1) nq(50) line(none) ytitle("% of Tracts with Mean Rank of Low-Inc. Black Males > p50") ///
	title(${title_size}) xtitle("Share in Poverty (2000)") savedata("${final}/bin_black_rank_median_poor_share")

import delimited "${final}/bin_black_rank_median_poor_share.csv", clear

chopper, vars(poor_share2000 high_black)
save "${final}/bin_black_rank_median_poor_share", replace