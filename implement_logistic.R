#' Extract parameter list from synds object
#' 
#' @param df the original data frame
#' @param synds the fitted synds object
#' 
#' @details 
#' The synds object should be run with a parametric method and with the argument `models = TRUE`
#' 
#' @return a list of data frames
get_par_addlog <- function(df, synds) {
  # check that only parametric methods were used
  allowed_methods <- c("norm", "logreg") # "logreg" added 
  # TODO: far future: "polyreg", "polyr")
  used_methods <- synds$method 
  if (!all(used_methods[-1] %in% allowed_methods)) 
    stop("Extracting method should be parametric.")
  
  # extract parameters
  if (is.null(synds$models)) 
    stop("Run synthpop::syn() with argument `models = TRUE` to extract parameters")
  if(any(str_detect(colnames(df), "\\d"))) 
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
  } else if (is.factor(first_var) && nlevels(first_var) >= 2){
    stop("`polyreg` is not implemented yet.")
  }  else if (!is.factor(first_var) && length(unique(first_var))==2){
    stop("Please convert the dicothomous variable to a factor in order to implement `logreg`.")
  }else{
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
read_sheets <- function(path, ...) {
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
gen_syn_addlog <- function(par_list, n = 1000) {
  # extract name of methods
  col_nm <- methods <- c()
  for (i in 1:length(par_list)){
    col_nm[i] <- str_trim(strsplit(names(par_list), split="\\|")[[i]][1])
    methods[i] <- str_trim(strsplit(names(par_list), split="\\|")[[i]][2])
  }
  # with the first variable, create a dataframe to store syndat
  cur_df <- par_list[[1]]
  if (methods[1] == "norm"){
    m <- cur_df[cur_df[,1] == "mean", 2]
    s <- cur_df[cur_df[,1] == "sd", 2]
    syndat <- data.frame(v1 = rnorm(n = n, mean = m, sd = s))
    colnames(syndat) <- col_nm[1]
  }
  if (methods[1] =="logreg"){
    p <- as.numeric(cur_df[cur_df[,1] == "prob", 2]) # as.numeric() is necessary as they are stored as character (for logreg)
    syndat <- data.frame(v1 = as.factor(rbinom(n = n, size = 1, prob = p)))
    levels(syndat[,1]) <- c(cur_df[cur_df[,1] == "label(0)", 2], 
                            cur_df[cur_df[,1] == "label(1)", 2])
    colnames(syndat) <- col_nm[1]
  }
  
  # for the remaining variable, extract betas and previously synthesized data
  for (i in 2:length(par_list)) {
    cur_df <- par_list[[i]]
    
    # storage for previously synthesized data (=predictors for the current variable)
    # xp = design matrix for variable i
    xp <- matrix(NA, nrow = n, ncol = (i - 1)) 
    for (j in 1:(i - 1)){
      xp[,j] <- syndat[,j]
    }
    xp <- cbind(1, xp)
    betas <- as.matrix(as.numeric(cur_df[grepl("^b", cur_df[,1]), 2]))
    if (methods[i] == "norm"){
      m <- xp %*% betas 
      s <- cur_df[cur_df[,1] == "sd", 2]
      syndat[,col_nm[i]] <- rnorm(n = n, mean = m, sd = s)
    }
    if (methods[i] =="logreg"){
      xp <- scale(xp, scale=FALSE)
      p   <- 1/(1 + exp(-(xp %*% betas)))
      # syndat[, col_nm[i]] <- as.factor(runif(nrow(p)) <= p)
      syndat[,col_nm[i]] <- as.factor(rbinom(nrow(p),1, p))
      levels(syndat[,1]) <- c(cur_df[cur_df[,1] == "label(0)", 2], 
                              cur_df[cur_df[,1] == "label(1)", 2])
    }
  }
  return(syndat)
}



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

