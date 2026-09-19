rm(list = ls())

library(tidyverse)
library(broom)

project_root <- normalizePath(getwd())
b2020 <- read.csv(file.path(project_root, "data", "processed", "disability_work_2020.csv"))
b2022 <- read.csv(file.path(project_root, "data", "processed", "disability_work_2022.csv"))

# Create missing columns
b2020 <- b2020 %>%
  mutate(
    l_other = ifelse(other != 0, log(other), 0), 
    disability = ifelse(rowSums(select(., dis_walk, dis_see, dis_arm, dis_learn, 
                                       dis_hear, dis_dress, dis_talk, dis_ment)) != 0, 1, 0),
    mandatory = ifelse(rowSums(select(., secondary, bac, higher)) != 0, 1, 0),
    physical = ifelse(rowSums(select(., dis_walk, dis_arm, dis_dress)) != 0, 1, 0),
    sensory = ifelse(rowSums(select(., dis_hear, dis_see, dis_talk)) != 0, 1, 0),
    mental = ifelse(rowSums(select(., dis_ment)) != 0, 1, 0),
    intellectual = ifelse(rowSums(select(., dis_learn)) != 0, 1, 0)
  )

b2022 <- b2022 %>%
  mutate(
    l_other = ifelse(other != 0, log(other), 0), 
    disability = ifelse(rowSums(select(., dis_walk, dis_see, dis_arm, dis_learn, 
                                       dis_hear, dis_dress, dis_talk, dis_ment)) != 0, 1, 0),
    mandatory = ifelse(rowSums(select(., secondary, bac, higher)) != 0, 1, 0),
    physical = ifelse(rowSums(select(., dis_walk, dis_arm, dis_dress)) != 0, 1, 0),
    sensory = ifelse(rowSums(select(., dis_hear, dis_see, dis_talk)) != 0, 1, 0),
    mental = ifelse(rowSums(select(., dis_ment)) != 0, 1, 0),
    intellectual = ifelse(rowSums(select(., dis_learn)) != 0, 1, 0)
  )

# Check difference in means
t_stats <- map_dfr(names(b2022), ~ {
  test <- t.test(b2022[[.x]], b2020[[.x]])                      # Perform t-test
  tidy(test) %>%                                                # Convert to tidy format
  mutate(variable = .x) %>%                                     # Add column name
  select(variable, everything())  
})

# Regression

# Pooled regression on years

b2020.p <- b2020 %>% 
  mutate("2022" = FALSE)

b2022.p <- b2022 %>% 
  mutate("2022" = TRUE)

b2020.r <- b2020.p %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age, health_prob,`2022`)

b2022.r <- b2022.p %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age, health_prob, `2022`)

pool <- bind_rows(b2022.r, b2020.r)

modelp <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = pool)
summary(modelp)

# Pooled regression on years with interaction terms

pool.interaction <- pool %>% 
  mutate(disability_2022 = disability*`2022`)

modelp.interaction <- glm(work_lwk ~ .,
              family = binomial(link = "probit"),
              data = pool.interaction)
summary(modelp.interaction)

# work_lwk (1)

b2020.r <- b2020 %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age, health_prob)

b2022.r <- b2022 %>% 
  select(work_lwk,dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age, health_prob)

model1.2020 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2020.r)
summary(model1.2020)

model1.2022 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2022.r)
summary(model1.2022)

# work_lwk (3)

b2020.r <- b2020 %>% 
  select(work_lwk, dis_learn, dis_ment, physical, sensory,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age)

b2022.r <- b2022 %>% 
  select(work_lwk, dis_learn, dis_ment, physical, sensory,
         mandatory, exp, married, female, isp, disability,
         dis_ben, l_other, age)

model2.2020 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2020.r)
summary(model2.2020)

model2.2022 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2022.r)
summary(model2.2022)

# work_lwk (5)

b2020.r <- b2020 %>% 
  select(work_lwk, mandatory, exp, married, female, isp, 
         disability, dis_ben, l_other, age)

b2022.r <- b2022 %>% 
  select(work_lwk, mandatory, exp, married, female, isp, 
         disability, dis_ben, l_other, age)

model3.2020 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2020.r)
summary(model3.2020)

model3.2022 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2022.r)
summary(model3.2022)

# work_lwk (early onset)

b2020.r <- b2020 %>% 
  filter(cause_walk == 1 | 
           cause_see == 1 | 
           cause_arm == 1 | 
           cause_learn == 1 | 
           cause_hear == 1 | 
           cause_dress == 1 | 
           cause_talk == 1 | 
           cause_ment == 1 &
           disability == 1) %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, dis_ben, l_other, 
         age)

b2022.r <- b2022 %>% 
  filter(cause_walk == 1 | 
           cause_see == 1 | 
           cause_arm == 1 | 
           cause_learn == 1 | 
           cause_hear == 1 | 
           cause_dress == 1 | 
           cause_talk == 1 | 
           cause_ment == 1 &
           disability == 1) %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, dis_ben, l_other, 
         age)

model4.2020 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2020.r)
summary(model4.2020)

model4.2022 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2022.r)
summary(model4.2022)

# work_lwk (later)

b2020.r <- b2020 %>% 
  filter(cause_walk == 0 | 
           cause_see == 0 | 
           cause_arm == 0 | 
           cause_learn == 0 | 
           cause_hear == 0 | 
           cause_dress == 0 | 
           cause_talk == 0 | 
           cause_ment == 0) %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, dis_ben, l_other, 
         age)

b2022.r <- b2022 %>% 
  filter(cause_walk == 0 | 
           cause_see == 0 | 
           cause_arm == 0 | 
           cause_learn == 0 | 
           cause_hear == 0 | 
           cause_dress == 0 | 
           cause_talk == 0 | 
           cause_ment == 0) %>% 
  select(work_lwk, dis_walk, dis_see, dis_arm, dis_learn,
         dis_hear, dis_dress, dis_talk, dis_ment,
         mandatory, exp, married, female, isp, dis_ben, l_other, 
         age)

model4.2020 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2020.r)
summary(model4.2020)

model4.2022 <- glm(work_lwk ~ .,
                   family = binomial(link = "probit"),
                   data = b2022.r)
summary(model4.2022)
