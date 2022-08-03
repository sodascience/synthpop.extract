#' Extract parameter list from synds object
#' 
#' @param df the original data frame
#' @param synds the fitted synds object
#' 
#' @details 
#' The synds object should be run with a parametric method and with the argument `models = TRUE`
#' 
#' @return a list of data frames
get_par_list <- function(df, synds) {
  # check that only parametric methods were used
  allowed_methods <- c("norm") 
  # TODO: "logreg"
  # TODO: far future: "polyreg", "polyr")
  if (!all(synds$method[-1] %in% allowed_methods)) 
    stop("Extracting method should be parametric.")

  # extract parameters
  if (is.null(synds$models)) 
    stop("Run synthpop::syn() with argument `models = TRUE` to extract parameters")
  params <- synds$models
  col_nm <- names(params)
  
  # create exportable storage format for betas and sigma
  par_list <- list()
  
  # for the first variable, extract mean and sd from the original data
  first_var <- df[[col_nm[1]]]
  par_list[[1]] <- data.frame(
    param = c("mean", "sd"),
    value = c(mean(df[[col_nm[1]]], na.rm = TRUE), sd(df[[col_nm[1]]], na.rm = TRUE))
  )
  
  # for remaining variables, extract betas & sigma
  for (i in 2:length(params)) {
    par_list[[i]] <- data.frame(
      param = c(paste0("b", 0:(length(params[[i]]$beta)-1)), "sd"),
      value = c(params[[i]]$beta, params[[i]]$sigma)
    )
  }
  
  names(par_list) <- col_nm
  
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
gen_syn <- function(par_list, n = 1000) {
  col_nm <- names(par_list)
  
  cur_df <- par_list[[1]]
  m <- cur_df[cur_df[,1] == "mean", 2]
  s <- cur_df[cur_df[,1] == "sd", 2]
  
  syndat <- data.frame(v1 = rnorm(n = n, mean = m, sd = s))
  colnames(syndat) <- col_nm[1]
  
  for (i in 2:length(par_list)) {
    cur_df <- par_list[[i]]
    
    # storage for previously synthesized data (=predictors for the current variable)
    # xp = design matrix for variable i
    xp <- matrix(NA, nrow = n, ncol = i - 1) 
    for (j in 1:(i - 1)){
      xp[,j] <- syndat[[j]]
    }
    xp <- cbind(1, xp)
    betas <- as.matrix(cur_df[grepl("b", cur_df[,1]), 2])
    m <- xp %*% betas 
    s <- cur_df[cur_df[,1] == "sd", 2]
    
    syndat[[col_nm[i]]] <- rnorm(n = n, mean = m, sd = s)
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


