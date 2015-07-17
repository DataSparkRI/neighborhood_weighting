**********************
Create a population-weighted nhood-tract file for joining ACS tract data to convert to nhood level
**********************.


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

DATASET CLOSE block_walk.

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





**********************
Get data, join on tract, calculate weighted values, then create a file 
aggregated on nhood with weighted values.
**********************.

*/Citizen data.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\gjdetamore\Civic Engagement\ACS_13_5YR_B05003\ACS_13_5YR_B05003_with_ann2.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  GeoLong A20
  census_tract A11
  GeoName A60
  Est_T F4.0
  MOE_T F4.0
  Est_M F4.0
  MOE_M F4.0
  Est_M_Youth F4.0
  MOE_M_Youth F4.0
  Est_M_Youth_N F4.0
  MOE_M_Youth_N F4.0
  Est_M_Youth_F F4.0
  MOE_M_Youth_F F4.0
  Est_M_Youth_F_Cit F4.0
  MOE_M_Youth_F_Cit F4.0
  Est_M_Youth_F_Not F4.0
  MOE_M_Youth_F_Not F4.0
  Est_M_Adult F4.0
  MOE_M_Adult F4.0
  Est_M_Adult_N F4.0
  MOE_M_Adult_N F4.0
  Est_M_Adult_F F4.0
  MOE_M_Adult_F F4.0
  Est_M_Adult_F_Cit F4.0
  MOE_M_Adult_F_Cit F4.0
  Est_M_Adult_F_Not F4.0
  MOE_M_Adult_F_Not F4.0
  Est_F F4.0
  MOE_F F4.0
  Est_F_Youth F4.0
  MOE_F_Youth F4.0
  Est_F_Youth_N F4.0
  MOE_F_Youth_N F4.0
  Est_F_Youth_F F4.0
  MOE_F_Youth_F F4.0
  Est_F_Youth_F_Cit F4.0
  MOE_F_Youth_F_Cit F4.0
  Est_F_Youth_F_Not F4.0
  MOE_F_Youth_F_Not F4.0
  Est_F_Adult F4.0
  MOE_F_Adult F4.0
  Est_F_Adult_N F4.0
  MOE_F_Adult_N F4.0
  Est_F_Adult_F F4.0
  MOE_F_Adult_F F4.0
  Est_F_Adult_F_Cit F4.0
  MOE_F_Adult_F_Cit F4.0
  Est_F_Adult_F_Not F4.0
  MOE_F_Adult_F_Not F4.0.
CACHE.
EXECUTE.
DATASET NAME CitizenNums WINDOW=FRONT.


*********
Merge Citizen onto nhood_tract
*********.
DATASET ACTIVATE CitizenNums.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.
MATCH FILES /FILE=*
  /TABLE='CitizenNums'
  /BY census_tract.
EXECUTE.



*/Calculate weighted variables.
COMPUTE Adult_Cit_M_wtd=(nhood_tract_wght*(Est_M_Adult_N+Est_M_Adult_F_Cit)).
COMPUTE Adult_Cit_F_wtd=(nhood_tract_wght*(Est_F_Adult_N+Est_F_Adult_F_Cit)).
COMPUTE Adult_Cit_T_wtd=(Adult_Cit_M_wtd+Adult_Cit_F_wtd).
COMPUTE Adult_Not_T_wtd=(nhood_tract_wght*(Est_M_Adult_F_Not+Est_F_Adult_F_Not)).
COMPUTE Youth_Cit_M_wtd=(nhood_tract_wght*(Est_M_Youth_N+Est_M_Youth_F_Cit)).
COMPUTE Youth_Cit_F_wtd=(nhood_tract_wght*(Est_F_Youth_N+Est_F_Youth_F_Cit)).
COMPUTE Youth_Cit_T_wtd=(Youth_Cit_M_wtd+Youth_Cit_F_wtd).
COMPUTE Youth_Not_T_wtd=(nhood_tract_wght*(Est_M_Youth_F_Not+Est_F_Youth_F_Not)).
EXECUTE.
 * FORMATS Total_25o_wtd to Bach_degree_or_Higher_wtd(F5.0).
 * EXECUTE.


*********
Aggregate weighted citizen data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE nhood_tract.
DATASET DECLARE Nhood_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='Nhood_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
   /Adult_Cit_M_wtd_sum=SUM(Adult_Cit_M_wtd)
   /Adult_Cit_F_wtd_sum=SUM(Adult_Cit_F_wtd)
   /Adult_Cit_T_wtd_sum=SUM(Adult_Cit_T_wtd)
   /Adult_Not_T_wtd_sum=SUM(Adult_Not_T_wtd)
   /Youth_Cit_M_wtd_sum=SUM(Youth_Cit_M_wtd)
   /Youth_Cit_F_wtd_sum=SUM(Youth_Cit_F_wtd)
   /Youth_Cit_T_wtd_sum=SUM(Youth_Cit_T_wtd)
   /Youth_Not_T_wtd_sum=SUM(Youth_Not_T_wtd).
EXECUTE.

DATASET CLOSE CitizenNums.


*********
Round
*********.
DATASET ACTIVATE Nhood_wtd.
COMPUTE Adult_Cit_M_wtd_sum=RND(Adult_Cit_M_wtd_sum).
COMPUTE Adult_Cit_F_wtd_sum=RND(Adult_Cit_F_wtd_sum).
COMPUTE Adult_Cit_T_wtd_sum=RND(Adult_Cit_T_wtd_sum).
COMPUTE Adult_Not_T_wtd_sum=RND(Adult_Not_T_wtd_sum).
COMPUTE Youth_Cit_M_wtd_sum=RND(Youth_Cit_M_wtd_sum).
COMPUTE Youth_Cit_F_wtd_sum=RND(Youth_Cit_F_wtd_sum).
COMPUTE Youth_Cit_T_wtd_sum=RND(Youth_Cit_T_wtd_sum).
COMPUTE Youth_Not_T_wtd_sum=RND(Youth_Not_T_wtd_sum).
EXECUTE.

DATASET ACTIVATE Nhood_wtd.
FORMATS Adult_Cit_M_wtd_sum to Youth_Not_T_wtd_sum (F8.0).
EXECUTE.


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



SAVE TRANSLATE OUTFILE='P:\WORK\gjdetamore\Civic Engagement\tract weighting\Neighborhood_Citizen_Pops.csv'
  /TYPE=CSV
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.


******Haven't assessed whether MOEs will be possible - don't think you can weight MOEs****. (-Kim)


