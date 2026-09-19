*preliminaries

clear
cap log close;

* Run this do-file from the repository root.
capture mkdir "data/processed"

********************************************************************************
*                                                                              *
*                             WORK DATASET                                     *
*                                                                              *
********************************************************************************

use "data/raw/trabajos.dta"

*only keeping information on main occupation
drop if id_trabajo != "1"


*Job benefits
destring pres_*, replace force
 foreach num in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 {
 replace pres_`num' = pres_`num' == `num'
 }
 
 
 
	*We are going to define four categories of jobs based on the benefits given to employees. According to the Ley Federal del Trabajo (nationally applicable labor law in Mexico) and the Ley del Seguro Social (general law for social security) state that there are some lawfully mandated? benefits
	** these include benefits 1-3, 5 7-8, 11,14, 17, 18 (10)
	** jobs may be then classified in the way that they comply with labor law (%) and the number of extra benefits that they offer.

gen leg_ben = (pres_1 + pres_2 + pres_3 + pres_5 + pres_7 + pres_8 + pres_11 + pres_14 + pres_17 + pres_18)/10

gen extra_ben = pres_4 + pres_6 + pres_9 + pres_10 + pres_12 + pres_13 + pres_15 + pres_16 + pres_19

label var leg_ben "Measure of how much does this job comply with labor law"
label var extra_ben "How many extra benefits does this job offer"


gen informal = contrato == "2";
label var informal "Informal job defined as having a contract or not"
gen tempo = .
replace tempo = 1 if tipocontr == "1" & informal != 1
label var tempo "Conditional on having a contract, having a temporal contract"

gen no_pay = pago == "2" | "3"
label var no_pay "Denotes a job in which the employee receives no pay"

replace subor = subor == "1"
label var subor "Dummy variable equal to 1 if individual is employed by someone else (has a boss)"

replace indep = indep == "1"
label var indep "Dummy variable equal to 1 if individual is self-employed (freelance or enterpreneur)"
rename indep self_emp

gen no_wage = 0
replace no_wage = 1 if tiene_suel == "1"
label var no_wage "Dummy variable equal to 1 if individual has an assigned wage" 


*using already existing variables
label var htrab "Weekly hours of work of main occupation"
label var sinco "Classification of activities performed on the job"
label var scian "Classification of economic activity the individual is employed in"

*keeping so far: folioviv foliohog numren informal tempo no_pay htrab scian(sector) sinco(type of job) leg_ben extra_ben 



keep folioviv foliohog numren subor self_emp htrab sinco scian leg_ben extra_ben informal tempo no_pay no_wage
sort folioviv foliohog numren

save "data/processed/work_english.dta", replace


********************************************************************************
*                                                                              *
*                           INCOME DATASET                                     *
*                                                                              *
********************************************************************************
clear
use "data/raw/ingresos.dta"
drop mes*
drop ing_tri

*in order to simplify matters, we are going to be working with an average income for the six months recorded
foreach income in ing_1 ing_2 ing_3 ing_4 ing_5 ing_6{
	replace `income' = 0 if `income' == .
}

gen avg_inc = (ing_1+ing_2+ing_3+ing_4+ing_5+ing_6)/6
drop ing*

reshape wide avg_inc, i(folioviv foliohog numren) j(clave) string

global categories avg_incP001 avg_incP011 avg_incP002 avg_incP003 avg_incP004 avg_incP005 avg_incP006 avg_incP007 avg_incP008 avg_incP009 avg_incP012 avg_incP013 avg_incP105
foreach income in $categories {
	replace `income' = 0 if `income' == .
}

gen wage = avg_incP001 + avg_incP011
gen work_inc = avg_incP002 + avg_incP003 + avg_incP004 + avg_incP005 + avg_incP006 + avg_incP007 + avg_incP008 + avg_incP009 + avg_incP012 + avg_incP013

*create a variable that captures other sources of income for individuals
egen other = rowtotal(avg_inc*)
rename avg_incP105 dis_ben
replace other = other - wage - work_inc - dis_ben if other > 0
replace other = 0 if other < 0 

label var wage "Average monthly income by wage for main occupation"
label var work_inc "Monthly average work income other than wage for main occupation"
label var dis_ben "Monthly average transfer of government disability pension"
label var other "Monthly average of other sources of income for the individual"

keep folioviv foliohog numren wage work_inc dis_ben other
sort folioviv foliohog numren

save "data/processed/income_english.dta", replace

********************************************************************************
*                                                                              *
*                           POPULATION DATASET                                 *
*                                                                              *
********************************************************************************
clear
use "data/raw/poblacion.dta"
*following what CONEVAL does to estimate the poverty index, we exclude people who are in the household as housekeepers or guests
drop if parentesco>="400" & parentesco <"500"
drop if parentesco>="700" & parentesco <"800"

*This database contains multiple types of variables that are of interest to us:
	* General demographical variables
	*Some variables related to timeuse and job status (PNEA)
	* DISABILITY: type, severity and cause
	* Health: access to medical services and presence of medical problems in the past year
	*Education: maximium grade of education achieved

	
***********************Demographical variables**********************************
*mostly renaming in this case
rename edad age
rename hijos_sob children
gen female = sexo == "2"
*consider married people those who live together and/or are legally married
gen married = edo_conyug == "1"
replace married = 1 if edo_conyug == "2"
*Following CONEVAL, define ethnicity based on speaking an indigenous tongue
gen isp = hablaind == "1"
label var isp "Indigenous-tongue-speaking person"

	* Keeping: age children female married isp

**********************Disability variables**************************************
* Following both the Washington's group recomendations and CONEVAL methodology, we define persons with a disability those individuals who either cannot do an activity, or do so with a lot of difficulty
gen dis_walk = 0
replace dis_walk = 1 if disc_camin == "2" | disc_camin=="1"
gen dis_see = 0
replace dis_see = 1 if disc_ver == "2" | disc_ver=="1"
gen dis_arm = 0
replace dis_arm = 1 if disc_brazo== "2" | disc_brazo=="1"
gen dis_learn = 0
replace dis_learn = 1 if disc_apren== "2" | disc_apren=="1"
gen dis_hear = 0
replace dis_hear = 1 if disc_oir== "2" | disc_oir=="1"
gen dis_dress = 0
replace dis_dress = 1 if disc_vest == "2" | disc_vest=="1"
gen dis_talk = 0
replace dis_talk = 1 if disc_habla == "2" | disc_habla=="1"
gen dis_ment = 0
replace dis_ment = 1 if disc_acti == "2" | disc_acti=="1"

*walk, see, arm, learn, hear, dress, talk, ment. Dummies of at-birth disability
gen cause_walk = cau_camin == "3"
gen cause_see = cau_ver == "3"
gen cause_arm = cau_brazo == "3"
gen cause_learn = cau_apren == "3"
gen cause_hear = cau_oir == "3"
gen cause_dress = cau_vest == "3"
gen cause_talk = cau_habla == "3"
gen cause_ment = cau_acti == "3"

replace disc_camin = "0" if disc_camin != "1" & disc_camin != "2"
replace disc_ver = "0" if disc_ver != "1" & disc_ver != "2"
replace disc_brazo = "0" if disc_brazo!= "1" & disc_brazo != "2"
replace disc_apren = "0" if disc_apren != "1" & disc_apren != "2"
replace disc_oir = "0" if disc_oir != "1" & disc_oir != "2"
replace disc_vest = "0" if disc_vest != "1" & disc_vest != "2"
replace disc_habla = "0" if disc_habla != "1" & disc_habla != "2"
replace disc_acti = "0" if disc_acti != "1" & disc_acti != "2"


destring disc_camin disc_ver disc_brazo disc_apren disc_oir disc_vest disc_habla disc_acti , {sev_walk sev_see sev_arm sev_learn sev_hear sev_dress sev_talk sev_ment}


replace sev_walk = 1 if disc_camin == "2"
replace sev_walk = 2 if disc_camin == "1"

replace sev_see = 1 if disc_ver == "2"
replace sev_see = 2 if disc_ver == "1"

replace sev_arm = 1 if disc_brazo == "2"
replace sev_arm = 2 if disc_brazo == "1"

replace sev_learn = 1 if disc_apren == "2"
replace sev_learn = 2 if disc_apren == "1"

replace sev_hear = 1 if disc_oir == "2"
replace sev_hear = 2 if disc_oir == "1"

replace sev_dress = 1 if disc_vest == "2"
replace sev_dress = 2 if disc_vest == "1"

replace sev_talk = 1 if disc_habla == "2"
replace sev_talk = 2 if disc_habla== "1"

replace sev_ment = 1 if disc_acti == "2"
replace sev_ment = 2 if disc_acti == "1"





*keeping dis* and cause*

***********************Health-related variables*********************************
*For such reasons, Oi and Andrews (1992) advocated the use of health-related impairments, noting that disablement may affect the work–leisure choice in three distinct ways — the effect on individual preferences and hence the demand for leisure; the effect on productivity and the effect on the time available for work and leisure. (from Kidd et al 2000)

*variable numbers 99, 100 and 101
*define a work-impacting health problem in the past year if it ocurred in 2020 or in 2019 after july AND person went to get help (attended)

gen health_prob = 0
replace health_prob = 1 if prob_anio == "2020"
destring prob_mes, replace
replace health_prob = 1 if prob_anio == "2019" & prob_mes > 6

gen attended = prob_sal == "1"

replace health_prob = health_prob*attended
drop attended

*time spent in health-related care attendance
gen time_health = hh_lug + mm_lug/60 + hh_esp + mm_esp/60

*keep health_prob time_health


************************Education variables*************************************
*Following the levels used in Mitra et al (2008)
gen illiterate = nivelaprob == "0"
gen less_primary = nivelaprob == "1"
gen primary = nivelaprob == "2"
gen secondary = nivelaprob == "3"
gen bac = 0
replace bac = 1 if nivelaprob == "4"  | nivelaprob == "5"
gen higher = 0
replace higher = 1 if nivelaprob == "6"  | nivelaprob == "7"| nivelaprob == "8" | nivelaprob == "9"



***************************Job related variables********************************

*We can build an experience dummy based on the number of years spent contributing to social security: we only have this data for subordinate persons in formal jobs
gen ss = segsoc == "1"
gen exp = ss_a + ss_m/12 if ss == 1

gen help_job = 0
replace help_job = 1 if redsoc_1 == 3 | redsoc_1 == 4
label var help_job "Easy for this individual finding help for getting a job"

rename hor_1 hours_wk
rename hor_3 hours_vol

gen work_lwk = trabajo_mp == "1"
gen job_seeking = act_pnea1 == "2"
gen pea = work_lwk+job_seeking
gen work_dis = act_pnea2 == "5"
label var work_dis "Person has a physical or mental limitation that impedes work for the rest of their lives"

gen jcf = c_futuro == "1"


keep folioviv foliohog numren age female married children isp dis* cause* health_prob time_health illiterate less_primary primary secondary bac higher ss exp help_job hours_wk hours_vol work_lwk job_seeking pea work_dis jcf
sort folioviv foliohog numren
drop disc*

*add and change labels here
label var age "Age"
label var hours_wk "Hours spent working the previous week"
label var hours_vol "Hours spent on volunteering activities prev week"
label var children "Number of children"
label var female "1 if female"
label var married "1 if person married or cohabiting with partner"
label var dis_walk "Impossibility or difficulty in walking ability"
label var dis_see "Impossibility of difficulty in seeing"
label var dis_arm "Impossibility or difficulty in use of arms and hands"
label var dis_learn "Impossibility or difficulty in learning or remembering"
label var dis_hear "Impossibility or difficulty in hearing"
label var dis_dress "Impossibility or difficulty in caring (eat, dress or wash)"
label var dis_talk "Impossibility or difficulty in talking or communicating"
label var dis_ment "Limitation in daily activities mental/emotional distress"
label var cause_walk "1 if disability from birth"
label var cause_see "1 if disability from birth"
label var cause_arm "1 if disability from birth"
label var cause_learn "1 if disability from birth"
label var cause_hear "1 if disability from birth"
label var cause_dress "1 if disability from birth"
label var cause_talk "1 if disability from birth"
label var cause_ment "1 if disability from birth"
label var health_prob "Had a health problem in the previous year and got treated"
label var time_health "Time spent in travel and wait time to get treatment"
label var illiterate "No years of education"
label var less_primary "Has only passed preschool"
label var primary "Highest grade achieved is primary"
label var secondary "Highest grade achieved is secondary school"
label var bac "Highest grade achieved is highschool or normal school"
label var higher "Highest grade achieved is undergarduate or higher"
label var ss "Individual pays a contribution to social security"
label var exp "Proxy for experience: years contributing to social security"
label var work_lwk "Individual reports having worked last week"
label var job_seeking "Individual reports looking for work last week"
label var pea "Economically Active Population: employed and seeking work"
label var jcf "Beneficiary of Jóvenes Construyendo el Futuro program"

save "data/processed/population_english.dta", replace


 foreach var in sev_walk sev_see sev_arm sev_learn sev_hear sev_dress sev_talk sev_ment{
	graph bar work_lwk, over(`var') title(`var') ytitle("% worked last month")
	graph export workby_`var'.png
}






********************************************************************************
*                                                                              *
*                                 MERGING DATABASES                            *
*                                                                              *
********************************************************************************

clear

use "data/processed/income_english.dta"

merge 1:m folioviv foliohog numren using "Bases\population_english.dta", nogen
merge m:1 folioviv foliohog numren using "Bases\work_english.dta", nogen




save "data/processed/disability_work.dta", replace




