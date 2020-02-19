cap program drop inflate
program define inflate 

	syntax , var(varname) yearvar(varname)

	*if the set up is good then proceed to the scaling factors
		local scale1959 =	8.129923
		local scale1960 =	8.010385
		local scale1961 =	7.925553
		local scale1962 =	7.833426
		local scale1963 =	7.736254
		local scale1964 =	7.635308
		local scale1965 =	7.516644
		local scale1966 =	7.298465
		local scale1967 =	7.100741
		local scale1968 =	6.811609
		local scale1969 =	6.460352
		local scale1970 =	6.101367
		local scale1971 =	5.853946
		local scale1972 =	5.668421
		local scale1973 =	5.334547
		local scale1974 =	4.805419
		local scale1975 =	4.402921
		local scale1976 =	4.162539
		local scale1977 =	3.909606
		local scale1978 =	3.632452
		local scale1979 =	3.265037
		local scale1980 =	2.876641
		local scale1981 =	2.606165
		local scale1982 =	2.454978
		local scale1983 =	2.379788
		local scale1984 =	2.280185
		local scale1985 =	2.202484
		local scale1986 =	2.160486
		local scale1987 =	2.085849
		local scale1988 =	2.003697
		local scale1989 =	1.912087
		local scale1990 =	1.813794
		local scale1991 =	1.74042
		local scale1992 =	1.689046
		local scale1993 =	1.640334
		local scale1994 =	1.598834
		local scale1995 =	1.555205
		local scale1996 =	1.510836
		local scale1997 =	1.476326
		local scale1998 =	1.453835
		local scale1999 =	1.422635
		local scale2000 =	1.376299
		local scale2001 =	1.338596
		local scale2002 =	1.317572
		local scale2003 =	1.287974
		local scale2004 =	1.254509
		local scale2005 =	1.21366
		local scale2006 =	1.175775
		local scale2007 =	1.142966
		local scale2008 =	1.100964
		local scale2009 =	1.104503
		local scale2010 =	1.086718
		local scale2011 =	1.053637
		local scale2012 =	1.032237
		local scale2013 =	1.017336
		local scale2014 =	1.001197
		local scale2015 =	1
		local scale2016 =	.9874088
		local scale2017 =	.9667013

		*loop over the years
		qui summ `yearvar'
		local min `r(min)'
		local max `r(max)'
		assert `min'>=1959
		assert `max'<=2017
		
		qui gen adj_`var'=.
		forval year=`min'/`max' {
			qui replace adj_`var' = `var' * `scale`year'' if `yearvar'==`year'
		}
		*check that the values are right
		di "check count"
		qui count if !missing(`var')
		local count_orig =`r(N)'
		qui count if !missing(adj_`var')
		local count_adj = `r(N)'
		assert `count_orig' == `count_adj'
		di "all populated, dropping old var"
		*all good
		drop `var'
		rename adj_`var' `var'
		
		
		
	
	

end


