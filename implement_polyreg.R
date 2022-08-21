#' Extract parameter list from synds object  
#' 
#' @param df the original data frame
#' @param synds the fitted synds object
#' 
#' @details 
#' The synds object should be run with a parametric method and with the argument `models = TRUE`
#' 
#' @return a list of data frames
synp_get_param_addpoly <- function(df, synds) {
  # check that only parametric methods were used
  allowed_methods <- c("norm", "logreg", "polyreg")  
  # TODO: far future: "polyreg", "polyr"
  used_methods <- synds$method 
  if (!all(used_methods[-1] %in% allowed_methods)) 
    stop("Extracting method should be parametric.")
  
  # extract parameters
  if (is.null(synds$models)) 
    stop("Run synthpop::syn() with argument `models = TRUE` to extract parameters")
  if(any(stringr::str_detect(colnames(df), "\\d"))) 
    stop("Numbers are not allowed in the variable names. Please consider converting them into alphabet characters")
  params <- synds$models
  col_nm <- names(params)
  
  # create exportable storage format for betas and sigma
  par_list <- list()
  
  # for the first variable, 
  # extract mean and sd from the original data when "norm" and
  # extract probability when "logreg"
  first_var <- df[,1]
  if(is.factor(first_var) && nlevels(first_var)==2){ # since synthpop by default uses "sample" method for the first variable... 
    pt <- prop.table(table(first_var)) # prop. table
    par_list[[1]] <- data.frame(          
      param = c("prob", "label(0)", "label(1)"),               
      value = c(pt[[2]], names(pt)) 
    )
    used_methods[1] <- "logreg" # change the used method to "logreg" instead of "sample"
    
  } else if (is.factor(first_var) && nlevels(first_var) > 2){
    pt <- prop.table(table(first_var)) # prop. table
    par_list[[1]] <- as.data.frame(pt)
    colnames(par_list[[1]]) <- c("cat_label", "probability")
    used_methods[1] <- "polyreg"
  }  else if (!is.factor(first_var) && length(unique(first_var)) <= 10){ ## how many categories would be considered as categorical?...
    stop("Please convert the dicothomous/categorical variable to a factor in order to implement `logreg`/`polyreg`.")
    
  }else{ # "norm" method
    par_list[[1]] <- data.frame(
      param = c("mean", "sd"),
      value = c(mean(df[[col_nm[1]]], na.rm = TRUE), sd(df[[col_nm[1]]], na.rm = TRUE))
    )
    used_methods[1] <- "norm"
  }
  
  # for remaining variables, 
  # extract betas and sigma when "norm" and
  # extract betas and level labels when "logreg"
  for (i in 2:length(params)) {
    if(used_methods[[i]]=="norm"){
      par_list[[i]] <- data.frame(
        param = c(paste0("b", 0:(length(params[[i]]$beta)-1)), "sd"),
        value = c(params[[i]]$beta, params[[i]]$sigma)
      )
    }
    
    if(used_methods[[i]]=="logreg"){
      betas <- unname(coef(params[[i]])[,1])
      par_list[[i]] <- data.frame(
        param = c(paste0("b", 0:(length(betas)-1)),  "label(0)", "label(1)"),
        value = c(betas, names(pt))
      )
    }
    
    if(used_methods[[i]]=="polyreg"){
      betas <- as.data.frame(coef(params[[i]]))
      values <- pivot_longer(cols = everything(), betas, names_to ="variable", values_to = "value")
      param_combined <- expand.grid(paste0("b", 0:(ncol(betas)-1)),  rownames(betas))
      par_list[[i]] <- data.frame(
        param = paste0(param_combined$Var1, "_", param_combined$Var2),
        value = values[,2]
      )
    }
  }
  names(par_list) <- paste0(col_nm, " | ", used_methods)
  
  return(par_list)
}


#' Read all the sheets in an xlsx workbook into a list of data frames
#' 
#' @param path the file path of the xslx workbook
#' @param ... arguments passed to `readxl::read_xlsx()`
#'
#' @return a list of data frames
synp_read_sheets <- function(path, ...) {
  # get the sheet names
  col_nm <- readxl::excel_sheets(path) 
  
  # read in the data from each sheet
  par_list <- lapply(col_nm, function(x) as.data.frame(readxl::read_excel(path, sheet = x, ...)))
  
  names(par_list) <- col_nm
  return(par_list)
}



#' Generate synthetic data from a parameter list
#' 
#' @param par_list the parameter list
#' @param n sample size (default = 1000)
#' 
#' @return a data frame
synp_gen_syndat_addpoly <- function(par_list, n = 1000) {
  # extract name of methods
  col_nm <- methods <- c()
  for (i in 1:length(par_list)){
    col_nm[i] <- stringr::str_trim(strsplit(names(par_list), split="\\|")[[i]][1])
    methods[i] <- stringr::str_trim(strsplit(names(par_list), split="\\|")[[i]][2])
  }
  # with the first variable, create a dataframe to store syndat
  cur_df <- par_list[[1]]
  if (methods[1] == "norm"){
    m <- cur_df[cur_df[,1] == "mean", 2]
    s <- cur_df[cur_df[,1] == "sd", 2]
    syndat <- data.frame(v1 = rnorm(n = n, mean = m, sd = s))
  }
  if (methods[1] =="logreg"){
    p <- as.numeric(cur_df[cur_df[,1] == "prob", 2]) # as.numeric() is necessary as they are stored as character (for logreg)
    syndat <- data.frame(v1 = as.factor(rbinom(n = n, size = 1, prob = p)))
    levels(syndat[,1]) <- c(cur_df[cur_df[,1] == "label(0)", 2], 
                            cur_df[cur_df[,1] == "label(1)", 2])
  }
  if (methods[1]=="polyreg"){
    ind_mat <- rmultinom(n=n, size=1, prob=cur_df$probability) 
    idx <- apply(ind_mat, 2, function(x) which(x==1))
    syndat <- data.frame(v1 = factor(cur_df$cat_label[idx], levels = cur_df$cat_label))
  }
  colnames(syndat) <- col_nm[1]

  # for the remaining variable, extract betas and previously synthesized data
  for (i in 2:length(par_list)) {
    cur_df <- par_list[[i]]
    
    # xp = design matrix 
    # previously synthesized data (=predictors for the current variable)
    xp <- model.matrix(as.formula(paste("~", paste(colnames(syndat), collapse ="+"))), data = syndat)
    betas <- as.matrix(as.numeric(cur_df[grepl("^b", cur_df[,1]), 2]))
    if (methods[i] == "norm"){
      m <- xp %*% betas 
      s <- cur_df[cur_df[,1] == "sd", 2]
      syndat[,col_nm[i]] <- rnorm(n = n, mean = m, sd = s)
    }
    if (methods[i] == "logreg"){
      scaleidx <- apply(xp, 2, function(x) length(unique(x)) > 2)
      xp[,scaleidx] <- scale(xp[,scaleidx], scale=FALSE) 
      p   <- 1/(1 + exp(-(xp %*% betas)))
      #syndat[, col_nm[i]] <- as.factor(runif(nrow(p)) <= p)
      syndat[,col_nm[i]] <- as.factor(rbinom(nrow(p), 1, p))
      
      levels(syndat[,i]) <- c(cur_df[cur_df[,1] == "label(0)", 2], 
                              cur_df[cur_df[,1] == "label(1)", 2])
    }
    if (methods[i] == "polyreg"){
      # first, re-scale them to [0,1] as synthpop did (not ideal as we don't have data "xf" which synthpop uses to scale)
      toscale <- apply(xp, 2, function(z) (is.numeric(z) & (any(z < 0) | any(z > 1))))
      rsc <- apply(xp[, toscale, drop = FALSE], 2, range)
      for (l in names(toscale[toscale == TRUE])) xp[, l] <- (xp[, l] - rsc[1,l])/(rsc[2,l] - rsc[1,l])
      
      # reformat the parameters
      separate_cols <- stringr::str_split(cur_df$param, pattern="_", simplify = TRUE)
      cur_df$param <- separate_cols[,1]
      cur_df$category <- separate_cols[,2]
      # exclude the first (name) column and convert it to matrix
      betas <- as.matrix(tidyr::pivot_wider(cur_df, names_from = category, values_from = value)[,-1])

      # compute probabilities for each category
      probs <- matrix(NA, nrow = n, ncol= ncol(betas)+1) # storage
      for (k in 1:ncol(betas)){
        probs[,k+1] <- exp(xp %*% as.matrix(betas[,k]))/(1 + rowSums(exp(xp %*% betas)))
      }
      probs[,1] <- 1 - rowSums(probs[,-1]) # reference category
      colnames(probs) <- c("ref", unique(cur_df$category))
      
      # add some noise
      un <- rep(runif(nrow(xp)), each = ncol(probs))
      draws <- un > apply(probs, 1, cumsum)
      idx   <- 1 + apply(draws, 2, sum)
      
      # create synthetic data
      syndat[,col_nm[i]] <- factor(colnames(probs)[idx] , levels=colnames(probs))
    }
    
  }
  return(syndat)
}





#################################################
## example case (polyreg is not the first var) ##
#################################################
library(tidyverse)

exampledata <- read.csv("Birthweight.csv")

# create catagorical variables
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

# run synthpop
synobj <- synthpop::syn(polydat, method=c("sample", "norm", "polyreg", "polyreg"), models = TRUE)

# get the parameters
res <- synp_get_param_addpoly(polydat, synobj)
# export to excel
writexl::write_xlsx(res, "try_addpoly.xlsx")

# read in the parameters
par <- synp_read_sheets("try_addpoly.xlsx")

# generate synthetic data 
syn_poly <- synp_gen_syndat_addpoly(par, n = nrow(polydat))

# check the result
summary(syn_poly); summary(polydat); summary(synobj$syn)


#############################################
## example case (polyreg is the first var) ##
#############################################

polydat2 <- polydat %>% 
  # reorder columns (so that polyreg is the first variable)
  relocate(mnocig) 

synobj2 <- synthpop::syn(polydat2, method=c("sample", "norm", "norm", "polyreg"), models = TRUE)


# get the parameters
res2 <- synp_get_param_addpoly(polydat2, synobj2)

# export to excel
writexl::write_xlsx(res2, "try_addpoly2.xlsx")

# read in the parameters
par2 <- synp_read_sheets("try_addpoly2.xlsx")

# generate synthetic data 
syn_poly2 <- synp_gen_syndat_addpoly(par2, n = nrow(polydat))

# check the result
summary(syn_poly2); summary(polydat2); summary(synobj2$syn)


