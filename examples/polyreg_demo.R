# load the packages
library(synthpop.extract)
library(dplyr)


#################################################
## example case (polyreg is not the first var) ##
#################################################

# load the example data
data("Birthweight")

## due to disclosure control, we merge two categories
polydat <- data.frame(as.factor(ifelse(Birthweight$mnocig < 1, '0',
                                       ifelse(Birthweight$mnocig < 15, '<15', '15+'))))
colnames(polydat) <- "mnocig"

polydat$fnocig <- as.factor(ifelse(Birthweight$fnocig < 1, '0',
                                   ifelse(Birthweight$fnocig < 15, '<15', '15+')))

# check the dataset
table(polydat$mnocig)
table(polydat$fnocig)
str(polydat)

polydat <- polydat %>%
  # add some normal variables to the dataset
  mutate(mheight = Birthweight$mheight, Bweight = Birthweight$Birthweight) %>%
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
synp_write_sheets(res, "try_addpoly.xlsx")

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
synp_write_sheets(res2, "try_addpoly2.xlsx")

## 4) read in the parameters
par2 <- synp_read_sheets("try_addpoly2.xlsx")

## 5) generate synthetic data
syn_poly2 <- synp_gen_syndat(par2, n = nrow(polydat2))

# check the result
summary(syn_poly2); summary(polydat2); summary(synobj2$syn)

