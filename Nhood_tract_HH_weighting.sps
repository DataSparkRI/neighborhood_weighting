**********************
Create a household-weighted nhood-tract file for joining ACS tract data to convert to nhood level
**********************.




*
Can jump to line 151 to get the already created weighted tract file!
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
Add Household (occupied housing units) count
*********.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Block data\DEC_10_SF1_H3_HU.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  Id A24
  block_fips_code A15
  Geography A77
  Total F3.0
  Occupied F3.0
  Vacant F2.0.
CACHE.
EXECUTE.
DATASET NAME households WINDOW=FRONT.

DATASET ACTIVATE households.
SORT CASES BY block_fips_code.
DATASET ACTIVATE block_walk.
SORT CASES BY block_fips_code.

DATASET ACTIVATE block_walk.
MATCH FILES /FILE=*
  /TABLE='households'
  /RENAME (Geography Id Total Vacant = d0 d1 d2 d3) Occupied=Households
  /BY block_fips_code
  /DROP= d0 d1 d2 d3.
EXECUTE.

DATASET CLOSE households.


*********
Aggregate blocks to nhood-tract; sum households
*********.
DATASET ACTIVATE block_walk.
DATASET DECLARE nhood_tract.
SORT CASES BY nhood_tract.
AGGREGATE
  /OUTFILE='nhood_tract'
  /PRESORTED
  /BREAK=nhood_tract
  /households_sum=SUM(households) 
  /census_tract_first=FIRST(census_tract) 
  /neighborhood_first=FIRST(neighborhood)
  /N_BREAK=N.


*********
Aggregate households to tract
*********.
DATASET ACTIVATE block_walk.
DATASET DECLARE tract_HH.
SORT CASES BY census_tract.
AGGREGATE
  /OUTFILE='tract_HH'
  /PRESORTED
  /BREAK=census_tract
  /households_sum=SUM(households)
  /N_BREAK=N.


*********
Merge tract HH count onto nhood_tract by tract
*********.
DATASET ACTIVATE tract_HH.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract_first.
MATCH FILES /FILE=*
  /RENAME (N_BREAK = d0) census_tract_first=census_tract
  /TABLE='tract_HH'
  /RENAME (N_BREAK = d1) households_sum=tract_HH_count
  /BY census_tract
  /DROP= d0 d1.
EXECUTE.
VARIABLE LABELS tract_HH_count "H3 OCCUPANCY STATUS - Occupied HU = Households 2010 Census Summary File 1".
EXECUTE.

DATASET ACTIVATE nhood_tract.
COMPUTE nhood_tract_wght=(households_sum/tract_HH_count).
FORMATS nhood_tract_wght(f5.3).
EXECUTE.
VARIABLE LABELS nhood_tract_wght "Weight to be given to the partial/complete tract portion of a neighborhood based on households".
EXECUTE.

FORMATS households_sum(f5.0).
FORMATS tract_HH_count(f5.0).
EXECUTE.

DATASET CLOSE tract_HH.
DATASET CLOSE block_walk.

*/Only have to save once.
*SAVE OUTFILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_tract_weights_HH.sav'
  /COMPRESSED.


*/In the future.
*GET
  FILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_tract_weights_HH.sav'.
*DATASET NAME nhood_tract WINDOW=FRONT.

**********************
Get data, join on tract, calculate weighted values, then create a file 
aggregated on nhood with weighted values.
**********************.

*/Limited English and HH Languages.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Tract data\ACS_13_5YR_B16002_lim_Eng.csv"
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
  MarginofErrorTotal F3.0
  EstimateTotalEnglishonly F4.0
  MarginofErrorTotalEnglishonly F3.0
  EstimateTotalSpanish F4.0
  MarginofErrorTotalSpanish F3.0
  EstimateTotalSpanishLimitedEnglishspeakinghousehold F3.0
  MarginofErrorTotalSpanishLimitedEnglishspeakingho F3.0
  EstimateTotalSpanishNotalimitedEnglishspeakinghou F3.0
  MarginofErrorTotalSpanishNotalimitedEnglishspeak F3.0
  EstimateTotalOtherIndoEuropeanlanguages F4.0
  MarginofErrorTotalOtherIndoEuropeanlanguages F3.0
  EstimateTotalOtherIndoEuropeanlanguagesLimitedEngl F3.0
  MarginofErrorTotalOtherIndoEuropeanlanguagesLimit F3.0
  EstimateTotalOtherIndoEuropeanlanguagesNotalimite F3.0
  MarginofErrorTotalOtherIndoEuropeanlanguagesNota F3.0
  EstimateTotalAsianandPacificIslandlanguages F3.0
  MarginofErrorTotalAsianandPacificIslandlanguages_B F3.0
  EstimateTotalAsianandPacificIslandlanguagesLimited F3.0
  MarginofErrorTotalAsianandPacificIslandlanguages_A F3.0
  EstimateTotalAsianandPacificIslandlanguagesNotal F3.0
  MarginofErrorTotalAsianandPacificIslandlanguages F3.0
  EstimateTotalOtherlanguages F3.0
  MarginofErrorTotalOtherlanguages F3.0
  EstimateTotalOtherlanguagesLimitedEnglishspeakingh F2.0
  MarginofErrorTotalOtherlanguagesLimitedEnglishspe F2.0
  EstimateTotalOtherlanguagesNotalimitedEnglishspea F3.0
  MarginofErrorTotalOtherlanguagesNotalimitedEngli F3.0.
CACHE.
EXECUTE.
DATASET NAME LimEng WINDOW=FRONT.

*/Calculate variables.
COMPUTE Total_HH=EstimateTotal.
COMPUTE EnglishOnly=EstimateTotalEnglishonly.
COMPUTE Spanish=EstimateTotalSpanish.
COMPUTE OtherIndoEuropeanLang=EstimateTotalOtherIndoEuropeanlanguages.
COMPUTE AsianandPacificIslandLang=EstimateTotalAsianandPacificIslandlanguages.
COMPUTE Otherlanguages=EstimateTotalOtherlanguages.
COMPUTE LimitedEnglish	=(EstimateTotalSpanishLimitedEnglishspeakinghousehold +  EstimateTotalOtherIndoEuropeanlanguagesLimitedEngl +  
EstimateTotalAsianandPacificIslandlanguagesLimited +  EstimateTotalOtherlanguagesLimitedEnglishspeakingh).
COMPUTE NOTLimitedEnglish=(	EstimateTotalSpanishNotalimitedEnglishspeakinghou+EstimateTotalOtherIndoEuropeanlanguagesNotalimite +
EstimateTotalAsianandPacificIslandlanguagesNotal+EstimateTotalOtherlanguagesNotalimitedEnglishspea).
EXECUTE.
FORMATS Total_HH to NOTLimitedEnglish(F8.0).
EXECUTE.

*********
Merge LimEng onto nhood_tract
*********.
DATASET ACTIVATE LimEng.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.

DATASET ACTIVATE nhood_tract.
MATCH FILES /FILE=*
  /TABLE='LimEng'
  /RENAME (EstimateTotal EstimateTotalAsianandPacificIslandlanguages 
    EstimateTotalAsianandPacificIslandlanguagesLimited EstimateTotalAsianandPacificIslandlanguagesNotal 
    EstimateTotalEnglishonly EstimateTotalOtherIndoEuropeanlanguages 
    EstimateTotalOtherIndoEuropeanlanguagesLimitedEngl 
    EstimateTotalOtherIndoEuropeanlanguagesNotalimite EstimateTotalOtherlanguages 
    EstimateTotalOtherlanguagesLimitedEnglishspeakingh 
    EstimateTotalOtherlanguagesNotalimitedEnglishspea EstimateTotalSpanish 
    EstimateTotalSpanishLimitedEnglishspeakinghousehold 
    EstimateTotalSpanishNotalimitedEnglishspeakinghou Geography Id MarginofErrorTotal 
    MarginofErrorTotalAsianandPacificIslandlanguages MarginofErrorTotalAsianandPacificIslandlanguages_A 
    MarginofErrorTotalAsianandPacificIslandlanguages_B MarginofErrorTotalEnglishonly 
    MarginofErrorTotalOtherIndoEuropeanlanguages MarginofErrorTotalOtherIndoEuropeanlanguagesLimit 
    MarginofErrorTotalOtherIndoEuropeanlanguagesNota MarginofErrorTotalOtherlanguages 
    MarginofErrorTotalOtherlanguagesLimitedEnglishspe MarginofErrorTotalOtherlanguagesNotalimitedEngli 
    MarginofErrorTotalSpanish MarginofErrorTotalSpanishLimitedEnglishspeakingho 
    MarginofErrorTotalSpanishNotalimitedEnglishspeak = d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 
    d14 d15 d16 d17 d18 d19 d20 d21 d22 d23 d24 d25 d26 d27 d28 d29) 
  /BY census_tract
  /DROP= d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15 d16 d17 d18 d19 d20 d21 d22 d23 d24 
    d25 d26 d27 d28 d29.
EXECUTE.

*/Calculate weighted variables.
COMPUTE Total_HH_wtd=(nhood_tract_wght*Total_HH).
COMPUTE EnglishOnly_wtd	=(nhood_tract_wght*EnglishOnly).
COMPUTE Spanish_wtd=(nhood_tract_wght*Spanish).
COMPUTE OtherIndoEuropeanLang_wtd=(nhood_tract_wght*OtherIndoEuropeanLang).
COMPUTE AsianandPacificIslandLang_wtd=(nhood_tract_wght*AsianandPacificIslandLang).
COMPUTE Otherlanguages_wtd=(nhood_tract_wght*Otherlanguages).
COMPUTE LimitedEnglish_wtd=	(nhood_tract_wght*LimitedEnglish).
COMPUTE NOTLimitedEnglish_wtd=(nhood_tract_wght*NOTLimitedEnglish).
EXECUTE.
FORMATS Total_HH_wtd to NOTLimitedEnglish_wtd(F5.0).
EXECUTE.

*********
Aggregate weighted LimEng data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE nhood_tract.
DATASET DECLARE Nhood_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='Nhood_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
  /Total_HH_wtd=SUM(Total_HH_wtd) 
  /EnglishOnly_wtd=SUM(EnglishOnly_wtd) 
  /Spanish_wtd=SUM(Spanish_wtd) 
  /OtherIndoEuropeanLang_wtd=SUM(OtherIndoEuropeanLang_wtd) 
  /AsianandPacificIslandLang_wtd=SUM(AsianandPacificIslandLang_wtd) 
  /Otherlanguages_wtd=SUM(Otherlanguages_wtd) 
  /LimitedEnglish_wtd=SUM(LimitedEnglish_wtd) 
  /NOTLimitedEnglish_wtd=SUM(NOTLimitedEnglish_wtd).
EXECUTE.

DATASET ACTIVATE Nhood_wtd.
FORMATS Total_HH_wtd to NOTLimitedEnglish_wtd (F5.0).
EXECUTE.

DATASET CLOSE LimEng.

******Haven't assessed whether MOEs will be possible - don't think you can weight MOEs****.




*/HH income.
GET DATA
  /TYPE=TXT
  /FILE="P:\WORK\Kim\NNIP\Nhood_Block_working\Tract data\ACS_13_5YR_B19001_hh_income.csv"
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
  MarginofErrorTotal F3.0
  EstimateTotalLessthan$10000 F3.0
  MarginofErrorTotalLessthan$10000 F3.0
  EstimateTotal$10000to$14999 F3.0
  MarginofErrorTotal$10000to$14999 F3.0
  EstimateTotal$15000to$19999 F3.0
  MarginofErrorTotal$15000to$19999 F3.0
  EstimateTotal$20000to$24999 F3.0
  MarginofErrorTotal$20000to$24999 F3.0
  EstimateTotal$25000to$29999 F3.0
  MarginofErrorTotal$25000to$29999 F3.0
  EstimateTotal$30000to$34999 F3.0
  MarginofErrorTotal$30000to$34999 F3.0
  EstimateTotal$35000to$39999 F3.0
  MarginofErrorTotal$35000to$39999 F3.0
  EstimateTotal$40000to$44999 F3.0
  MarginofErrorTotal$40000to$44999 F3.0
  EstimateTotal$45000to$49999 F3.0
  MarginofErrorTotal$45000to$49999 F3.0
  EstimateTotal$50000to$59999 F3.0
  MarginofErrorTotal$50000to$59999 F3.0
  EstimateTotal$60000to$74999 F3.0
  MarginofErrorTotal$60000to$74999 F3.0
  EstimateTotal$75000to$99999 F3.0
  MarginofErrorTotal$75000to$99999 F3.0
  EstimateTotal$100000to$124999 F3.0
  MarginofErrorTotal$100000to$124999 F3.0
  EstimateTotal$125000to$149999 F3.0
  MarginofErrorTotal$125000to$149999 F3.0
  EstimateTotal$150000to$199999 F3.0
  MarginofErrorTotal$150000to$199999 F3.0
  EstimateTotal$200000ormore F3.0
  MarginofErrorTotal$200000ormore F3.0.
CACHE.
EXECUTE.
DATASET NAME HH_Income WINDOW=FRONT.

*/Calculate variables.
COMPUTE Total_HH=EstimateTotal.
COMPUTE HH_Lessthan$20000=(EstimateTotalLessthan$10000+EstimateTotal$10000to$14999+EstimateTotal$15000to$19999).
COMPUTE HH_$20000to$29999=(EstimateTotal$20000to$24999+EstimateTotal$25000to$29999).
COMPUTE HH_$30000to$49999=(EstimateTotal$30000to$34999+EstimateTotal$35000to$39999+EstimateTotal$40000to$44999+EstimateTotal$45000to$49999).
COMPUTE HH_$50000to$74999=(EstimateTotal$50000to$59999+EstimateTotal$60000to$74999).
COMPUTE HH_$75000ormore=(EstimateTotal$75000to$99999+EstimateTotal$100000to$124999+EstimateTotal$125000to$149999+EstimateTotal$150000to$199999+EstimateTotal$200000ormore).
EXECUTE.
FORMATS Total_HH to HH_$75000ormore(F8.0).
EXECUTE.

*********
Merge nhood_tract tract info onto HH income
*********.
DATASET ACTIVATE HH_Income.
SORT CASES BY census_tract.
DATASET ACTIVATE nhood_tract.
SORT CASES BY census_tract.
DATASET ACTIVATE HH_Income.
MATCH FILES /TABLE=*
  /FILE='nhood_tract'
  /RENAME (AsianandPacificIslandLang AsianandPacificIslandLang_wtd EnglishOnly EnglishOnly_wtd 
    LimitedEnglish LimitedEnglish_wtd NOTLimitedEnglish NOTLimitedEnglish_wtd OtherIndoEuropeanLang 
    OtherIndoEuropeanLang_wtd Otherlanguages Otherlanguages_wtd Spanish Spanish_wtd Total_HH 
    Total_HH_wtd = d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15) 
  /BY census_tract
  /DROP= d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15.
EXECUTE.


*/Calculate weighted variables.
COMPUTE Total_HH_wtd=(nhood_tract_wght*EstimateTotal).
COMPUTE HH_Lessthan$10000_wtd=(nhood_tract_wght*EstimateTotalLessthan$10000).
COMPUTE HH_$10000to$14999_wtd=(nhood_tract_wght*EstimateTotal$10000to$14999).
COMPUTE HH_$15000to$19999_wtd=(nhood_tract_wght*EstimateTotal$15000to$19999).
COMPUTE HH_$20000to$24999_wtd=(nhood_tract_wght*EstimateTotal$20000to$24999).
COMPUTE HH_$25000to$29999_wtd=(nhood_tract_wght*EstimateTotal$25000to$29999).
COMPUTE HH_$30000to$34999_wtd=(nhood_tract_wght*EstimateTotal$30000to$34999).
COMPUTE HH_$35000to$39999_wtd=(nhood_tract_wght*EstimateTotal$35000to$39999).
COMPUTE HH_$40000to$44999_wtd=(nhood_tract_wght*EstimateTotal$40000to$44999).
COMPUTE HH_$45000to$49999_wtd=(nhood_tract_wght*EstimateTotal$45000to$49999).
COMPUTE HH_$50000to$59999_wtd=(nhood_tract_wght*EstimateTotal$50000to$59999).
COMPUTE HH_$60000to$74999_wtd=(nhood_tract_wght*EstimateTotal$60000to$74999).
COMPUTE HH_$75000to$99999_wtd=(nhood_tract_wght*EstimateTotal$75000to$99999).
COMPUTE HH_$100000to$124999_wtd=(nhood_tract_wght*EstimateTotal$100000to$124999).
COMPUTE HH_$125000to$149999_wtd=(nhood_tract_wght*EstimateTotal$125000to$149999).
COMPUTE HH_$150000to$199999_wtd=(nhood_tract_wght*EstimateTotal$150000to$199999).
COMPUTE HH_$200000ormore_wtd=(nhood_tract_wght*EstimateTotal$200000ormore).
COMPUTE HH_Lessthan$20000_wtd=(nhood_tract_wght*HH_Lessthan$20000).
COMPUTE HH_$20000to$29999_wtd=(nhood_tract_wght*HH_$20000to$29999).
COMPUTE HH_$30000to$49999_wtd=(nhood_tract_wght*HH_$30000to$49999).
COMPUTE HH_$50000to$74999_wtd=(nhood_tract_wght*HH_$50000to$74999).
COMPUTE HH_$75000ormore_wtd=(nhood_tract_wght*HH_$75000ormore).
EXECUTE.
FORMATS Total_HH_wtd to HH_$75000ormore_wtd(F5.0).
EXECUTE.

*********
Aggregate weighted income data to neighborhoods and create nhood file
*********.
DATASET ACTIVATE HH_Income.
DATASET DECLARE HH_Income_wtd.
SORT CASES BY neighborhood_first.
AGGREGATE
  /OUTFILE='HH_Income_wtd'
  /PRESORTED
  /BREAK=neighborhood_first
  /Total_HH_wtd=SUM(Total_HH_wtd) 
  /HH_$10000to$14999_wtd=SUM(HH_$10000to$14999_wtd) 
  /HH_$15000to$19999_wtd=SUM(HH_$15000to$19999_wtd) 
  /HH_$20000to$24999_wtd=SUM(HH_$20000to$24999_wtd) 
  /HH_$25000to$29999_wtd=SUM(HH_$25000to$29999_wtd) 
  /HH_$30000to$34999_wtd=SUM(HH_$30000to$34999_wtd) 
  /HH_$35000to$39999_wtd=SUM(HH_$35000to$39999_wtd) 
  /HH_$40000to$44999_wtd=SUM(HH_$40000to$44999_wtd) 
  /HH_$45000to$49999_wtd=SUM(HH_$45000to$49999_wtd)
  /HH_$50000to$59999_wtd=SUM(HH_$50000to$59999_wtd) 
  /HH_$60000to$74999_wtd=SUM(HH_$60000to$74999_wtd) 
  /HH_$75000to$99999_wtd=SUM(HH_$75000to$99999_wtd) 
  /HH_$100000to$124999_wtd=SUM(HH_$100000to$124999_wtd) 
  /HH_$125000to$149999_wtd=SUM(HH_$125000to$149999_wtd) 
  /HH_$150000to$199999_wtd=SUM(HH_$150000to$199999_wtd)
  /HH_$200000ormore_wtd=SUM(HH_$200000ormore_wtd) 
  /HH_Lessthan$20000_wtd=SUM(HH_Lessthan$20000_wtd) 
  /HH_$20000to$29999_wtd=SUM(HH_$20000to$29999_wtd) 
  /HH_$30000to$49999_wtd=SUM(HH_$30000to$49999_wtd) 
  /HH_$50000to$74999_wtd=SUM(HH_$50000to$74999_wtd) 
  /HH_$75000ormore_wtd=SUM(HH_$75000ormore_wtd).
EXECUTE.


DATASET ACTIVATE HH_Income_wtd.
FORMATS Total_HH_wtd to HH_$75000ormore_wtd (F5.0).
EXECUTE.

DATASET CLOSE HH_Income.

DATASET ACTIVATE Nhood_wtd.
MATCH FILES /TABLE=*
  /FILE='HH_Income_wtd'
  /BY neighborhood_first.
EXECUTE.

DATASET CLOSE HH_Income_wtd.
DATASET CLOSE nhood_tract.

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


SAVE TRANSLATE OUTFILE='P:\WORK\Kim\NNIP\Nhood_Block_working\nhood_trct_wtd_HH.csv'
  /TYPE=CSV
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.



