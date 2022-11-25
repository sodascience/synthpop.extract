# load the package
library(synthpop.extract)



## =====================================
## Implement logreg
## =====================================

# load example data
data("Birthweight")

# only use the subset
bw <- Birthweight[,c(6,7,15,9)]

# for synthopop::syn to recognize them as binary variables
bw$lowbwt <- as.factor(bw$lowbwt)
bw$msmoker <- as.factor(bw$msmoker)

synds <- synthpop::syn(bw, model=T, method=c("sample", "norm", "logreg", "norm"))

# get the parameters
res <- synp_get_param(bw, synds)

# export to excel
synp_write_sheets(res, "try_addlog.xlsx")

# read in the parameters
par <- synp_read_sheets("try_addlog.xlsx")

# generate synthetic data
syn_log <- synp_gen_syndat(par, n = nrow(bw))

# it's a b it off... :-( (but then "mage" is not really normally distributed)
summary(syn_log); summary(bw); summary(synds$syn)

