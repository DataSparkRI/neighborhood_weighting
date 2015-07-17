**********************
Create a population-weighted nhood-tract file for joining ACS tract data to convert to nhood level
**********************.




*
Can jump to line 112 to get the already created weighted tract file!
*.



*********
Get block-nhood-tract crosswalk file
*********.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\HCTI\pvdblock2010_forHCTI.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  block_fips_code A15
  block_population F3.0
  census_tract A11
  zcta A5
  census_block_group A12
  neighborhood A25.
CACHE.
EXECUTE.
DATASET NAME block_walk WINDOW=FRONT.


*********
Add field to create nhood-tract field for aggregation purposes
*********.
STRING nhood_tract (A40).
COMPUTE nhood_tract = CONCAT(RTRIM(neighborhood)," ",RTRIM(census_tract)).
EXECUTE.


*********
Aggregate blocks to nhood-tract; sum populations
*********.
DATASET ACTIVATE block_walk.
DATASET DECLARE nhood_tract.
SORT CASES BY nhood_tract.
AGGREGATE
  /OUTFILE='nhood_tract'
  /PRESORTED
  /BREAK=nhood_tract
  /block_population_sum=SUM(block_population) 
  /census_tract_first=FIRST(census_tract) 
  /neighborhood_first=FIRST(neighborhood)
  /N_BREAK=N.


*********
Aggregate population to tract
*********.
DATASET ACTIVATE block_walk.
DATASET DECLARE tract_pop.
SORT CASES BY census_tract.
AGGREGATE
  /OUTFILE='tract_pop'
  /PRESORTED
  /BREAK=census_tract
  /block_population_sum=SUM(block_population)
  /N_BREAK=N.


*********
Merge tract pop onto nhood_tract by tract
*********.
DATASET ACTIVATE tract_pop.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract_first.
MATCH FILES /FILE=*
  /RENAME (N_BREAK = d0) census_tract_first=census_tract
  /TABLE='tract_pop'
  /RENAME (N_BREAK = d1) block_population_sum=tract_population
  /BY census_tract
  /DROP= d0 d1.
EXECUTE.
VARIABLE LABELS tract_population "P1	TOTAL POPULATION 2010 Census Summary File 1".
EXECUTE.

DATASET ACTIVATE nhood_tract.
COMPUTE nhood_tract_wght=(block_population_sum/tract_population).
FORMATS nhood_tract_wght(f5.3).
EXECUTE.
VARIABLE LABELS nhood_tract_wght "Weight to be given to the partial/complete tract portion of a neighborhood based on total pop".
EXECUTE.

FORMATS block_population_sum(f5.0).
FORMATS tract_population(f5.0).
EXECUTE.

DATASET CLOSE tract_pop.


*/Only have to save once.
*SAVE OUTFILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_tract_weights_pop.sav'
  /COMPRESSED.


*/In the future.
GET
  FILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_tract_weights_pop.sav'.
DATASET NAME nhood_tract WINDOW=FRONT.

**********************
Get data, join on tract, calculate weighted values, then create a file 
aggregated on nhood with weighted values.
**********************.

*/Educational Attainment.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Tract data\ACS_13_5YR_B15003_edu_attn_temp.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  census_tract A11
  Total F4.0
  MOE_Total F3.0
  Noschoolingcompleted F3.0
  MOE_Noschoolingcompleted F3.0
  Nurseryschool F2.0
  MOE_Nurseryschool F2.0
  Kindergarten F2.0
  MOE_Kindergarten F2.0
  @1stgrade F2.0
  MOE_1stgrade F2.0
  @2ndgrade F3.0
  MOE_2ndgrade F3.0
  @3rdgrade F3.0
  MOE_3rdgrade F3.0
  @4thgrade F3.0
  MOE_4thgrade F3.0
  @5thgrade F3.0
  MOE_5thgrade F3.0
  @6thgrade F3.0
  MOE_6thgrade F3.0
  @7thgrade F3.0
  MOE_7thgrade F3.0
  @8thgrade F3.0
  MOE_8thgrade F3.0
  @9thgrade F3.0
  MOE_9thgrade F3.0
  @10thgrade F3.0
  MOE_10thgrade F3.0
  @11thgrade F3.0
  MOE_11thgrade F3.0
  @12thgradenodiploma F3.0
  MOE_12thgradenodiploma F3.0
  Regularhighschooldiploma F4.0
  MOE_Regularhighschooldiploma F3.0
  GEDoralternativecredential F3.0
  MOE_GEDoralternativecredential F3.0
  Somecollegelessthan1year F3.0
  MOE_Somecollegelessthan1year F3.0
  Somecollege1ormoreyearsnodegree F4.0
  MOE_Somecollege1ormoreyearsnodegree F3.0
  Associatesdegree F3.0
  MOE_Associatesdegree F3.0
  Bachelorsdegree F4.0
  MOE_Bachelorsdegree F3.0
  Mastersdegree F3.0
  MOE_Mastersdegree F3.0
  Professionalschooldegree F3.0
  MOE_Professionalschooldegree F3.0
  Doctoratedegree F3.0
  MOE_Doctoratedegree F3.0.
CACHE.
EXECUTE.
DATASET NAME EduAttn WINDOW=FRONT.

*/Calculate variables.
COMPUTE Total_25o=Total.
COMPUTE LT_HS_Diploma_Equiv	=(Noschoolingcompleted +  Nurseryschool +  Kindergarten +   @1stgrade +  @2ndgrade +   @3rdgrade +   @4thgrade +
  @5thgrade +   @6thgrade +  @7thgrade +  @8thgrade +  @9thgrade +  @10thgrade +  @11thgrade +  @12thgradenodiploma ).
COMPUTE HS_Dipl_Equiv=(	Regularhighschooldiploma+GEDoralternativecredential).
COMPUTE SomeCollege=(Somecollegelessthan1year+Somecollege1ormoreyearsnodegree+Associatesdegree).
COMPUTE Bach_degree=Bachelorsdegree.
COMPUTE Masters_degree	=Mastersdegree.
COMPUTE Prof_school_degree=	Professionalschooldegree.
COMPUTE Doc_degree=Doctoratedegree.
EXECUTE.
FORMATS Total_25o to Doc_degree(F5.0).
EXECUTE.

COMPUTE HS_Grad_or_Higher=	(Regularhighschooldiploma+GEDoralternativecredential+Somecollegelessthan1year+Somecollege1ormoreyearsnodegree+Associatesdegree
+Bachelorsdegree+Mastersdegree+Professionalschooldegree+Doctoratedegree).
COMPUTE Bach_degree_or_Higher=(Bachelorsdegree+Mastersdegree+Professionalschooldegree+Doctoratedegree).
EXECUTE.
FORMATS HS_Grad_or_Higher to Bach_degree_or_Higher(F5.0).
EXECUTE.


*********
Merge Edu onto nhood_tract
*********.
DATASET ACTIVATE EduAttn.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.
MATCH FILES /FILE=*
  /TABLE='EduAttn'
  /RENAME (@10thgrade @11thgrade @12thgradenodiploma @1stgrade @2ndgrade @3rdgrade @4thgrade 
    @5thgrade @6thgrade @7thgrade @8thgrade @9thgrade Associatesdegree Bachelorsdegree Doctoratedegree 
    GEDoralternativecredential Kindergarten Mastersdegree MOE_10thgrade MOE_11thgrade 
    MOE_12thgradenodiploma MOE_1stgrade MOE_2ndgrade MOE_3rdgrade MOE_4thgrade MOE_5thgrade 
    MOE_6thgrade MOE_7thgrade MOE_8thgrade MOE_9thgrade MOE_Associatesdegree MOE_Bachelorsdegree 
    MOE_Doctoratedegree MOE_GEDoralternativecredential MOE_Kindergarten MOE_Mastersdegree 
    MOE_Noschoolingcompleted MOE_Nurseryschool MOE_Professionalschooldegree 
    MOE_Regularhighschooldiploma MOE_Somecollege1ormoreyearsnodegree MOE_Somecollegelessthan1year 
    MOE_Total Noschoolingcompleted Nurseryschool Professionalschooldegree Regularhighschooldiploma 
    Somecollege1ormoreyearsnodegree Somecollegelessthan1year Total = d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 
    d11 d12 d13 d14 d15 d16 d17 d18 d19 d20 d21 d22 d23 d24 d25 d26 d27 d28 d29 d30 d31 d32 d33 d34 d35 
    d36 d37 d38 d39 d40 d41 d42 d43 d44 d45 d46 d47 d48 d49) 
  /BY census_tract
  /DROP= d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19 d20 d21 d22 d23 d24 
    d25 d26 d27 d28 d29 d30 d31 d32 d33 d34 d35 d36 d37 d38 d39 d40 d41 d42 d43 d44 d45 d46 d47 d48 d49.    
EXECUTE.



*/Calculate weighted variables.
COMPUTE Total_25o_wtd=(nhood_tract_wght*Total_25o).
COMPUTE LT_HS_Grad_wtd	=(nhood_tract_wght*LT_HS_Diploma_Equiv).
COMPUTE HS_Grad_Equiv_wtd=(nhood_tract_wght*HS_Dipl_Equiv).
COMPUTE SomeCollege_wtd=(nhood_tract_wght*SomeCollege).
COMPUTE Bach_degree_wtd=(nhood_tract_wght*Bach_degree).
COMPUTE Masters_degree_wtd=(nhood_tract_wght*Masters_degree).
COMPUTE Prof_school_degree_wtd=	(nhood_tract_wght*Prof_school_degree).
COMPUTE Doc_degree_wtd=(nhood_tract_wght*Doc_degree).
COMPUTE HS_Grad_or_Higher_wtd=	(nhood_tract_wght*HS_Grad_or_Higher).
COMPUTE Bach_degree_or_Higher_wtd=(nhood_tract_wght*Bach_degree_or_Higher).
EXECUTE.
FORMATS Total_25o_wtd to Bach_degree_or_Higher_wtd(F5.0).
EXECUTE.


*********
Aggregate weighted ed data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE nhood_tract.
DATASET DECLARE Nhood_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='Nhood_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
  /Total_25o_wtd_sum=SUM(Total_25o_wtd) 
  /LT_HS_Grad_wtd_sum=SUM(LT_HS_Grad_wtd) 
  /HS_Grad_Equiv_wtd_sum=SUM(HS_Grad_Equiv_wtd) 
  /SomeCollege_wtd_sum=SUM(SomeCollege_wtd) 
  /Bach_degree_wtd_sum=SUM(Bach_degree_wtd) 
  /Masters_degree_wtd_sum=SUM(Masters_degree_wtd) 
  /Prof_school_degree_wtd_sum=SUM(Prof_school_degree_wtd) 
  /Doc_degree_wtd_sum=SUM(Doc_degree_wtd) 
  /HS_Grad_or_Higher_wtd_sum=SUM(HS_Grad_or_Higher_wtd) 
  /Bach_degree_or_Higher_wtd_sum=SUM(Bach_degree_or_Higher_wtd).
EXECUTE.

DATASET ACTIVATE Nhood_wtd.
FORMATS Total_25o_wtd_sum to Bach_degree_or_Higher_wtd_sum (F5.0).
EXECUTE.

DATASET CLOSE EduAttn.

******Haven't assessed whether MOEs will be possible - don't think you can weight MOEs****.




*/poverty.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Tract data\ACS_13_5YR_S1701_poverty.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  Id A20
  census_tract A11
  Geography A52
  TotalEst_Pop_PSD F4.0
  TotalMOE_Pop_PSD F4.0
  BelowPovEst_Pop_PSD F4.0
  BelowPovMOE_Pop_PSD F3.0
  PercentBelowPovEst_Pop_PSD A4
  PercentBelowPovMOE_Pop_PSD A4
  TotalEst_AGEUnder18years F4.0
  TotalMOE_AGEUnder18years F3.0
  BelowPovEst_AGEUnder18years F4.0
  BelowPovMOE_AGEUnder18years F3.0
  PercentBelowPovEst_AGEUnder18years A4
  PercentBelowPovMOE_AGEUnder18years A4
  TotalEst_AGEUnder18yearsRelatedchildrenunder18year F4.0
  TotalMOE_AGEUnder18yearsRelatedchildrenunder18year F3.0
  BelowPovEst_AGEUnder18yearsRelatedchildrenunder18y F4.0
  BelowPovMOE_AGEUnder18yearsRelatedchildrenunder18y F3.0
  PercentBelowPovEst_AGEUnder18yearsRelatedchildrenun A4
  PercentBelowPovMOE_AGEUnder18yearsRelatedchildrenun A4
  TotalEst_AGE18to64years F4.0
  TotalMOE_AGE18to64years F3.0
  BelowPovEst_AGE18to64years F4.0
  BelowPovMOE_AGE18to64years F3.0
  PercentBelowPovEst_AGE18to64years A4
  PercentBelowPovMOE_AGE18to64years A4
  TotalEst_AGE65yearsandover F4.0
  TotalMOE_AGE65yearsandover F3.0
  BelowPovEst_AGE65yearsandover F3.0
  BelowPovMOE_AGE65yearsandover F3.0
  PercentBelowPovEst_AGE65yearsandover A4
  PercentBelowPovMOE_AGE65yearsandover A4
  TotalEst_SEXMale F4.0
  TotalMOE_SEXMale F3.0
  BelowPovEst_SEXMale F4.0
  BelowPovMOE_SEXMale F3.0
  PercentBelowPovEst_SEXMale A4
  PercentBelowPovMOE_SEXMale A4
  TotalEst_SEXFemale F4.0
  TotalMOE_SEXFemale F3.0
  BelowPovEst_SEXFemale F4.0
  BelowPovMOE_SEXFemale F3.0
  PercentBelowPovEst_SEXFemale A4
  PercentBelowPovMOE_SEXFemale A4
  TotalEst_RACEANDHISPANICORLATINOORIGINOnerace F4.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOnerace F4.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOnerace F4.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOnerace F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_F A4
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_F A4
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceWhite F4.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceWhite F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceWh F4.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceWh F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_E A4
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_E A4
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceBlack F4.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceBlack F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceBl F3.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceBl F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_D A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_D A5
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceAmeri F3.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceAmeri F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceAm F3.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceAm F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_C A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_C A5
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceAsian F4.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceAsian F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceAs F3.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceAs F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_B A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_B A5
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceNativ F2.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceNativ F2.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceNa F2.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceNa F2.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner_A A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner_A A5
  TotalEst_RACEANDHISPANICORLATINOORIGINOneraceSome F4.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINOneraceSome F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINOneraceSo F4.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINOneraceSo F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINOner A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINOner A5
  TotalEst_RACEANDHISPANICORLATINOORIGINTwoormorerace F3.0
  TotalMOE_RACEANDHISPANICORLATINOORIGINTwoormorerace F3.0
  BelowPovEst_RACEANDHISPANICORLATINOORIGINTwoormorer F3.0
  BelowPovMOE_RACEANDHISPANICORLATINOORIGINTwoormorer F3.0
  PercentBelowPovEst_RACEANDHISPANICORLATINOORIGINTwoo A5
  PercentBelowPovMOE_RACEANDHISPANICORLATINOORIGINTwoo A5
  TotalEst_HispanicorLatinooriginofanyrace F4.0
  TotalMOE_HispanicorLatinooriginofanyrace F4.0
  BelowPovEst_HispanicorLatinooriginofanyrace F4.0
  BelowPovMOE_HispanicorLatinooriginofanyrace F3.0
  PercentBelowPovEst_HispanicorLatinooriginofanyrace A5
  PercentBelowPovMOE_HispanicorLatinooriginofanyrace A5
  TotalEst_WhitealonenotHispanicorLatino F4.0
  TotalMOE_WhitealonenotHispanicorLatino F3.0
  BelowPovEst_WhitealonenotHispanicorLatino F4.0
  BelowPovMOE_WhitealonenotHispanicorLatino F3.0
  PercentBelowPovEst_WhitealonenotHispanicorLatino A4
  PercentBelowPovMOE_WhitealonenotHispanicorLatino A4
  TotalEst_EDUCATIONALATTAINMENTPopulation25yearsandover F4.0
  TotalMOE_EDUCATIONALATTAINMENTPopulation25yearsandover F3.0
  BelowPovEst_EDUCATIONALATTAINMENTPopulation25yearsando F4.0
  BelowPovMOE_EDUCATIONALATTAINMENTPopulation25yearsando F3.0
  PercentBelowPovEst_EDUCATIONALATTAINMENTPopulation25yea A4
  PercentBelowPovMOE_EDUCATIONALATTAINMENTPopulation25yea A4
  TotalEst_EDUCATIONALATTAINMENTLessthanhighschoolgradua F4.0
  TotalMOE_EDUCATIONALATTAINMENTLessthanhighschoolgradua F3.0
  BelowPovEst_EDUCATIONALATTAINMENTLessthanhighschoolgra F3.0
  BelowPovMOE_EDUCATIONALATTAINMENTLessthanhighschoolgra F3.0
  PercentBelowPovEst_EDUCATIONALATTAINMENTLessthanhighsc A4
  PercentBelowPovMOE_EDUCATIONALATTAINMENTLessthanhighsc A4
  TotalEst_EDUCATIONALATTAINMENTHighschoolgraduateinclud F4.0
  TotalMOE_EDUCATIONALATTAINMENTHighschoolgraduateinclud F3.0
  BelowPovEst_EDUCATIONALATTAINMENTHighschoolgraduateinc F3.0
  BelowPovMOE_EDUCATIONALATTAINMENTHighschoolgraduateinc F3.0
  PercentBelowPovEst_EDUCATIONALATTAINMENTHighschoolgradu A4
  PercentBelowPovMOE_EDUCATIONALATTAINMENTHighschoolgradu A4
  TotalEst_EDUCATIONALATTAINMENTSomecollegeassociatesde F4.0
  TotalMOE_EDUCATIONALATTAINMENTSomecollegeassociatesde F3.0
  BelowPovEst_EDUCATIONALATTAINMENTSomecollegeassociates F3.0
  BelowPovMOE_EDUCATIONALATTAINMENTSomecollegeassociates F3.0
  PercentBelowPovEst_EDUCATIONALATTAINMENTSomecollegeass A4
  PercentBelowPovMOE_EDUCATIONALATTAINMENTSomecollegeass A4
  TotalEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigher F4.0
  TotalMOE_EDUCATIONALATTAINMENTBachelorsdegreeorhigher F3.0
  BelowPovEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigh F3.0
  BelowPovMOE_EDUCATIONALATTAINMENTBachelorsdegreeorhigh F3.0
  PercentBelowPovEst_EDUCATIONALATTAINMENTBachelorsdegree A4
  PercentBelowPovMOE_EDUCATIONALATTAINMENTBachelorsdegree A4
  TotalEst_EMPLOYMENTSTATUSCivilianlaborforce16yearsand F4.0
  TotalMOE_EMPLOYMENTSTATUSCivilianlaborforce16yearsand F3.0
  BelowPovEst_EMPLOYMENTSTATUSCivilianlaborforce16years F4.0
  BelowPovMOE_EMPLOYMENTSTATUSCivilianlaborforce16years F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSCivilianlaborforce1 A4
  PercentBelowPovMOE_EMPLOYMENTSTATUSCivilianlaborforce1 A4
  TotalEst_EMPLOYMENTSTATUSEmployed F4.0
  TotalMOE_EMPLOYMENTSTATUSEmployed F3.0
  BelowPovEst_EMPLOYMENTSTATUSEmployed F3.0
  BelowPovMOE_EMPLOYMENTSTATUSEmployed F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSEmployed A4
  PercentBelowPovMOE_EMPLOYMENTSTATUSEmployed A4
  TotalEst_EMPLOYMENTSTATUSEmployedMale F4.0
  TotalMOE_EMPLOYMENTSTATUSEmployedMale F3.0
  BelowPovEst_EMPLOYMENTSTATUSEmployedMale F3.0
  BelowPovMOE_EMPLOYMENTSTATUSEmployedMale F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSEmployedMale A4
  PercentBelowPovMOE_EMPLOYMENTSTATUSEmployedMale A4
  TotalEst_EMPLOYMENTSTATUSEmployedFemale F4.0
  TotalMOE_EMPLOYMENTSTATUSEmployedFemale F3.0
  BelowPovEst_EMPLOYMENTSTATUSEmployedFemale F3.0
  BelowPovMOE_EMPLOYMENTSTATUSEmployedFemale F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSEmployedFemale A4
  PercentBelowPovMOE_EMPLOYMENTSTATUSEmployedFemale A4
  TotalEst_EMPLOYMENTSTATUSUnemployed F4.0
  TotalMOE_EMPLOYMENTSTATUSUnemployed F3.0
  BelowPovEst_EMPLOYMENTSTATUSUnemployed F3.0
  BelowPovMOE_EMPLOYMENTSTATUSUnemployed F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSUnemployed A4
  PercentBelowPovMOE_EMPLOYMENTSTATUSUnemployed A4
  TotalEst_EMPLOYMENTSTATUSUnemployedMale F3.0
  TotalMOE_EMPLOYMENTSTATUSUnemployedMale F3.0
  BelowPovEst_EMPLOYMENTSTATUSUnemployedMale F3.0
  BelowPovMOE_EMPLOYMENTSTATUSUnemployedMale F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSUnemployedMale A5
  PercentBelowPovMOE_EMPLOYMENTSTATUSUnemployedMale A4
  TotalEst_EMPLOYMENTSTATUSUnemployedFemale F3.0
  TotalMOE_EMPLOYMENTSTATUSUnemployedFemale F3.0
  BelowPovEst_EMPLOYMENTSTATUSUnemployedFemale F3.0
  BelowPovMOE_EMPLOYMENTSTATUSUnemployedFemale F3.0
  PercentBelowPovEst_EMPLOYMENTSTATUSUnemployedFemale A5
  PercentBelowPovMOE_EMPLOYMENTSTATUSUnemployedFemale A5
  TotalEst_WORKEXPERIENCEPopulation16yearsandover F4.0
  TotalMOE_WORKEXPERIENCEPopulation16yearsandover F3.0
  BelowPovEst_WORKEXPERIENCEPopulation16yearsandover F4.0
  BelowPovMOE_WORKEXPERIENCEPopulation16yearsandover F3.0
  PercentBelowPovEst_WORKEXPERIENCEPopulation16yearsand A4
  PercentBelowPovMOE_WORKEXPERIENCEPopulation16yearsand A4
  TotalEst_WORKEXPERIENCEWorkedfulltimeyearroundinthe F4.0
  TotalMOE_WORKEXPERIENCEWorkedfulltimeyearroundinthe F3.0
  BelowPovEst_WORKEXPERIENCEWorkedfulltimeyearroundin F3.0
  BelowPovMOE_WORKEXPERIENCEWorkedfulltimeyearroundin F3.0
  PercentBelowPovEst_WORKEXPERIENCEWorkedfulltimeyearr A4
  PercentBelowPovMOE_WORKEXPERIENCEWorkedfulltimeyearr A4
  TotalEst_WORKEXPERIENCEWorkedparttimeorpartyearinth F4.0
  TotalMOE_WORKEXPERIENCEWorkedparttimeorpartyearinth F3.0
  BelowPovEst_WORKEXPERIENCEWorkedparttimeorpartyearin F3.0
  BelowPovMOE_WORKEXPERIENCEWorkedparttimeorpartyearin F3.0
  PercentBelowPovEst_WORKEXPERIENCEWorkedparttimeorpart A4
  PercentBelowPovMOE_WORKEXPERIENCEWorkedparttimeorpart A4
  TotalEst_WORKEXPERIENCEDidnotwork F4.0
  TotalMOE_WORKEXPERIENCEDidnotwork F3.0
  BelowPovEst_WORKEXPERIENCEDidnotwork F4.0
  BelowPovMOE_WORKEXPERIENCEDidnotwork F3.0
  PercentBelowPovEst_WORKEXPERIENCEDidnotwork A4
  PercentBelowPovMOE_WORKEXPERIENCEDidnotwork A4
  TotalEst_AllIndividualsbelow50percentofpovertylevel F4.0
  TotalMOE_AllIndividualsbelow50percentofpovertylevel F3.0
  BelowPovEst_AllIndividualsbelow50percentofpovertylev A3
  BelowPovMOE_AllIndividualsbelow50percentofpovertylev A3
  PercentBelowPovEst_AllIndividualsbelow50percentofpov A3
  PercentBelowPovMOE_AllIndividualsbelow50percentofpov A3
  TotalEst_AllIndividualsbelow125percentofpovertylevel F4.0
  TotalMOE_AllIndividualsbelow125percentofpovertylevel F3.0
  BelowPovEst_AllIndividualsbelow125percentofpovertyle A3
  BelowPovMOE_AllIndividualsbelow125percentofpovertyle A3
  PercentBelowPovEst_AllIndividualsbelow125percentofpo A3
  PercentBelowPovMOE_AllIndividualsbelow125percentofpo A3
  TotalEst_AllIndividualsbelow150percentofpovertylevel F4.0
  TotalMOE_AllIndividualsbelow150percentofpovertylevel F4.0
  BelowPovEst_AllIndividualsbelow150percentofpovertyle A3
  BelowPovMOE_AllIndividualsbelow150percentofpovertyle A3
  PercentBelowPovEst_AllIndividualsbelow150percentofpo A3
  PercentBelowPovMOE_AllIndividualsbelow150percentofpo A3
  TotalEst_AllIndividualsbelow185percentofpovertylevel F4.0
  TotalMOE_AllIndividualsbelow185percentofpovertylevel F4.0
  BelowPovEst_AllIndividualsbelow185percentofpovertyle A3
  BelowPovMOE_AllIndividualsbelow185percentofpovertyle A3
  PercentBelowPovEst_AllIndividualsbelow185percentofpo A3
  PercentBelowPovMOE_AllIndividualsbelow185percentofpo A3
  TotalEst_AllIndividualsbelow200percentofpovertylevel F4.0
  TotalMOE_AllIndividualsbelow200percentofpovertylevel F4.0
  BelowPovEst_AllIndividualsbelow200percentofpovertyle A3
  BelowPovMOE_AllIndividualsbelow200percentofpovertyle A3
  PercentBelowPovEst_AllIndividualsbelow200percentofpo A3
  PercentBelowPovMOE_AllIndividualsbelow200percentofpo A3
  TotalEst_Unrelatedindividualsforwhompovertystatusisdete F4.0
  TotalMOE_Unrelatedindividualsforwhompovertystatusisdete F3.0
  BelowPovEst_Unrelatedindividualsforwhompovertystatusisd F4.0
  BelowPovMOE_Unrelatedindividualsforwhompovertystatusisd F3.0
  PercentBelowPovEst_Unrelatedindividualsforwhompovertysta A4
  PercentBelowPovMOE_Unrelatedindividualsforwhompovertysta A4
  TotalEst_Male F4.0
  TotalMOE_Male F3.0
  BelowPovEst_Male F3.0
  BelowPovMOE_Male F3.0
  PercentBelowPovEst_Male A4
  PercentBelowPovMOE_Male A4
  TotalEst_Female F4.0
  TotalMOE_Female F3.0
  BelowPovEst_Female F3.0
  BelowPovMOE_Female F3.0
  PercentBelowPovEst_Female A4
  PercentBelowPovMOE_Female A4
  TotalEst_Meanincomedeficitforunrelatedindividualsdollar A4
  TotalMOE_Meanincomedeficitforunrelatedindividualsdollar A4
  BelowPovEst_Meanincomedeficitforunrelatedindividualsdol A3
  BelowPovMOE_Meanincomedeficitforunrelatedindividualsdol A3
  PercentBelowPovEst_Meanincomedeficitforunrelatedindividu A3
  PercentBelowPovMOE_Meanincomedeficitforunrelatedindividu A3
  TotalEst_Workedfulltimeyearroundinthepast12months F4.0
  TotalMOE_Workedfulltimeyearroundinthepast12months F3.0
  BelowPovEst_Workedfulltimeyearroundinthepast12months F3.0
  BelowPovMOE_Workedfulltimeyearroundinthepast12months F3.0
  PercentBelowPovEst_Workedfulltimeyearroundinthepast1 A4
  PercentBelowPovMOE_Workedfulltimeyearroundinthepast1 A4
  TotalEst_Workedlessthanfulltimeyearroundinthepast12 F4.0
  TotalMOE_Workedlessthanfulltimeyearroundinthepast12 F3.0
  BelowPovEst_Workedlessthanfulltimeyearroundinthepast F3.0
  BelowPovMOE_Workedlessthanfulltimeyearroundinthepast F3.0
  PercentBelowPovEst_Workedlessthanfulltimeyearroundin A4
  PercentBelowPovMOE_Workedlessthanfulltimeyearroundin A4
  TotalEst_Didnotwork F4.0
  TotalMOE_Didnotwork F3.0
  BelowPovEst_Didnotwork F3.0
  BelowPovMOE_Didnotwork F3.0
  PercentBelowPovEst_Didnotwork A4
  PercentBelowPovMOE_Didnotwork A4
  TotalEst_PERCENTIMPUTEDPovertystatusforindividuals A4
  TotalMOE_PERCENTIMPUTEDPovertystatusforindividuals A3
  BelowPovEst_PERCENTIMPUTEDPovertystatusforindividuals A3
  BelowPovMOE_PERCENTIMPUTEDPovertystatusforindividuals A3
  PercentBelowPovEst_PERCENTIMPUTEDPovertystatusforindiv A3
  PercentBelowPovMOE_PERCENTIMPUTEDPovertystatusforindiv A3.
CACHE.
EXECUTE.
DATASET NAME Poverty_tct WINDOW=FRONT.



ADD FILES FILE=*
/KEEP census_tract TotalEst_Pop_PSD BelowPovEst_Pop_PSD TotalEst_AGEUnder18years BelowPovEst_AGEUnder18years TotalEst_AGE18to64years BelowPovEst_AGE18to64years
TotalEst_AGE65yearsandover BelowPovEst_AGE65yearsandover TotalEst_EDUCATIONALATTAINMENTPopulation25yearsandover BelowPovEst_EDUCATIONALATTAINMENTPopulation25yearsando
TotalEst_EDUCATIONALATTAINMENTLessthanhighschoolgradua BelowPovEst_EDUCATIONALATTAINMENTLessthanhighschoolgra TotalEst_EDUCATIONALATTAINMENTHighschoolgraduateinclud
BelowPovEst_EDUCATIONALATTAINMENTHighschoolgraduateinc TotalEst_EDUCATIONALATTAINMENTSomecollegeassociatesde BelowPovEst_EDUCATIONALATTAINMENTSomecollegeassociates
TotalEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigher BelowPovEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigh TotalEst_AllIndividualsbelow50percentofpovertylevel
TotalEst_AllIndividualsbelow125percentofpovertylevel  TotalEst_AllIndividualsbelow150percentofpovertylevel TotalEst_AllIndividualsbelow185percentofpovertylevel  TotalEst_AllIndividualsbelow200percentofpovertylevel.
VARIABLE LABELS
TotalEst_Pop_PSD 'Population for whom poverty status is determined'
BelowPovEst_Pop_PSD 'Total Population Below poverty level'
TotalEst_AGEUnder18years 'Under 18 years'
BelowPovEst_AGEUnder18years 'Under 18 years - Below Poverty'
TotalEst_AGE18to64years  '18 to 64 years'
BelowPovEst_AGE18to64years '18 to 64 years - Below Poverty'
TotalEst_AGE65yearsandover  '65 years and over'
BelowPovEst_AGE65yearsandover '65 years and over - Below Poverty'
TotalEst_EDUCATIONALATTAINMENTPopulation25yearsandover  'Population 25 years and over'
BelowPovEst_EDUCATIONALATTAINMENTPopulation25yearsando 'Population 25 years and over - Below Poverty'
TotalEst_EDUCATIONALATTAINMENTLessthanhighschoolgradua 'Less than high school graduate'
BelowPovEst_EDUCATIONALATTAINMENTLessthanhighschoolgra 'Less than high school graduate - Below Poverty'
TotalEst_EDUCATIONALATTAINMENTHighschoolgraduateinclud 'High school graduate (includes equivalency)'
BelowPovEst_EDUCATIONALATTAINMENTHighschoolgraduateinc 'High school graduate (includes equivalency) - Below Poverty'
TotalEst_EDUCATIONALATTAINMENTSomecollegeassociatesde "Some college, associate's degree"
BelowPovEst_EDUCATIONALATTAINMENTSomecollegeassociates "Some college, associate's degree - Below Poverty"
TotalEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigher "Bachelor's degree or higher"
BelowPovEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigh "Bachelor's degree or higher - Below Poverty"
TotalEst_AllIndividualsbelow50percentofpovertylevel 'All Individuals below:	50 percent of poverty level'
TotalEst_AllIndividualsbelow125percentofpovertylevel 'All Individuals below:	125 percent of poverty level'
TotalEst_AllIndividualsbelow150percentofpovertylevel 'All Individuals below:	150 percent of poverty level'
TotalEst_AllIndividualsbelow185percentofpovertylevel 'All Individuals below:	185 percent of poverty level'
TotalEst_AllIndividualsbelow200percentofpovertylevel 'All Individuals below:	200 percent of poverty level'.
RENAME VARIABLES 
TotalEst_Pop_PSD=TotPop_PSD
BelowPovEst_Pop_PSD =TotPopBP_PSD
TotalEst_AGEUnder18years=PopU18_PSD
BelowPovEst_AGEUnder18years=PopU18_BP_PSD
TotalEst_AGE18to64years  =Pop18to64_PSD
BelowPovEst_AGE18to64years =Pop18to64_BP_PSD
TotalEst_AGE65yearsandover =Pop65over_PSD
BelowPovEst_AGE65yearsandover =Pop65over_BP_PSD
TotalEst_EDUCATIONALATTAINMENTPopulation25yearsandover =Pop25over_PSD
BelowPovEst_EDUCATIONALATTAINMENTPopulation25yearsando=Pop25over_BP_PSD
TotalEst_EDUCATIONALATTAINMENTLessthanhighschoolgradua=LT_highschl_PSD
BelowPovEst_EDUCATIONALATTAINMENTLessthanhighschoolgra=LT_highschl_BP_PSD
TotalEst_EDUCATIONALATTAINMENTHighschoolgraduateinclud =HSgrad_PSD
BelowPovEst_EDUCATIONALATTAINMENTHighschoolgraduateinc=HSgrad_BP_PSD
TotalEst_EDUCATIONALATTAINMENTSomecollegeassociatesde =SomeColl_Assoc_PSD
BelowPovEst_EDUCATIONALATTAINMENTSomecollegeassociates =SomeColl_Assoc_BP_PSD
TotalEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigher =BachHigher_PSD
BelowPovEst_EDUCATIONALATTAINMENTBachelorsdegreeorhigh =BachHigher_BP_PSD
TotalEst_AllIndividualsbelow50percentofpovertylevel =Indiv_Below50pctPov
TotalEst_AllIndividualsbelow125percentofpovertylevel =Indiv_Below125pctPov
TotalEst_AllIndividualsbelow150percentofpovertylevel =Indiv_Below150pctPov
TotalEst_AllIndividualsbelow185percentofpovertylevel =Indiv_Below185pctPov
TotalEst_AllIndividualsbelow200percentofpovertylevel =Indiv_Below200pctPov.
EXECUTE.



*********
Merge nhood_tract tract info onto Poverty
*********.
DATASET ACTIVATE Poverty_tct.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.
DATASET ACTIVATE Poverty_tct.
MATCH FILES /TABLE=*
  /FILE='nhood_tract'
  /RENAME (Bach_degree Bach_degree_or_Higher Bach_degree_or_Higher_wtd Bach_degree_wtd Doc_degree 
    Doc_degree_wtd HS_Dipl_Equiv HS_Grad_Equiv_wtd HS_Grad_or_Higher HS_Grad_or_Higher_wtd 
    LT_HS_Diploma_Equiv LT_HS_Grad_wtd Masters_degree Masters_degree_wtd Prof_school_degree 
    Prof_school_degree_wtd SomeCollege SomeCollege_wtd Total_25o Total_25o_wtd = d0 d1 d2 d3 d4 d5 d6 
    d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19) 
  /BY census_tract
  /DROP= d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19.
EXECUTE.




*/Calculate weighted variables.
COMPUTE TotPop_PSD_wtd=(nhood_tract_wght*TotPop_PSD).
COMPUTE TotPopBP_PSD_wtd=(nhood_tract_wght*TotPopBP_PSD).
COMPUTE PopU18_PSD_wtd=(nhood_tract_wght*PopU18_PSD).
COMPUTE PopU18_BP_PSD_wtd=(nhood_tract_wght*PopU18_BP_PSD).
COMPUTE Pop18to64_PSD_wtd=(nhood_tract_wght*Pop18to64_PSD).
COMPUTE Pop18to64_BP_PSD_wtd=(nhood_tract_wght*Pop18to64_BP_PSD).
COMPUTE Pop65over_PSD_wtd=(nhood_tract_wght*Pop65over_PSD).
COMPUTE Pop65over_BP_PSD_wtd=(nhood_tract_wght*Pop65over_BP_PSD).
COMPUTE Pop25over_PSD_wtd=(nhood_tract_wght*Pop25over_PSD).
COMPUTE Pop25over_BP_PSD_wtd=(nhood_tract_wght*Pop25over_BP_PSD).
COMPUTE LT_highschl_PSD_wtd=(nhood_tract_wght*LT_highschl_PSD).
COMPUTE LT_highschl_BP_PSD_wtd=(nhood_tract_wght*LT_highschl_BP_PSD).
COMPUTE HSgrad_PSD_wtd=(nhood_tract_wght*HSgrad_PSD).
COMPUTE HSgrad_BP_PSD_wtd=(nhood_tract_wght*HSgrad_BP_PSD).
COMPUTE SomeColl_Assoc_PSD_wtd=(nhood_tract_wght*SomeColl_Assoc_PSD).
COMPUTE SomeColl_Assoc_BP_PSD_wtd=(nhood_tract_wght*SomeColl_Assoc_BP_PSD).
COMPUTE BachHigher_PSD_wtd=(nhood_tract_wght*BachHigher_PSD).
COMPUTE BachHigher_BP_PSD_wtd=(nhood_tract_wght*BachHigher_BP_PSD).
COMPUTE Indiv_Below50pctPov_wtd=(nhood_tract_wght*Indiv_Below50pctPov).
COMPUTE Indiv_Below125pctPov_wtd=(nhood_tract_wght*Indiv_Below125pctPov).
COMPUTE Indiv_Below150pctPov_wtd=(nhood_tract_wght*Indiv_Below150pctPov).
COMPUTE Indiv_Below185pctPov_wtd=(nhood_tract_wght*Indiv_Below185pctPov).
COMPUTE Indiv_Below200pctPov_wtd=(nhood_tract_wght*Indiv_Below200pctPov).
EXECUTE.
FORMATS TotPop_PSD_wtd to Indiv_Below200pctPov_wtd (F5.0).
EXECUTE.

*********
Aggregate weighted poverty data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE Poverty_tct.
DATASET DECLARE Povtery_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='Povtery_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
  /TotPop_PSD_wtd=SUM(TotPop_PSD_wtd) 
  /TotPopBP_PSD_wtd=SUM(TotPopBP_PSD_wtd) 
  /PopU18_PSD_wtd=SUM(PopU18_PSD_wtd) 
  /PopU18_BP_PSD_wtd=SUM(PopU18_BP_PSD_wtd) 
  /Pop18to64_PSD_wtd=SUM(Pop18to64_PSD_wtd) 
  /Pop18to64_BP_PSD_wtd=SUM(Pop18to64_BP_PSD_wtd) 
  /Pop65over_PSD_wtd=SUM(Pop65over_PSD_wtd) 
  /Pop65over_BP_PSD_wtd=SUM(Pop65over_BP_PSD_wtd) 
  /Pop25over_PSD_wtd=SUM(Pop25over_PSD_wtd) 
  /Pop25over_BP_PSD_wtd=SUM(Pop25over_BP_PSD_wtd)
  /LT_highschl_PSD_wtd=SUM(LT_highschl_PSD_wtd) 
  /LT_highschl_BP_PSD_wtd=SUM(LT_highschl_BP_PSD_wtd) 
  /HSgrad_PSD_wtd=SUM(HSgrad_PSD_wtd) 
  /HSgrad_BP_PSD_wtd=SUM(HSgrad_BP_PSD_wtd) 
  /SomeColl_Assoc_PSD_wtd=SUM(SomeColl_Assoc_PSD_wtd) 
  /SomeColl_Assoc_BP_PSD_wtd=SUM(SomeColl_Assoc_BP_PSD_wtd)
  /BachHigher_PSD_wtd=SUM(BachHigher_PSD_wtd) 
  /BachHigher_BP_PSD_wtd=SUM(BachHigher_BP_PSD_wtd) 
  /Indiv_Below50pctPov_wtd=SUM(Indiv_Below50pctPov_wtd) 
  /Indiv_Below125pctPov_wtd=SUM(Indiv_Below125pctPov_wtd) 
  /Indiv_Below150pctPov_wtd=SUM(Indiv_Below150pctPov_wtd) 
  /Indiv_Below185pctPov_wtd=SUM(Indiv_Below185pctPov_wtd)
  /Indiv_Below200pctPov_wtd=SUM(Indiv_Below200pctPov_wtd).
EXECUTE.

VARIABLE LABELS
TotPop_PSD_wtd 'Population for whom poverty status is determined'
TotPopBP_PSD_wtd 'Total Population Below poverty level'
PopU18_PSD_wtd 'Population Under 18 years for whom poverty status is determined'
PopU18_BP_PSD_wtd 'Population Under 18 years - Below Poverty'
Pop18to64_PSD_wtd  Population '18 to 64 years for whom poverty status is determined'
Pop18to64_BP_PSD_wtd 'Population 18 to 64 years - Below Poverty'
Pop65over_PSD_wtd  'Population 65 years and over for whom poverty status is determined'
Pop65over_BP_PSD_wtd 'Population 65 years and over - Below Poverty'
Pop25over_PSD_wtd  'Population 25 years and over for whom poverty status is determined'
Pop25over_BP_PSD_wtd 'Population 25 years and over - Below Poverty'
LT_highschl_PSD_wtd 'Population 25 years and over - Less than high school graduate'
LT_highschl_BP_PSD_wtd 'Population 25 years and over - Less than high school graduate - Below Poverty'
HSgrad_PSD_wtd 'Population 25 years and over - High school graduate (includes equivalency)'
HSgrad_BP_PSD_wtd 'Population 25 years and over - High school graduate (includes equivalency) - Below Poverty'
SomeColl_Assoc_PSD_wtd "Population 25 years and over - Some college, associate's degree"
SomeColl_Assoc_BP_PSD_wtd "Population 25 years and over - Some college, associate's degree - Below Poverty"
BachHigher_PSD_wtd "Population 25 years and over - Bachelor's degree or higher"
BachHigher_BP_PSD_wtd "Population 25 years and over - Bachelor's degree or higher - Below Poverty"
Indiv_Below50pctPov_wtd 'All Individuals below:	50 percent of poverty level'
Indiv_Below125pctPov_wtd 'All Individuals below:	125 percent of poverty level'
Indiv_Below150pctPov_wtd 'All Individuals below:	150 percent of poverty level'
Indiv_Below185pctPov_wtd 'All Individuals below:	185 percent of poverty level'
Indiv_Below200pctPov_wtd 'All Individuals below:	200 percent of poverty level'.

DATASET ACTIVATE Povtery_wtd.
FORMATS TotPop_PSD_wtd to Indiv_Below200pctPov_wtd (F5.0).
EXECUTE.

DATASET CLOSE Poverty_tct.

DATASET ACTIVATE Nhood_wtd.
MATCH FILES /TABLE=*
  /FILE='Povtery_wtd'
  /BY neighborhood_first.
EXECUTE.

DATASET CLOSE Povtery_wtd.


*/poverty ratios.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Tract data\ACS_13_5YR_C17002_pov_ratio.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  Id A20
  census_tract A11
  Geography A52
  EstimateTotal F4.0
  MarginofErrorTotal F4.0
  EstimateTotalUnder.50 F4.0
  MarginofErrorTotalUnder.50 F3.0
  EstimateTotal.50to.99 F4.0
  MarginofErrorTotal.50to.99 F3.0
  EstimateTotal1.00to1.24 F4.0
  MarginofErrorTotal1.00to1.24 F3.0
  EstimateTotal1.25to1.49 F4.0
  MarginofErrorTotal1.25to1.49 F3.0
  EstimateTotal1.50to1.84 F4.0
  MarginofErrorTotal1.50to1.84 F3.0
  EstimateTotal1.85to1.99 F3.0
  MarginofErrorTotal1.85to1.99 F3.0
  EstimateTotal2.00andover F4.0
  MarginofErrorTotal2.00andover F3.0.
CACHE.
EXECUTE.
DATASET NAME PovRatio WINDOW=FRONT.



*********
Merge nhood_tract tract info onto Poverty
*********.
DATASET ACTIVATE PovRatio.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.
DATASET ACTIVATE PovRatio.
MATCH FILES /TABLE=*
  /FILE='nhood_tract'
  /RENAME (Bach_degree Bach_degree_or_Higher Bach_degree_or_Higher_wtd Bach_degree_wtd Doc_degree 
    Doc_degree_wtd HS_Dipl_Equiv HS_Grad_Equiv_wtd HS_Grad_or_Higher HS_Grad_or_Higher_wtd 
    LT_HS_Diploma_Equiv LT_HS_Grad_wtd Masters_degree Masters_degree_wtd Prof_school_degree 
    Prof_school_degree_wtd SomeCollege SomeCollege_wtd Total_25o Total_25o_wtd = d0 d1 d2 d3 d4 d5 d6 
    d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19) 
  /BY census_tract
  /DROP= d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19.
EXECUTE.

*/Calculate weighted variables.
COMPUTE TotPop_PSD_wtd=(nhood_tract_wght*EstimateTotal).
COMPUTE Indiv_Under.50Pov_wtd=(nhood_tract_wght*EstimateTotalUnder.50).
COMPUTE Indiv_Total.50to.99Pov_wtd=(nhood_tract_wght*EstimateTotal.50to.99).
COMPUTE Indiv_Total1.00to1.24Pov_wtd=(nhood_tract_wght*EstimateTotal1.00to1.24).
COMPUTE Indiv_Total1.25to1.49Pov_wtd=(nhood_tract_wght*EstimateTotal1.25to1.49).
COMPUTE Indiv_Total1.50to1.84Pov_wtd=(nhood_tract_wght*EstimateTotal1.50to1.84).
COMPUTE Indiv_Total1.85to1.99Pov_wtd=(nhood_tract_wght*EstimateTotal1.85to1.99).
COMPUTE Indiv_Total2.00andoverPov_wtd=(nhood_tract_wght*EstimateTotal2.00andover).
EXECUTE.
FORMATS TotPop_PSD_wtd to Indiv_Total2.00andoverPov_wtd (F5.0).
EXECUTE.

*********
Aggregate weighted poverty data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE PovRatio.
DATASET DECLARE PovRatio_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='PovRatio_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
  /TotPop_PSD_wtd=SUM(TotPop_PSD_wtd) 
  /Indiv_Under.50Pov_wtd=SUM(Indiv_Under.50Pov_wtd) 
  /Indiv_Total.50to.99Pov_wtd=SUM(Indiv_Total.50to.99Pov_wtd) 
  /Indiv_Total1.00to1.24Pov_wtd=SUM(Indiv_Total1.00to1.24Pov_wtd) 
  /Indiv_Total1.25to1.49Pov_wtd=SUM(Indiv_Total1.25to1.49Pov_wtd) 
  /Indiv_Total1.50to1.84Pov_wtd=SUM(Indiv_Total1.50to1.84Pov_wtd) 
  /Indiv_Total1.85to1.99Pov_wtd=SUM(Indiv_Total1.85to1.99Pov_wtd) 
  /Indiv_Total2.00andoverPov_wtd=SUM(Indiv_Total2.00andoverPov_wtd).
EXECUTE.

DATASET ACTIVATE PovRatio_wtd.
FORMATS TotPop_PSD_wtd to Indiv_Total2.00andoverPov_wtd (F5.0).
EXECUTE.

DATASET CLOSE PovRatio.

DATASET ACTIVATE Nhood_wtd.
MATCH FILES /TABLE=*
  /FILE='PovRatio_wtd'
  /RENAME (TotPop_PSD_wtd = d0) 
  /BY neighborhood_first
  /DROP= d0.
EXECUTE.

DATASET CLOSE PovRatio_wtd.


*********
format nhood file for profiles requirements
*********.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Community Profiles\data_files\data_files\RI_geo_records_withnhood.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  geo_name A25
  geo_id A12
  level A21
  moe F1.0.
CACHE.
EXECUTE.
DATASET NAME nhood.

DATASET ACTIVATE nhood.
FILTER OFF.
USE ALL.
SELECT IF (level = 'neighborhood').
EXECUTE.

DATASET ACTIVATE nhood.
SORT CASES BY geo_name(A).
DATASET ACTIVATE Nhood_wtd.
SORT CASES BY neighborhood_first(A).

DATASET ACTIVATE Nhood_wtd.
MATCH FILES /FILE=*
  /RENAME neighborhood_first=geo_name
  /TABLE='nhood'
  /BY geo_name.
EXECUTE.

DATASET ACTIVATE Nhood_wtd.
ADD FILES FILE=*
/KEEP geo_name geo_id level moe ALL.



SAVE TRANSLATE OUTFILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_trct_wtd_pop.csv'
  /TYPE=CSV
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.







