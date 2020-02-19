
*------------------------------------------------------------------------------
* Define masking program
*------------------------------------------------------------------------------

*Program takes in raw census racecodes and assigns an aggregated race
*The raw race variables must be strings

cap program drop makerace
program define makerace

	syntax, r1(varname) r2(varname) h(varname) gname(name)
	
	*Generate kid race and hispanic variable
	destring `r1', gen(race1) force
	g tmp_race = .
	replace tmp_race=1 if race1>=100 & race1<200 // White alone
	replace tmp_race=2 if race1>=200 & race1<300 // Black alone
	replace tmp_race=3 if (race1>=300 & race1<400) | ///
		(mi(race1) & `r1'~="000" & ~missing(`r1')) // AIAN alone (letters in race code)
	replace tmp_race=4 if race1>=400 & race1<500 // Asian alone
	replace tmp_race=5 if race1>=500 & race1<600 // NHPI alone
	replace tmp_race=6 if race1>=600 & race1<1000 // SOR alone
	replace tmp_race=7 if `r1'~="000" & ~mi(`r1') & ///
		`r2'~="000" & ~mi(`r2') // Two or more races
		
	*Kid hispanic origin
	destring `h', gen(hisp) 
	g tmp_hisp = .
	replace tmp_hisp = 1 if hisp>=200 & hisp<300
	replace tmp_hisp = 0 if ~mi(hisp) & (hisp<200|hisp>=300)

	*Create a more aggregate race variable
	g `gname'=.
	replace `gname'=1 if tmp_hisp==0 & tmp_race==1 // White non-hispanic
	replace `gname'=2 if tmp_hisp==0 & tmp_race==2 // Black non-hispanic
	replace `gname'=3 if tmp_hisp==0 & tmp_race==4 // Asian non-hispanic
	replace `gname'=4 if tmp_hisp==1 // Hispanic
	replace `gname'=5 if tmp_hisp==0 & tmp_race==3 // AIAN
	replace `gname'=6 if tmp_hisp==0 & (tmp_race==5|tmp_race==6|tmp_race==7)
	drop `r1' `r2' `h' tmp_hisp tmp_race hisp race1
	
	label define races ///
		1 "White" 2 "Black" 3 "Asian" 4 "Hispanic" 5 "AIAN" 6 "Other", replace
	label values `gname' races
	
end


