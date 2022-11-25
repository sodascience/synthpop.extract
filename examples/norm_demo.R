# load the packages
library(synthpop.extract)
library(MASS)
# source the function to change the numbers in column names to roman numerals
source("examples/number_to_roman.R")

## =====================================
## simulate normally-distributed data
## =====================================
set.seed(123)
# create the variance covariance matrix
sigma <- rbind(c(1,-0.4,-0.2),
               c(-0.4,1, 0.3),
               c(-0.2,0.3,1))
# create the mean vector
mu <- c(10, 5, 2)
# generate normally distributed variables
df <- as.data.frame(mvrnorm(n=1000, mu=mu, Sigma=sigma))
colnames(df) <- c("x1", "x2", "x3")



## =====================================
## Check the func. added logreg option with normal data
## =====================================
synds <- synthpop::syn(df, method=c(rep("norm",3)), models=T)
res <- synp_get_param(df, synds)

## need to convert the name to characters
colnames(df) <- num_to_roman(df) # change the numbers to roman numerals
synds <- synthpop::syn(df, method=c(rep("norm",3)), models=T)
res <- synp_get_param(df, synds)

# export to excel
synp_write_sheets(res, "try_newf.xlsx")

# read in the parameters
par <- synp_read_sheets("try_newf.xlsx")

# generate synthetic data
syn_new <- synp_gen_syndat(par)

# it's okay!
summary(syn_new); summary(df); summary(synds$syn)

