source("synthpop_extractor.R")


## =====================================
## number to roman numerals
## =====================================
#' Convert numbers to roman numerals in variable names
#' 
#' @param df the original data frame
#' 
#' @return converted version of column name vector
num_to_roman <- function(df){
  ori_colnames <- colnames(df)
  new_colnames <- c()
  
  for ( i in 1: length(ori_colnames)){
    roman <- as.roman(sapply(ori_colnames, function(x) str_extract_all(x, "\\d+")[[1]]))
    new_colnames[i] <- gsub("([0-9]+)", paste0("_",roman[i]), ori_colnames[i])
  }
  return(new_colnames)
}


## =====================================
## simulate normally-distributed data
## =====================================
library(MASS)

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
# df$y <- df$x1 + 2*df$x2 + 5*df$x3 + rnorm(1000)

## =====================================
## Try to implement logreg
## =====================================
exampledata <- read.csv("Birthweight.csv")
bw <- exampledata[,c(6,7,15,9)]
# for synthopop::syn to recognize them as binary variables
bw$lowbwt <- as.factor(bw$lowbwt)
bw$msmoker <- as.factor(bw$msmoker)

synds <- synthpop::syn(bw, model=T, method=c("sample", "norm", "logreg", "norm"))

# get the parameters
res <- synp_get_param(bw, synds)
# export to excel
writexl::write_xlsx(res, "try_addlog.xlsx")
# read in the parameters
par <- synp_read_sheets("try_addlog.xlsx")
# generate synthetic data 
syn_log <- synp_gen_syndat(par, n = nrow(bw))
# it's off... :-( (but then "mage" is not really normally distributed)
summary(syn_log); summary(bw); summary(synds$syn)


# ## =====================================
# ## Check the cleand func. with normal data
# ## =====================================
# synds <- synthpop::syn(df, method=c(rep("norm",3)), models=T)
# res <- synp_get_param(df, synds)
# # export to excel
# writexl::write_xlsx(res, "try_oldf.xlsx")
# # read in the parameters
# par <- synp_read_sheets("try_oldf.xlsx")
# # generate synthetic data 
# syn_old <- synp_gen_syndat(par)
# # it's okay!
# summary(syn_old); summary(df)


## =====================================
## Check the func. added logreg option with normal data
## =====================================
synds <- synthpop::syn(df, method=c(rep("norm",3)), models=T)
res <- synp_get_param(df, synds)
## need to convert the name to char. --> run again
colnames(df) <- num_to_roman(df)
synds <- synthpop::syn(df, method=c(rep("norm",3)), models=T)
res <- synp_get_param(df, synds)
# export to excel
writexl::write_xlsx(res, "try_newf.xlsx")
# read in the parameters
par <- synp_read_sheets("try_newf.xlsx")
# generate synthetic data 
syn_new <- synp_gen_syndat(par)
# it's okay!
summary(syn_new); summary(df); summary(synds$syn)

