library(synthpop)
library(dplyr)
library(magrittr)

source("synthpop_extractor.R")


# data from synthpop package
data(SD2011)

# select some variables
ods <- SD2011 %>% 
  dplyr::select(sex, age, edu, ls, smoke) %>% 
  # convert them to ordered factors
  mutate(edu = ordered(edu), ls = ordered(ls)) %>% 
  na.omit()

# check the data
str(ods)

## =====================================
## Check the func. with polr method added
## =====================================
synds <- synthpop::syn(ods, method=c("sample", "norm", "polr", "polr", "logreg"), models=T)

# extract parameters
res <- synp_get_param(ods, synds)

# export to excel
writexl::write_xlsx(res, "try_polr1.xlsx")

# read in the parameters
par <- synp_read_sheets("try_polr1.xlsx")

# generate synthetic data 
syn_new <- synp_gen_syndat(par, n = nrow(ods))
str(syn_new)

# they are comparable!
summary(syn_new); summary(synds$syn); summary(ods)


## ========================================
## when polr method is used for the 1st var
## ========================================
# pick the ordered categorical variable as the first one
ods2 <- SD2011 %>% 
  dplyr::select(edu, sex, age, ls, smoke) %>% 
  # convert them to ordered factors
  mutate(edu = ordered(edu), ls = ordered(ls)) %>% 
  na.omit()

# create synds obj
synds2 <- synthpop::syn(ods2, method=c("sample", "logreg", "norm", "polr", "logreg"), models=T)

# extract parameters
res2 <- synp_get_param(ods2, synds2)

# export to excel
writexl::write_xlsx(res2, "try_polr2.xlsx")

# read in the parameters
par2 <- synp_read_sheets("try_polr2.xlsx")

# generate synthetic data 
syn_new2 <- synp_gen_syndat(par2, n = nrow(ods2))
str(syn_new2)

# they are comparable!
summary(syn_new2); summary(synds2$syn); summary(ods2)
