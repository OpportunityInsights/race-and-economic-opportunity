/*

This .do file converts tables previously made as .dta files to .txt files 
for convenience. 

*/

global files ///
		baseline_sum_stats_mskd ///
		dad_regressions_mskd ///
		appdx_linkage_counts_mskd ///
		appdx_sample_bias_mskd ///
		appdx_acs_tax_matrix_mskd ///
		appdx_income_quality_mskd ///
		rank_rank_cohort_mskd ///
		par_sum_stats_mskd /// 
		scf_correction ///
		sig_corr_male_mskd /// 
		sig_corr_male_lowpov_mskd /// 
		sig_corr_female_mskd 
	
foreach f of global files {
	use "${final}/`f'", clear
	export delimited "${tables}/`f'.txt", replace	
}