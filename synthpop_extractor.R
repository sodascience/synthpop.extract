#' Extract parameter list from synds object  
#' 
#' @param df the original data frame
#' @param synds the fitted synds object
#' 
#' @details 
#' The synds object should be run with a parametric method and with the argument `models = TRUE`
#' 
#' @return a list of data frames
synp_get_param <- function(df, synds) {
  
  # disclosure control check
  if(nrow(df) < 10) 
    stop("Disclosure control (as per CBS guideline #1): At least 10 observations are required.", .call=FALSE)
  
  # check that only parametric methods were used
  allowed_methods <- c("norm", "logreg", "polyreg")  
  # TODO: far future: polyr"
  used_methods <- synds$method 
  if (!all(used_methods[-1] %in% allowed_methods)) 
    stop("Extracting method should be parametric.", .call=FALSE)
  
  # extract parameters
  if (is.null(synds$models)) 
    stop("Run synthpop::syn() with argument `models = TRUE` to extract parameters", .call=FALSE)
  if(any(stringr::str_detect(colnames(df), "\\d"))) 
    stop("Numbers are not allowed in the variable names. Please consider converting them into alphabet characters", .call=FALSE)
  params <- synds$models
  col_nm <- names(params)
  
  # create exportable storage format for parameters
  par_list <- list()
  
  # for the first variable, 
  # extract probability when "logreg"
  # extract probability per category when "polyreg
  # extract mean and sd from the original data when "norm"
  first_var <- df[,1]
  if(is.factor(first_var) && nlevels(first_var)==2){ # since synthpop by default uses "sample" method for the first variable
    tt <- table(first_var)
    pt <- prop.table(tt) 
    # disclosure control check
    if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[1]} should have minimum 10 observations per cell to proceed."), .call=FALSE)
    # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[1] has a cell contains more than 90% of the total observations."), .call=FALSE)
    par_list[[1]] <- data.frame(          
      param = c("prob", "label(0)", "label(1)"),               
      value = c(pt[[2]], names(pt)) 
    )
    used_methods[1] <- "logreg" # change the used method to "logreg" instead of "sample"
    
  } else if (is.factor(first_var) && nlevels(first_var) > 2){
    tt <- table(first_var)
    pt <- prop.table(tt) 
    # disclosure control check
    if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[1]} should have minimum 10 observations per cell to proceed."), .call=FALSE)
    # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[1] has a cell contains more than 90% of the total observations."), .call=FALSE)
    par_list[[1]] <- as.data.frame(pt)
    colnames(par_list[[1]]) <- c("cat_label", "probability")
    used_methods[1] <- "polyreg"
    
  } else { # "norm" method
    if (length(unique(first_var)) <= (sqrt(nrow(df)) + 5)) 
      warning("First variable may be categorical. Please convert dichotomous/categorical variables to a factor in order to implement `logreg`/`polyreg`.", .call=FALSE)
    par_list[[1]] <- data.frame(
      param = c("mean", "sd"),
      value = c(mean(df[[col_nm[1]]], na.rm = TRUE), sd(df[[col_nm[1]]], na.rm = TRUE))
    )
    used_methods[1] <- "norm"
  }
  
  # for remaining variables, 
  # extract betas and sigma when "norm" 
  # extract betas and level labels when "logreg"
  # extract betas per category when "polyreg"
  for (i in 2:length(params)) {
    
    if(used_methods[[i]]=="norm"){
      # disclosure control check
      dof <- nrow(df) - (length(params[[i]]$beta)) # number of betas 
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."))
      par_list[[i]] <- data.frame(
        varname = c("intercept", rownames(params[[i]]$beta)[-1], "sd"),
        param = c(paste0("b", 0:(length(params[[i]]$beta)-1)), "sd"),
        value = c(params[[i]]$beta, params[[i]]$sigma)
      )
    }
    
    if(used_methods[[i]]=="logreg"){
      betas <- unname(coef(params[[i]])[,1])
      # disclosure control check
      tt <- table(df[,i])
      pt <- prop.table(tt)
      if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[i]} should have minimum 10 observations per cell to proceed."), .call=FALSE)
      dof <- nrow(df)  - length(betas)
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."), .call=FALSE)
      # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[i] has a cell contains more than 90% of the total observations."), .call=FALSE)
      
      par_list[[i]] <- data.frame(
        varname = c("intercept", rownames(params[[i]]$coefficients)[-1], "", ""),
        param = c(paste0("b", 0:(length(betas)-1)),  "label(0)", "label(1)"),
        value = c(betas, names(pt))
      )
    }
    
    if(used_methods[[i]]=="polyreg"){
      betas <- as.data.frame(coef(params[[i]]))
      values <- tidyr::pivot_longer(cols = everything(), betas, names_to ="variable", values_to = "value")
      param_combined <- expand.grid(paste0("b", 0:(ncol(betas)-1)),  rownames(betas))
      # disclosure control check
      tt <- table(df[,i])
      pt <- prop.table(tt) 
      if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[i]} should have minimum 10 observations per cell to proceed."), .call=FALSE)
      dof <- nrow(df) - nrow(param_combined)
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."), .call=FALSE)
      # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[i] has a cell contains more than 90% of the total observations."), .call=FALSE)
      par_list[[i]] <- data.frame(
        varname = params[[i]]$coefnames,
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
synp_gen_syndat <- function(par_list, n = 1000) {
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
  
  # for the remaining variable, use the parameters and previously synthesized data
  for (i in 2:length(par_list)) {
    cur_df <- par_list[[i]]
    
    # xp = design matrix 
    # previously synthesized data (=predictors for the current variable)
    xp <- model.matrix(as.formula(paste("~", paste(colnames(syndat), collapse ="+"))), data = syndat)
    betas <- as.matrix(as.numeric(cur_df[grepl("^b", cur_df[,2]), 3]))
    if (methods[i] == "norm"){
      m <- xp %*% betas 
      s <- cur_df[cur_df[,2] == "sd", 3]
      syndat[,col_nm[i]] <- rnorm(n = n, mean = m, sd = s)
    }
    if (methods[i] == "logreg"){
      scaleidx <- apply(xp, 2, function(x) length(unique(x)) > 2)
      xp[,scaleidx] <- scale(xp[,scaleidx], scale=FALSE) 
      p   <- 1/(1 + exp(-(xp %*% betas)))
      #syndat[, col_nm[i]] <- as.factor(runif(nrow(p)) <= p)
      syndat[,col_nm[i]] <- as.factor(rbinom(nrow(p), 1, p))
      
      levels(syndat[,i]) <- c(cur_df[cur_df[,2] == "label(0)", 3], 
                              cur_df[cur_df[,2] == "label(1)", 3])
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
      # exclude the varname & param columns and convert it to matrix
      betas <- as.matrix(tidyr::pivot_wider(cur_df, names_from = category, values_from = value)[,-c(1,2)])
      # compute probabilities for each category
      probs <- matrix(NA, nrow = n, ncol= ncol(betas)+1) # storage
      for (k in 1:ncol(betas)){
        probs[,k+1] <- exp(xp %*% as.matrix(betas[,k]))/(1 + rowSums(exp(xp %*% betas)))
      }
      probs[,1] <- 1 - rowSums(probs[,-1]) # reference category
      colnames(probs) <- c("ref", unique(cur_df$category))
      
      # sample from multinomial posterior
      un <- rep(runif(nrow(xp)), each = ncol(probs))
      draws <- un > apply(probs, 1, cumsum)
      idx   <- 1 + apply(draws, 2, sum)
      
      # create synthetic data
      syndat[,col_nm[i]] <- factor(colnames(probs)[idx] , levels=colnames(probs))
    }
    
    # the synthpop models spit out the betas in such an order that factor variables are behind the numerical variables... this seems to happen in numtocat.syn in the main syn function (???)
    syndat <- dplyr::relocate(syndat, where(is.factor), .after = where(is.numeric))
    
  }
  return(syndat[,col_nm]) # rearrange the columns as the original order
}
