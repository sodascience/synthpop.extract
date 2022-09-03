library(tidyverse)
source("synthpop_extractor.R")

#################################################
## example case (polyreg is not the first var) ##
#################################################

exampledata <- read.csv("Birthweight.csv")

# create categorical variables
polydat <- data.frame(as.factor(ifelse(exampledata$mnocig < 1, '0',
                                       ifelse(exampledata$mnocig < 10, '<10',
                                              ifelse(exampledata$mnocig < 26, '<25','25+')))))
colnames(polydat) <- "mnocig"

polydat$fnocig <- as.factor(ifelse(exampledata$fnocig < 1, '0',
                                   ifelse(exampledata$fnocig < 10, '<10',
                                          ifelse(exampledata$fnocig < 26, '<25','25+'))))
# check the dataset
table(polydat$mnocig)
table(polydat$fnocig)
str(polydat)

polydat <- polydat %>% 
  # add some normal variables to the dataset
  mutate(mheight = exampledata$mheight, Bweight = exampledata$Birthweight) %>% 
  # reorder columns (so that we can use polyreg for both categorical vars)
  relocate(where(is.numeric), .before = where(is.factor)) %>% 
  # reorder the categories in categorical variables
  mutate(mnocig = fct_relevel(mnocig, "0"), fnocig = fct_relevel(fnocig, "0"))

# check the dataset
GGally::ggpairs(polydat)

## 1) run synthpop
synobj <- synthpop::syn(polydat, method=c("sample", "norm", "polyreg", "polyreg"), models = TRUE)

## 2) get the parameters
res <- synp_get_param(polydat, synobj)

## 3) export to excel
writexl::write_xlsx(res, "try_addpoly.xlsx")

## 4) read in the parameters
par <- synp_read_sheets("try_addpoly.xlsx")

## 5) generate synthetic data 
syn_poly <- synp_gen_syndat(par, n = nrow(polydat))

# check the result
summary(syn_poly); summary(polydat); summary(synobj$syn)

#############################################
## example case (polyreg is the first var) ##
#############################################

polydat2 <- polydat %>% 
  # reorder columns (so that polyreg is the first variable)
  relocate(mnocig) 

## 1) run synthpop
synobj2 <- synthpop::syn(polydat2, method=c("sample", "norm", "norm", "polyreg"), models = TRUE)

## 2) get the parameters
res2 <- synp_get_param(polydat2, synobj2)

## 3) export to excel
writexl::write_xlsx(res2, "try_addpoly2.xlsx")

## 4) read in the parameters
par2 <- synp_read_sheets("try_addpoly2.xlsx")

## 5) generate synthetic data 
syn_poly2 <- synp_gen_syndat(par2, n = nrow(polydat2))

# check the result
summary(syn_poly2); summary(polydat2); summary(synobj2$syn)

