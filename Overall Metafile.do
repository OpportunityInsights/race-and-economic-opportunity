/*

This .do file runs over all the files required to replicate the results in 
"Race and Economic Opportunity in the United States: An Intergenerational Perspective". 
Please see the Read Me for details on the structure of the code. 

*/

* ----------------------------
* Set globals
* ----------------------------
* globals for reading in data
global raw ""
global in ""
global ext ""

* globals for derived data
global work ""
global out ""
global final ""

* globals for output 
global figures ""
global tables ""
global online_data_tables ""
global scalar ""

* globals for code location
global code ""

* global for suffix 
global suf ""

* set adopath 
adopath + "${code}/ado"

* erase scalarout file
cap erase "${scalar}"

* ----------------------------
* Build data
* ----------------------------
do "${build_code}/national analysis/build national analysis.do"
do "${build_code}/movers/build movers.do"

* ----------------------------
* Create figures
* ----------------------------
do "${code}/figures/create figures.do"

* ----------------------------
* Create tables
* ----------------------------
do "${code}/tables/create tables.do"