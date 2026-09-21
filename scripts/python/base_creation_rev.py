import pandas as pd
import numpy as np

from pathlib import Path

# Repository root directory
BASE_DIR = Path(__file__).resolve().parents[2]

# Raw data folder location
DATA_DIR = BASE_DIR / 'data' / 'raw'
PROCESSED_DIR = BASE_DIR / 'data' / 'processed'
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

################################################################################
#                                                                              #
#                             WORK DATASET                                     #
#                                                                              #
################################################################################                                                                                                                                                            

work_df = pd.read_csv(DATA_DIR / 'trabajos.csv', low_memory=False)

# Only keeping information on main occupation
work_df = work_df[work_df['id_trabajo']== 1]

# Job benefits
#   We are going to define four categories of jobs based on the benefits given to employees. According to the Ley Federal del Trabajo (nationally applicable labor law in Mexico) and the Ley del Seguro Social (general law for social security) state that there are some lawfully mandated? benefits
#   these include benefits 1-3, 5 7-8, 11,14, 17, 18 (10)
#   jobs may be then classified in the way that they comply with labor law (%) and the number of extra benefits that they offer.

work_df['leg_ben'] = work_df[['pres_1', 'pres_2', 'pres_3', 'pres_5', 'pres_7', 'pres_8', 'pres_11', 'pres_14', 'pres_17', 'pres_18']].apply(pd.to_numeric, errors='coerce').mean(axis=1)
work_df['extra_ben'] = work_df[['pres_4', 'pres_6', 'pres_9', 'pres_10', 'pres_12', 'pres_13', 'pres_15', 'pres_16', 'pres_19']].apply(pd.to_numeric, errors='coerce').sum(axis=1)

work_df['informal'] = (work_df['contrato'] == "2").astype(int)

work_df['tempo'] = 0
work_df.loc[(work_df['tipocontr'] == "1") & (work_df['informal'] != 1), 'tempo'] = 1

work_df['no_pay'] = 0
work_df.loc[(work_df['pago'] == "2") | (work_df['pago'] == "3"), 'no_pay'] = 1

work_df['subor'] = (work_df['subor'] == "1").astype(int)

work_df['indep'] = (work_df['indep'] == "1").astype(int)
work_df = work_df.rename(columns={'indep': 'self_emp'})


work_df['no_wage'] = np.nan
work_df.loc[work_df['tiene_suel'] == "1", 'no_wage'] = 0
work_df.loc[work_df['tiene_suel'] == "2", 'no_wage'] = 1

# Using already existing variables
# Keeping so far: folioviv foliohog numren informal tempo no_pay htrab scian(sector) sinco(type of job) leg_ben extra_ben 
work_df = work_df[['folioviv', 'foliohog', 'numren', 'subor', 'self_emp', 'htrab', 'sinco', 'scian', 'leg_ben', 'extra_ben', 'informal', 'tempo', 'no_pay', 'no_wage']]
work_df = work_df.sort_values(by = ['folioviv', 'foliohog', 'numren'])

work_df.to_csv(PROCESSED_DIR / 'work_english.csv', index=False)

################################################################################
#                                                                              #
#                             INCOME DATASET                                   #
#                                                                              #
################################################################################                                                                                                                                                            

income_df = pd.read_csv(DATA_DIR / 'ingresos.csv', low_memory=False)
income_df = income_df.loc[:, ~income_df.columns.str.startswith('mes') & (income_df.columns != 'ing_tri')]
    
# In order to simplify matters, we are going to be working with an average income for the six months recorded
# income_df = income_df.fillna(0)
income_df['avg_inc'] = income_df[['ing_1', 'ing_2', 'ing_3', 'ing_4', 'ing_5', 'ing_6']].apply(pd.to_numeric, errors='coerce').mean(axis=1)

income_df = income_df.loc[:, ~income_df.columns.str.startswith('ing')]

income_df = income_df.pivot_table(index=['folioviv', 'foliohog', 'numren'], columns='clave', values='avg_inc').reset_index()
income_df = income_df.fillna(0)

income_df['wage'] = income_df['P001'] + income_df['P011']
income_df['work_inc'] = income_df[['P002', 'P003', 'P004', 'P005', 'P006', 'P007', 'P008', 'P009', 'P012', 'P013']].sum(axis=1)

# Create a variable that captures other sources of income for individuals
income_df['other'] = 0
income_df['other'] = income_df[[col for col in income_df.columns if col.startswith('P')]].sum(axis=1)
income_df = income_df.rename(columns={'P105': 'dis_ben'})

income_df['other'] = income_df['other'] - income_df['wage'] - income_df['work_inc'] - income_df['dis_ben']
income_df['other'] = np.where(income_df['other'] < 0, 0, income_df['other'])

income_df = income_df[['folioviv', 'foliohog', 'numren', 'wage', 'work_inc', 'dis_ben', 'other']]
income_df = income_df.sort_values(by = ['folioviv', 'foliohog', 'numren'])

income_df.to_csv(PROCESSED_DIR / 'income_english.csv', index=False)

################################################################################
#                                                                              #
#                             POPULATION DATASET                               #
#                                                                              #
################################################################################                                                                                                                                                            

population_df = pd.read_csv(DATA_DIR / 'poblacion.csv', low_memory=False)
population_df[['parentesco','edad','asis_esc','nivelaprob','gradoaprob','antec_esc','hablaind']
              ]=population_df[['parentesco','edad','asis_esc','nivelaprob','gradoaprob','antec_esc','hablaind']].apply(pd.to_numeric, errors='coerce')

# Following what CONEVAL does to estimate the poverty index, we exclude people who are in the household as housekeepers or guests
population_df = population_df[~((population_df['parentesco'] >= 400) & (population_df['parentesco'] < 500) |
                  (population_df['parentesco'] >= 700) & (population_df['parentesco'] < 800))]

# This database contains multiple types of variables that are of interest to us:
#	General demographical variables
#	Some variables related to timeuse and job status (PNEA)
#	DISABILITY: type, severity and cause
#	Health: access to medical services and presence of medical problems in the past year
#	Education: maximium grade of education achieved

##############################Demographical variables##############################
# Mostly renaming in this case

population_df = population_df.rename(columns={'edad': 'age',
                                              'hijos_sob' : 'children'})

population_df['female'] = (population_df['sexo'] == 2).astype(int)

# Consider married people those who live together and/or are legally married
population_df['married'] = 0
population_df.loc[population_df['edo_conyug'].isin(["1", "5"]), 'married'] = 1

# Following CONEVAL, define ethnicity based on speaking an indigenous tongue
population_df['isp'] = (population_df['hablaind'] == 1).astype(int)

# Keeping: age children female married isp

##############################Disability variables##############################
# Following both the Washington's group recomendations and CONEVAL methodology, we define persons with a disability those individuals who either cannot do an activity, or do so with a lot of difficulty
population_df['dis_walk'] = 0
population_df.loc[(population_df['disc_camin'] == "2") | (population_df['disc_camin'] == "1"), 'dis_walk'] = 1
population_df['dis_see'] = 0
population_df.loc[(population_df['disc_ver'] == "2") | (population_df['disc_ver'] == "1"), 'dis_see'] = 1
population_df['dis_arm'] = 0
population_df.loc[(population_df['disc_brazo'] == "2") | (population_df['disc_brazo'] == "1"), 'dis_arm'] = 1
population_df['dis_learn'] = 0
population_df.loc[(population_df['disc_apren'] == "2") | (population_df['disc_apren'] == "1"), 'dis_learn'] = 1
population_df['dis_hear'] = 0
population_df.loc[(population_df['disc_oir'] == "2") | (population_df['disc_oir'] == "1"), 'dis_hear'] = 1
population_df['dis_dress'] = 0
population_df.loc[(population_df['disc_vest'] == "2") | (population_df['disc_vest'] == "1"), 'dis_dress'] = 1
population_df['dis_talk'] = 0
population_df.loc[(population_df['disc_habla'] == "2") | (population_df['disc_habla'] == "1"), 'dis_talk'] = 1
population_df['dis_ment'] = 0
population_df.loc[(population_df['disc_acti'] == "2") | (population_df['disc_acti'] == "1"), 'dis_ment'] = 1

# walk, see, arm, learn, hear, dress, talk, ment. Dummies of at-birth disability
population_df['cause_walk'] = (population_df['cau_camin'] == "3").astype(int)
population_df['cause_see'] = (population_df['cau_ver'] == "3").astype(int)
population_df['cause_arm'] = (population_df['cau_brazo'] == "3").astype(int)
population_df['cause_learn'] = (population_df['cau_apren'] == "3").astype(int)
population_df['cause_hear'] = (population_df['cau_oir'] == "3").astype(int)
population_df['cause_dress'] = (population_df['cau_vest'] == "3").astype(int)
population_df['cause_talk'] = (population_df['cau_habla'] == "3").astype(int)
population_df['cause_ment'] = (population_df['cau_acti'] == "3").astype(int)

population_df.loc[~population_df['disc_camin'].isin(["1", "2"]), 'disc_camin'] = 0
population_df.loc[~population_df['disc_ver'].isin(["1", "2"]), 'disc_ver'] = 0
population_df.loc[~population_df['disc_brazo'].isin(["1", "2"]), 'disc_brazo'] = 0
population_df.loc[~population_df['disc_apren'].isin(["1", "2"]), 'disc_apren'] = 0
population_df.loc[~population_df['disc_oir'].isin(["1", "2"]), 'disc_oir'] = 0
population_df.loc[~population_df['disc_vest'].isin(["1", "2"]), 'disc_vest'] = 0
population_df.loc[~population_df['disc_habla'].isin(["1", "2"]), 'disc_habla'] = 0
population_df.loc[~population_df['disc_acti'].isin(["1", "2"]), 'disc_acti'] = 0

population_df['sev_walk'] = 0
population_df.loc[population_df['disc_camin'] == "2", 'sev_walk'] = 1
population_df.loc[population_df['disc_camin'] == "1", 'sev_walk'] = 2

population_df['sev_see'] = 0
population_df.loc[population_df['disc_ver'] == "2", 'sev_see'] = 1
population_df.loc[population_df['disc_ver'] == "1", 'sev_see'] = 2

population_df['sev_arm'] = 0
population_df.loc[population_df['disc_brazo'] == "2", 'sev_arm'] = 1
population_df.loc[population_df['disc_brazo'] == "1", 'sev_arm'] = 2

population_df['sev_learn'] = 0
population_df.loc[population_df['disc_apren'] == "2", 'sev_learn'] = 1
population_df.loc[population_df['disc_apren'] == "1", 'sev_learn'] = 2

population_df['sev_hear'] = 0
population_df.loc[population_df['disc_oir'] == "2", 'sev_hear'] = 1
population_df.loc[population_df['disc_oir'] == "1", 'sev_hear'] = 2

population_df['sev_dress'] = 0
population_df.loc[population_df['disc_vest'] == "2", 'sev_dress'] = 1
population_df.loc[population_df['disc_vest'] == "1", 'sev_dress'] = 2

population_df['sev_talk'] = 0
population_df.loc[population_df['disc_habla'] == "2", 'sev_talk'] = 1
population_df.loc[population_df['disc_habla'] == "1", 'sev_talk'] = 2

population_df['sev_ment'] = 0
population_df.loc[population_df['disc_acti'] == "2", 'sev_ment'] = 1
population_df.loc[population_df['disc_acti'] == "1", 'sev_ment'] = 2

# Keeping dis* and cause*

##############################Health-related variables##############################
# For such reasons, Oi and Andrews (1992) advocated the use of health-related impairments, noting that disablement may affect the work–leisure choice in three distinct ways — the effect on individual preferences and hence the demand for leisure; the effect on productivity and the effect on the time available for work and leisure. (from Kidd et al 2000)

# Variable numbers 99, 100 and 101
# Define a work-impacting health problem in the past year if it ocurred in 2020 or in 2019 after july AND person went to get help (attended)

population_df['health_prob'] = 0
population_df.loc[population_df['prob_anio'] == "2020", 'health_prob'] = 1
population_df.loc[(population_df['prob_anio'] == "2019") & (pd.to_numeric(population_df['prob_mes'], errors='coerce') > 6), 'health_prob'] = 1

population_df['attended'] = (population_df['prob_sal'] == "1").astype(int)

population_df['health_prob'] = population_df['health_prob']*population_df['attended']
population_df.drop(columns=['attended'], inplace=True)

# Time spent in health-related care attendance
population_df[['hh_lug', 'mm_lug', 'hh_esp', 'mm_esp']] = population_df[['hh_lug', 'mm_lug', 'hh_esp', 'mm_esp']].apply(pd.to_numeric, errors='coerce')

population_df['time_health'] = (population_df['hh_lug'] +
                                population_df['mm_lug'] / 60 +
                                population_df['hh_esp'] +
                                population_df['mm_esp'] / 60)

# Keep health_prob time_health

##############################Education variables##############################
# Following the levels used in Mitra et al (2008)
population_df['illiterate'] = (population_df['nivelaprob'] == 0).astype(int)
population_df['less_primary'] = (population_df['nivelaprob'] == 1).astype(int)
population_df['primary'] = (population_df['nivelaprob'] == 2).astype(int)
population_df['secondary'] = (population_df['nivelaprob'] == 3).astype(int)
population_df['bac'] = 0
population_df.loc[(population_df['nivelaprob'] == 4) | (population_df['nivelaprob'] == 5), 'bac'] = 1
population_df['higher'] = 0
population_df.loc[(population_df['nivelaprob'] == 6) | (population_df['nivelaprob'] == 7) | (population_df['nivelaprob'] == 8) | (population_df['nivelaprob'] == 9), 'higher'] = 1

##############################Job related variables##############################
# We can build an experience dummy based on the number of years spent contributing to social security: we only have this data for subordinate persons in formal jobs
population_df['ss'] = (population_df['segsoc'] == "1").astype(int)
population_df[['ss_aa', 'ss_mm']] = population_df[['ss_aa', 'ss_mm']].apply(pd.to_numeric, errors='coerce')
population_df['exp'] = 0
population_df.loc[population_df['ss'] == 1, 'exp'] = population_df['ss_aa'] + population_df['ss_mm']/12

population_df['help_job'] = 0
population_df.loc[(population_df['redsoc_1'] == "3") | (population_df['redsoc_1'] == "4"), 'help_job'] = 1

population_df = population_df.rename(columns={'hor_1' : 'hours_wk',
                                              'hor_3' : 'hours_vol'})

population_df['work_lwk'] = (population_df['trabajo_mp'] == "1").astype(int)
population_df['job_seeking'] = (population_df['act_pnea1'] == "2").astype(int)
population_df['work_dis'] = (population_df['act_pnea2'] == "5").astype(int)

population_df['jcd'] = (population_df['c_futuro'] == "1").astype(int)

variables = ['sev_walk', 'sev_see', 'sev_arm', 'sev_learn', 'sev_hear', 'sev_dress', 'sev_talk', 'sev_ment']

population_df = population_df[
    [col for col in population_df.columns if col in [
        'folioviv', 'foliohog', 'numren', 'age', 'female', 'married', 'children', 'isp',
        'health_prob', 'time_health', 'illiterate', 'less_primary', 'primary', 'secondary',
        'bac', 'higher', 'ss', 'exp', 'help_job', 'hours_wk', 'hours_vol', 'work_lwk',
        'job_seeking', 'pea', 'work_dis', 'jcd'
    ] or col.startswith('dis') or col.startswith('cause')]
]

population_df.to_csv(PROCESSED_DIR / 'population_english.csv', index=False)

################################################################################
#                                                                              #
#                             MERGING DATASET                               #
#                                                                              #
################################################################################                                                                                                                                                            

merged_df = pd.merge(income_df, population_df, on=['folioviv', 'foliohog', 'numren'], how='left')
merged_df = pd.merge(merged_df, work_df, on=['folioviv', 'foliohog', 'numren'], how='left')

merged_df.to_csv(PROCESSED_DIR / 'disability_work.csv', index=False)
