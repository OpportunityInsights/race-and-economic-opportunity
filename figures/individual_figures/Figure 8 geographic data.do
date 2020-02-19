/*

This .do file rearranges the black-white gap conditional on geographic controls 
for graphing. 

*/

*loop over parent income percentile
foreach p in 25 75 {
	* loop through each race (black = 2, asian = 3, hispanic = 4)
	foreach race in 2 {

	* load data
	use "${final}/cond_regressions_mskd", clear
	keep if yvar == "kir" & gender != "P" & race == `race'
	keep gender gap par_inc edu two_par wealth tract block cmdline p
	sort gap
	gen order = .

	* loop through both genders and order regressions that are relevant for figure
	*now the controls are defined in indicator variables
	foreach gender in M F{

		* tract
		replace order = 1 if gender=="`gender'" & p==`p' ///
			& par_inc == 0 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 1 ///
			& block == 0 

		* block	
		replace order = 2 if gender=="`gender'" & p==`p' ///
			& par_inc == 0 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 1 


		* par inc + tract	
		replace order = 3 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 1 ///
			& block == 0 
			
		* par inc + block	
		replace order = 4 if gender=="`gender'" & p==`p' ///
			& par_inc == 1 ///
			& edu == 0 ///
			& two_par == 0 ///
			& wealth == 0 ///
			& tract == 0 ///
			& block == 1 

	}

	* keep just relevant gapfs
	*drop cmdline
	keep if ~missing(order)

	* make xaxis (shifts bars left and right based on gender)
	gen xaxis = .
	replace xaxis = order - 0.15 if gender == "M"
	replace xaxis = order + 0.15 if gender == "F"

	* format labels
	replace gap = gap * -1 * 100
	format gap %4.1f
	gen ylab = gap

	* race labels
	if `race' == 2{
		local race_name "Black"
		local race_label "black"
		local ymin -5
		local ymax 20
		local step 5
		local leg_pos 1
		local ylab_pos 12
		replace ylab = 0 if gap < 0
		local control_text = `ymin'-2
	}

chopper, vars(ylab gap)
save "${final}/bar_kir_black_white_controls_block_tract_p`p'",replace

	}
}


