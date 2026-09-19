* Load the dataset
* Run this do-file from the repository root.
use "data/processed/disability_work.dta", clear

* Create cause_dis variable
gen cause_dis = 0
replace cause_dis = 1 if cause_walk == 1
replace cause_dis = 1 if cause_see == 1
replace cause_dis = 1 if cause_learn == 1
replace cause_dis = 1 if cause_hear == 1
replace cause_dis = 1 if cause_dress == 1
replace cause_dis = 1 if cause_talk == 1
replace cause_dis = 1 if cause_ment == 1
replace cause_dis = 1 if cause_arm == 1

* Create sensory, physical, and combined disability variables
gen sensory = (dis_see == 1 | dis_hear == 1 | dis_talk == 1)
gen physical = (dis_walk == 1 | dis_arm == 1 | dis_dress == 1)

gen sensory_physical = sensory * physical
gen sensory_mental = sensory * dis_ment
gen sensory_intel = sensory * dis_learn

gen physical_mental = physical * dis_ment
gen physical_intel = physical * dis_learn

gen mental_intel = dis_ment * dis_learn

* Global macro for disability categories
global cat dis_walk dis_see dis_arm dis_learn dis_hear dis_dress dis_talk dis_ment

* Tabulate cause_dis by each disability category
foreach var of global cat {
    tab cause_dis `var'
}

* Create a general disability variable
gen disability = (dis_walk == 1 | dis_see == 1 | dis_arm == 1 | dis_learn == 1 | dis_hear == 1 | dis_dress == 1 | dis_talk == 1 | dis_ment == 1)

* Summary statistics for demographic data by each disability category
foreach cat of global cat {
    summarize age children female married isp health_prob less_primary primary secondary bac higher help_job if `cat' == 1
}

* Summary statistics for demographic data with no disability
summarize age children female married isp health_prob less_primary primary secondary bac higher help_job if disability == 0

* Preserve the current data state
preserve 

* Uncomment the following lines if needed to reshape and tabulate newvar
* reshape long dis_, i(folioviv foliohog numren) j(newvar)
* tab newvar

restore

* Alternatively: Perform t-tests for each variable by disability status
foreach var in age children female married isp health_prob less_primary primary secondary bac higher help_job {
    ttest `var', by(disability)
}

* Summary statistics for work outcomes by each disability category
foreach cat of global cat {
    summarize work_lwk job_seeking pea work_dis subor self_emp informal tempo if `cat' == 1
}

* Summary statistics for work outcomes with no disability
summarize work_lwk job_seeking pea work_dis subor self_emp informal tempo if disability == 0

* Summary statistics excluding those with later-onset disabilities
summarize age children female married isp health_prob less_primary primary secondary bac higher help_job if disability == 1 & cause_dis == 1

* Understanding onsets: tabulate cause by type for each disability category
foreach cat of global cat {
    summarize cause_dis if `cat' == 1
}

* Summary statistics for work income by each disability category
foreach cat of global cat {
    summarize hours_wk wage work_inc dis_ben htrab no_pay no_wage if `cat' == 1 & work_lwk == 1
}

* Summary statistics for work income with no disability
summarize hours_wk wage work_inc dis_ben htrab no_pay no_wage if disability == 0

* Categorizing sinco
replace sinco = "Professionals and technicians" if substr(sinco, 1, 1) == "2"
replace sinco = "Auxiliary in administrative activity" if substr(sinco, 1, 1) == "3"
replace sinco = "Commercial and sales employees" if substr(sinco, 1, 1) == "4"
replace sinco = "Personal services and security" if substr(sinco, 1, 1) == "5"
replace sinco = "Workers in primary sector" if substr(sinco, 1, 1) == "6"
replace sinco = "Artisans" if substr(sinco, 1, 1) == "7"
replace sinco = "Industrial machinery operators, assemblers, drivers" if substr(sinco, 1, 1) == "8"
replace sinco = "Industrial low-skill workers" if substr(sinco, 1, 1) == "9"
replace sinco = "Foreign workers" if substr(sinco, 1, 1) == "0"

* Preserve the current data state
preserve
keep if age > 20 & age < 50

* T-test and histogram for exp by disability status
ttest exp, by(disability)
hist exp, by(disability)

restore

* Create and replace education variable
gen educ = 0 if illiterate == 1 | less_primary == 1
replace educ = 6 if primary == 1
replace educ = 9 if secondary == 1
replace educ = 12 if bac == 1
replace educ = 15 if higher == 1
