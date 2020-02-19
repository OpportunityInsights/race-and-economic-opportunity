/*

This .do file produces data quality statistics. 

*/

set more off

*------------------------------------------------------------------------------
* Results in Appendix Table 2 - Raw counts and linkage rates
*------------------------------------------------------------------------------

************************
* Raw counts in ACS data 
************************

*Use the raw 2015 ACS to compute number of kids - by cohort - who were either 
	// born in the US or came to the US when they were younger than 16 years old
use ///
	pik		pwgt		dby ///
	yoe ///
	using "${raw}/acs_raw_2015${suf}", clear
	
*Indicator for being born in the US or coming at a young age 
g in_samp=mi(yoe) | (yoe-dby<16)
	
*Keep only the cohorts of interest and those in the sample
keep if inrange(dby,1978,1991) & in_samp==1

*Use the person weights to generate population approximated counts
collapse (sum) pwgt, by(dby)
rename (dby pwgt) (cohort count_acs_2015)
format %ty cohort

*Put counts in terms of 1000
replace count_acs_2015=count_acs_2015/1000
tempfile acs
save `acs'

************************
* Count of children matched to parent with positive income in our data 
************************
use cohort using "${work}/race_work", clear
g tmp=1
collapse (count) count_par_pos=tmp, by(cohort)
replace count_par_pos=count_par_pos/1000
tempfile pos
save `pos'

************************
* Count of children matched to parent with positive income in our data, 
	// and not missing race and/or one childhood tract 
************************
use cohort kid_race par_tract using "${work}/race_work", clear

*Drop those with missing race
drop if kid_race==-9

*Collapse counts
g count_race=1
g count_geo=1 if par_tract~=-9
collapse (sum) count_race count_geo, by(cohort)
replace count_race=count_race/1000
replace count_geo=count_geo/1000
tempfile race
save `race'

************************
* Count of children matched to parent with positive income in our data, 
	// and not missing race and/or one childhood tract, //
	// and appear in the ACS at some point between 2005-2015 
************************

use kid_pik cohort kid_race par_block if kid_race!=-9 & par_block!=-9 ///
	using "${work}/race_work", clear

*Merge to the spine and keep only those who appear in the ACS
merge 1:1 kid_pik using "${in}/spine${suf}", keepusing(kid_acs) assert(2 3) keep(3)

*Keep only those in the ACS
keep if kid_acs==1

*Collapse counts
g count_samp_acs=1
collapse (count) count_samp_acs, by(cohort)
replace count_samp_acs=count_samp_acs/1000

************************
* Merge counts, clean output 
************************
merge 1:1 cohort using `acs', nogen
merge 1:1 cohort using `pos', nogen
merge 1:1 cohort using `race', nogen

order cohort count_acs_2015 count_par_pos count_race count_geo count_samp_acs
label var count_acs_2015 "Number of people in 2015 ACS born 1978-1983 in US or came < 16"
label var count_par_pos "And matched to parents that have positive income"
label var count_race "And race is non-missing"
label var count_geo "And have at least one valid parental tract"
label var count_samp_acs "And ever appear in the ACS" 
ds cohort, not
foreach v in `r(varlist)' {
	replace `v'=round(`v')
}
sort cohort
compress
save "${out}/appdx_linkage_counts", replace

*------------------------------------------------------------------------------
* Results in Appendix Table 3 - Characteristics of matched vs. unmatched children  
*------------------------------------------------------------------------------

* Begin in the 2015 ACS and restrict to those born in the US or came before 16
use ///
	pik		pwgt		dby ///
	yoe 		ti 		rcc1 ///
	rcc2		his 		gqt ///
	schl		mar ///
	using "${raw}/acs_raw_2015${suf}", clear
	
global clpsvars ///
	ti_rank somecoll married incarcerated count

* Assign each person a race
makerace, r1(rcc1) r2(rcc2) h(his) gname(race)

* Destring useful variables
destring schl mar gqt, replace

* Indicator for attending college
g somecoll=schl>=18 & ~mi(schl)

* Indicator for being married
g married=mar==1

* Incarcerated
g incarcerated=(gqt>=101 & gqt<=106) | (gqt==203)
drop schl mar gqt

* Indicator for being born in the US or coming at a young age 
g in_samp=mi(yoe) | (yoe-dby<16)
	
* Keep only the cohorts of interest and those in the sample
keep if inrange(dby,1978,1983) & in_samp==1

* Replace income as 0 if it is missing
replace ti=0 if mi(ti)

* Rank incomes by birth year
egen tot=count(ti), by(dby)
egen ti_rank=rank(ti), by(dby)
replace ti_rank=ti_rank/tot
drop tot

* Keep necessary variables
rename pik kid_pik
keep kid_pik pwgt race ti_rank somecoll married incarcerated

*** Collapse mean income ranks by race storing counts ***
preserve
collapse (mean) ti_rank somecoll married incarcerated (rawsum) count=pwgt [w=pwgt], by(race)
tempfile full 
save `full'
restore 

*** Repeat but cut to those appearing in dm1 ***
preserve
merge m:1 kid_pik using "${raw}/dm1_sample${suf}", nogen keep(3) 
collapse (mean) ti_rank somecoll married incarcerated (rawsum) count=pwgt [w=pwgt], by(race)
foreach v of global clpsvars {
	rename `v' `v'_dm1
}
tempfile dm1 
save `dm1'
restore

*** Repeat but cut to those appearing in our sample ***
preserve
merge m:1 kid_pik using "${work}/race_work_78_83", nogen keepusing() keep(3) 
collapse (mean) ti_rank somecoll married incarcerated (rawsum) count=pwgt [w=pwgt], by(race)
foreach v of global clpsvars {
	rename `v' `v'_final
}
tempfile final 
save `final'
restore

*** Repeat but on those not in our final sample ***
merge m:1 kid_pik using "${work}/race_work_78_83", nogen keepusing() keep(1) 
collapse (mean) ti_rank somecoll married incarcerated (rawsum) count=pwgt [w=pwgt], by(race)
foreach v of global clpsvars {
	rename `v' `v'_miss
}
tempfile miss 
save `miss'

*** Merge results together ***
use `full', clear
merge 1:1 race using `dm1', nogen
merge 1:1 race using `final', nogen
merge 1:1 race using `miss', nogen

*Foreach sample generate sample fraction
foreach s in dm1 final miss {
	egen tot=total(count_`s')
	g pct_`s'=(count_`s'/tot)*100
	drop tot
}
egen tot=total(count)
g pct=(count/tot)*100
drop tot

compress
order race ti_rank somecoll married incarcerated count pct *dm1* *final* *miss*
save "${out}/appdx_sample_bias", replace

*------------------------------------------------------------------------------
* Results in Appendix Table 4 - Comparison of income measures 
*------------------------------------------------------------------------------

*Make a temporary file of kid 2015 individual income and filing flag
clear
g kii=.
g kir=.
forvalues co=1978/1983 {
	di "Appending `co'"
	append using "${raw}/intergen_`co'${suf}", keep(kid_pik gender cohort kid_indv_inc_`=2015-`co'' kid_indv_rank_`=2015-`co'')
	replace kir=kid_indv_rank_`=2015-`co'' if cohort==`co'
	replace kii=kid_indv_inc_`=2015-`co'' if cohort==`co'
}
keep if gender=="M" | gender=="F"
drop cohort kid_indv* gender

*Keep only those who made it to our final analysis sample
merge 1:1 kid_pik using "${work}/race_work_78_83", nogen keep(3) keepusing()

tempfile inc_2015
save `inc_2015'

use ///
	pik			race			year ///
	tot_inc			married			education ///
	state 			gender 			cohort ///
	pwgt ///
	if year==2015 ///
	using "${in}/acs${suf}", clear
rename pik kid_pik

*Impute 0 if there are any missing incomes in Census data
replace tot_inc=0 if mi(tot_inc)

*Generate income ranks
egen tot=count(tot_inc), by(cohort)
egen acs_rank=rank(tot_inc), by(cohort)
replace acs_rank=acs_rank/tot
drop tot

*Merge to our data for individual income
*Keep only people in both samples
merge 1:1 kid_pik using `inc_2015', nogen keep(3) ///
	keepusing(kii kir)
	
*Rename income vars
rename (tot_inc kii kir) (acs_inc tax_inc tax_rank)

*Make marriage variable from the ACS
rename married mar
g married=mar==1
drop mar

*Indicator for being female
g female=gender=="F"

*College variable
g somecoll=education>=4 & ~mi(education)

*Indicator for living in the south
merge m:1 state using "${ext}/state_region_cw", nogen keep(1 3) ///
	keepusing(census_region)
g south=census_region=="South"

*Fraction zero and negative
assert ~mi(acs_inc) & ~mi(tax_inc)
foreach i in tax acs {
	g `i'_zero=`i'_inc==0
	g `i'_neg=`i'_inc<0
}

*Indicators for being each race
g white=race==1
g black=race==2
g asian=race==3
g hisp=race==4
g aian=race==5
g other=race==6

*Save micro data
tempfile micro
save `micro'

*Collapse and store important variables 
collapse ///
	(mean) *_zero *_neg acs_mean=acs_inc tax_mean=tax_inc ///
		married female south somecoll ///
		white black asian hisp aian other ///
	(sd) acs_sd=acs_inc tax_sd=tax_inc ///
	(p10) acs_p10=acs_inc tax_p10=tax_inc ///
	(p25) acs_p25=acs_inc tax_p25=tax_inc ///
	(p50) acs_p50=acs_inc tax_p50=tax_inc ///
	(p75) acs_p75=acs_inc tax_p75=tax_inc ///
	(p90) acs_p90=acs_inc tax_p90=tax_inc ///
	(p99) acs_p99=acs_inc tax_p99=tax_inc ///
	(rawsum) count=pwgt [w=pwgt]
g samp="full"
tempfile full_samp
save `full_samp'

*Replicate the collapse for those with zero income
use `inc_2015'
keep if kii==0

*Merge to the above micro data and keep only those who match
merge 1:1 kid_pik using `micro', nogen keep(3)


*Replicate collapse
collapse ///
	(mean) *_zero *_neg acs_mean=acs_inc tax_mean=tax_inc ///
		married female south somecoll ///
		white black asian hisp aian other ///
	(sd) acs_sd=acs_inc tax_sd=tax_inc ///
	(p10) acs_p10=acs_inc tax_p10=tax_inc ///
	(p25) acs_p25=acs_inc tax_p25=tax_inc ///
	(p50) acs_p50=acs_inc tax_p50=tax_inc ///
	(p75) acs_p75=acs_inc tax_p75=tax_inc ///
	(p90) acs_p90=acs_inc tax_p90=tax_inc ///
	(p99) acs_p99=acs_inc tax_p99=tax_inc ///
	(rawsum) count=pwgt [w=pwgt]
g samp="zero-inc"

*Append together  and output
append using `full_samp'
compress
order samp
save "${out}/appdx_income_quality", replace

*Use the full micro data to compute a transition matrix of incomes
use acs_rank tax_rank pwgt using `micro', clear

corr acs_rank tax_rank [w=pwgt]
scalarout using "${scalar}", ///
	id("Sample weighted correlation between ACS and tax income ranks") ///
	num(`=round(`r(rho)',.0001)')

*Generate quintiles
assert ~mi(acs_rank) & ~mi(tax_rank)
g acs_q=ceil(acs_rank*5)
g tax_q=ceil(tax_rank*5)

*Produce indicators for being in each acs quintile
forvalues i=1/5 {
	g acs_q`i'=acs_q==`i'
}

*Produce transition matrix
collapse (mean) acs_q* (rawsum) count=pwgt [w=pwgt], by(tax_q)

order tax_q count
compress
save "${out}/appdx_acs_tax_matrix", replace

*------------------------------------------------------------------------------
* One off numbers
*------------------------------------------------------------------------------

*** Parent age restriction ****

*Fraction of parent matches dropped because of parental age restriction
use "${work}/input_data/intergen_mini/intergen_13", clear
g claimed=~mi(pik_pe)
 
*Count fraction of claimed rows dropped from age restriction
su claim_ind if claimed==1
scalarout using "${scalar}", ///
	id("Pct. of dependent claims dropped from age restriction") ///
	num(`=100*round(1-`r(mean)',.0001)')	
	
*Fraction of kids dropped
*Keep only those who have ever been claimed
egen ever_claimed=max(claimed), by(kid_pik)
keep if ever_claimed==1
egen ever_valid_claimed=max(claim_ind), by(kid_pik)
bysort kid_pik: keep if _n==1
su ever_valid 
scalarout using "${scalar}", ///
	id("Pct. of kids claimed at least once who never match to an appropriate aged parent") ///
	num(`=100*round(1-`r(mean)',.0001)')
	
*** Race response in the surveys ****

*XX Note that nobody in the 2010 Census, 2000 Census, or ACS - who has a PIK - 
*	has a missing value for race (this is because of the imputation). Also,
*	in the raw 2015 ACS, none of the missing PIK people are missing race. 
*	Generally, race appears to have full coverage. So instead we will note the
*	imputations.

*Use the random sample of the Databank
use ///
	race1_2000		race_edit_2000		race1_2010 ///
	race_edit_2010		race1_acs		race_edit_acs ///
	race_acs_yr		yr if yr==2015 ///
	using "${raw}/db_small${suf}", clear

scalarout using "${scalar}", ///
	id("Computed only amongst those with a PIK") ///
	num(00000000000)

*Total number of people with non-missing race in 2000
count if ~mi(race1_2000)
local tot=`r(N)'
di `tot'

*Fill out data
count if race_edit_2000==0
scalarout using "${scalar}", ///
	id("2000 Census - Pct. with race assigned as reported") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2000==1
scalarout using "${scalar}", ///
	id("2000 Census - Pct. with code changed from consistency edit") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2000==3
scalarout using "${scalar}", ///
	id("2000 Census - Pct. classified with response from hispanic question") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2000==4
scalarout using "${scalar}", ///
	id("2000 Census - Pct. allocated from within household") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2000==5
scalarout using "${scalar}", ///
	id("2000 Census - Pct. allocated from hot deck") ///
	num(`=100*round(`r(N)'/`tot',.000001)')	
	

*Total number of people with non-missing race in 2010
count if ~mi(race1_2010)
local tot=`r(N)'
di `tot'

*Fill out data
count if race_edit_2010==0
scalarout using "${scalar}", ///
	id("2010 Census - Pct. with race assigned as reported") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2010==1
scalarout using "${scalar}", ///
	id("2010 Census - Pct. with code changed from consistency edit") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2010==3
scalarout using "${scalar}", ///
	id("2010 Census - Pct. classified with response from hispanic question") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2010==4
scalarout using "${scalar}", ///
	id("2010 Census - Pct. allocated from within household") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if race_edit_2010==5
scalarout using "${scalar}", ///
	id("2010 Census - Pct. allocated from hot deck") ///
	num(`=100*round(`r(N)'/`tot',.000001)')	
count if race_edit_2010==9
scalarout using "${scalar}", ///
	id("2010 Census - Pct. assigned with previous census data") ///
	num(`=100*round(`r(N)'/`tot',.000001)')	
	

*Total number of people with non-missing race in ACS
count if ~mi(race1_acs)
local tot=`r(N)'
di `tot'

*Reconcile the race ACS flag that changes year to year
/***
0 - as reported
1 - hispanic 
2 - household
3 - hotdeck
4 - consistency edit
***/

g flag=.
replace flag=0 if race_edit_acs==0 & race_acs_yr<=2007
replace flag=1 if race_edit_acs==1 & race_acs_yr<=2007
replace flag=2 if race_edit_acs==4 & race_acs_yr<=2007
replace flag=3 if race_edit_acs==5 & race_acs_yr<=2007

*Two-hispanic origin codes in these years
replace flag=0 if race_edit_acs==0 & race_acs_yr<=2009 & race_acs_yr>=2008
replace flag=1 if race_edit_acs==1 & race_acs_yr<=2009 & race_acs_yr>=2008
replace flag=2 if race_edit_acs==5 & race_acs_yr<=2009 & race_acs_yr>=2008
replace flag=3 if race_edit_acs==6 & race_acs_yr<=2009 & race_acs_yr>=2008
replace flag=1 if race_edit_acs==7 & race_acs_yr<=2009 & race_acs_yr>=2008

replace flag=0 if race_edit_acs==0 & race_acs_yr<=2015 & race_acs_yr>=2010
replace flag=1 if race_edit_acs==2 & race_acs_yr<=2015 & race_acs_yr>=2010
replace flag=2 if race_edit_acs==5 & race_acs_yr<=2015 & race_acs_yr>=2010
replace flag=3 if race_edit_acs==7 & race_acs_yr<=2015 & race_acs_yr>=2010
replace flag=4 if race_edit_acs==1 & race_acs_yr<=2015 & race_acs_yr>=2010


*Fill out data
count if flag==0
scalarout using "${scalar}", ///
	id("ACS - Pct. with race assigned as reported") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if flag==4
scalarout using "${scalar}", ///
	id("ACS - Pct. with code changed from consistency edit") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if flag==1
scalarout using "${scalar}", ///
	id("ACS - Pct. classified with response from hispanic question") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if flag==2
scalarout using "${scalar}", ///
	id("ACS - Pct. allocated from within household") ///
	num(`=100*round(`r(N)'/`tot',.000001)')
count if flag==3
scalarout using "${scalar}", ///
	id("ACS - Pct. allocated from hot deck") ///
	num(`=100*round(`r(N)'/`tot',.000001)')	

*------------------------------------------------------------------------------
* Claiming discrepencies between 2000 Census and tax records
*------------------------------------------------------------------------------

use "${raw}/claiming_2000${suf}", clear
rename pik kid_pik

count
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank") ///
	num(`r(N)')	
	
count if ~mi(claimer_pik_p)
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank claimed in 2000") ///
	num(`r(N)')
	
count if ~mi(claimer_pik_s)
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank claimed by two people in 2000") ///
	num(`r(N)')

*Keep only the kids who are claimed
keep if ~mi(claimer_pik_p)

*Match to the 2000 census data
merge2 1:1 kid_pik using "${in}/2000_short${suf}", using_keys(pik) keep(1 3) keepusing(mafid)
g kid_2000=_merge==3
rename mafid kid_mafid
drop _merge

merge2 m:1 claimer_pik_p using "${in}/2000_short${suf}", using_keys(pik) keep(1 3) keepusing(mafid)
g p_2000=_merge==3
rename mafid p_mafid
drop _merge

merge2 m:1 claimer_pik_s using "${in}/2000_short${suf}", using_keys(pik) keep(1 3) keepusing(mafid)
g s_2000=_merge==3
rename mafid s_mafid
drop _merge

count if kid_2000==1
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank claimed in 2000 and appearing in 2000 Census") ///
	num(`r(N)')
	
count if p_2000==1
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank claimed in 2000 and primary claimer appearing in 2000 Census") ///
	num(`r(N)')

count if s_2000==1 & ~mi(claimer_pik_s)
scalarout using "${scalar}", ///
	id("Total born 1984-1999 Databank claimed in 2000 by two people and secondary claimer appearing in 2000 Census") ///
	num(`r(N)')
	
*Keep only people where kid and all parents appear in Census
keep if kid_2000==1
keep if (mi(claimer_pik_s) &  p_2000==1) | (~mi(claimer_pik_s) & p_2000==1 & s_2000==1)

count 
scalarout using "${scalar}", ///
	id("Total number of kids with all parents appearing in Census") ///
	num(`r(N)')
	
count if ~mi(claimer_pik_s)
scalarout using "${scalar}", ///
	id("Total number of kids with all parents appearing in Census and have 2 parents") ///
	num(`r(N)')

*Generate an indicator for living with all your parents
g same_match= ///
	(mi(claimer_pik_s) & p_mafid==kid_mafid) | ///
	(~mi(claimer_pik_s) & kid_mafid==p_mafid & kid_mafid==s_mafid)

su same_match if ~mi(claimer_pik_s)
scalarout using "${scalar}", ///
	id("Pct. address match amongst two parent households") ///
	num(`=100*round(`r(mean)',.0001)')	

su same_match if mi(claimer_pik_s)
scalarout using "${scalar}", ///
	id("Pct. address match amongst one parent households") ///
	num(`=100*round(`r(mean)',.0001)')	

	
*Cohabitation rates in the 2010 Census for kids in our sample
use kid_pik kid_race using "${work}/race_work_78_83", clear

*Merge on the 2010 Census
merge2 1:1 kid_pik using "${in}/2010_short${suf}", using_keys(pik) nogen keep(3) keepusing(married cohabitate)

*Generate a cohabitation indicator
g cohab=cohabitate==1
g mar=married==1

*Loop over racees to compute rates
forvalues r=1/2 {
	foreach i in cohab mar {
		su `i' if kid_race==`r'
		scalarout using "${scalar}", ///
		id("Pct. `i' for race `r' in 2010 Census in our sample") ///
		num(`=100*round(`r(mean)',.0001)')
	}
}

*Black white overlap in tracts and blocks
use ///
	kid_race	par_state	par_county ///
	par_tract	par_block  ///
	if kid_race~=-9 ///
	using "${work}/race_work_78_83", clear

*Produce counts
g white=kid_race==1
g black=kid_race==2
preserve
collapse ///
	(mean) black_share=black white_share=white ///
	(sum) black_count=black white_count=white, ///
	by(par_state par_county par_tract par_block)
g white_tract=white_share>.25

su white_share 
scalarout using "${scalar}", ///
	id("Mean pct. white at block level") ///
	num(`=100*round(`r(mean)',.0001)')	

su white_share [w=black_count]
scalarout using "${scalar}", ///
	id("Mean pct. white - weighted by black pop - at block level") ///
	num(`=100*round(`r(mean)',.0001)')
	
su white_tract [w=black_count]
scalarout using "${scalar}", ///
	id("Pct. of black kids living in >25% white block") ///
	num(`=100*round(`r(mean)',.0001)')
restore

*Repeat at the tract level
collapse ///
	(mean) black_share=black white_share=white ///
	(sum) black_count=black white_count=white, ///
	by(par_state par_county par_tract)
g white_tract=white_share>.25

su white_share 
scalarout using "${scalar}", ///
	id("Mean pct. white at tract level") ///
	num(`=100*round(`r(mean)',.0001)')	

su white_share [w=black_count]
scalarout using "${scalar}", ///
	id("Mean pct. white - weighted by black pop - at tract level") ///
	num(`=100*round(`r(mean)',.0001)')
	
su white_tract [w=black_count]
scalarout using "${scalar}", ///
	id("Pct. of black kids living in >25% white tract") ///
	num(`=100*round(`r(mean)',.0001)')

*------------------------------------------------------------------------------
* Concordance between ACS and tax data marriage variable
*------------------------------------------------------------------------------

use ///
	kid_pik			kid_race		kid_married ///
	kfr 			kir ///
	using "${work}/race_work_78_83", clear
	
	
*Merge on the acs variables
merge2 1:1 kid_pik using "${in}/acs${suf}", nogen keep(3) using_keys(pik)

*Keep only those in the 2015 ACS
keep if year==2015

*Look at similarities in marriage rates
g acs_married=married==1
tab acs_married kid_married, col

*Show that the differences are concentrated at the bottom
binscatter kid_married acs_married kir, n(50)