/*

This .do file produces the movers results. 

*/

clear
set more off

*------------------------------------------------------------------------------
* Set convenient globals
*------------------------------------------------------------------------------
* Birth cohorts of interest
global fcohort 1978
global lcohort 1991

* Minimum count for place estimates in hockey stick regressions
global mincount 25

* Minimum move distance requirement for one-time movers
global mindist 100

*------------------------------------------------------------------------------
* Individual files
*------------------------------------------------------------------------------
* Prepare the long geography file that is the basis for determining one-time movers
do "${code}/build data/movers/indiv/make_long.do"

*Make an invariant file with the variables of interest
do "${code}/build data/movers/indiv/make_invariant.do"

*Make a file of one-time movers
do "${code}/build data/movers/indiv/make_movers.do"

*Make exposure-weighted CZ estimates using permanent residents and multiple movers
do "${code}/build data/movers/indiv/make_xw_estimates.do"

*Make standard hockey sticks
do "${code}/build data/movers/indiv/hs_standard.do" 

*Make placebo hockey sticks
do "${code}/build data/movers/indiv/hs_placebo.do"

* Make exposure hockey sticks 
do "${code}/build data/movers/indiv/hs_exposure_effects.do"

*Mask results for DRB submission
do "${code}/build data/movers/indiv/masking.do"