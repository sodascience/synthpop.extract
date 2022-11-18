#' Extract parameter list from synds object
#'
#' @param df the original data frame
#' @param synds the fitted synds object
#'
#' @details
#' The synds object should be run with a parametric method and with the argument `models = TRUE`
#'
#' @return a list of data frames
#'
#' @seealso [synp_write_sheets()], [synp_read_sheets()], [synp_gen_syndat()]
#'
#' @import synthpop
#'
#' @examples
#'
#' # small example with big5 data
#' synds <- syn(big5, method="norm", models=TRUE)
#'
#' # get model parameters
#' model_par <- synp_get_param(big5, synds)
#'
#' # show model parameters
#' model_par
#'
#' @export
synp_get_param <- function(df, synds) {

  # disclosure control check
  if(nrow(df) < 10)
    stop("Disclosure control (as per CBS guideline #1): At least 10 observations are required.", call.=FALSE)

  # only parametric methods are allowed
  allowed_methods <- c("norm", "logreg", "polyreg", "polr")
  used_methods <- synds$method
  if (!all(used_methods[-1] %in% allowed_methods))
    stop("Extracting method should be parametric.", call.=FALSE)

  # some preliminary checks
  if (is.null(synds$models))
    stop("Run synthpop::syn() with argument `models = TRUE` to extract parameters", call.=FALSE)
  if(any(stringr::str_detect(colnames(df), "\\d")))
    stop("Numbers are not allowed in the variable names. Please consider converting them into alphabet characters", call.=FALSE)

  # extract synds model object
  params <- synds$models
  col_nm <- names(params)

  # create exportable storage format for parameters
  par_list <- list()

  # for the first variable,
  # extract probability per category when "logreg", "polyreg" or "polr"
  # extract mean and sd from the original data when "norm"
  first_var <- df[,1]
  # since synthpop by default uses "sample" method for the first variable
  # we manually check the variable type
  if(is.factor(first_var) && nlevels(first_var)==2){
    tt <- table(first_var)
    pt <- prop.table(tt)
    # disclosure control check
    if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[1]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
    # potential disclosure control for dominance rule
    # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[1] has a cell contains more than 90% of the total observations."), call.=FALSE)
    par_list[[1]] <- data.frame(
      param = c("prob", "label(0)", "label(1)"),
      value = c(pt[[2]], names(pt))
    )
    # change the used method to "logreg" instead of "sample"
    used_methods[1] <- "logreg"

  } else if (is.factor(first_var) && is.ordered(first_var) && nlevels(first_var) > 2) {
    tt <- table(first_var)
    pt <- prop.table(tt)
    # disclosure control check
    if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[1]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
    # potential disclosure control for dominance rule
    # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[1] has a cell contains more than 90% of the total observations."), call.=FALSE)
    par_list[[1]] <- as.data.frame(pt)
    colnames(par_list[[1]]) <- c("cat_label", "probability")
    # change the used method to "polr" instead of "sample"
    used_methods[1] <- "polr"

  } else if (is.factor(first_var) && nlevels(first_var) > 2){
    tt <- table(first_var)
    pt <- prop.table(tt)
    # disclosure control check
    if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[1]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
    # potential disclosure control for dominance rule
    # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[1] has a cell contains more than 90% of the total observations."), call.=FALSE)
    par_list[[1]] <- as.data.frame(pt)
    colnames(par_list[[1]]) <- c("cat_label", "probability")
    # change the used method to "polyreg" instead of "sample"
    used_methods[1] <- "polyreg"


  } else { # "norm" method
    if (length(unique(first_var)) <= (sqrt(nrow(df)) + 5))
      warning("First variable may be categorical. Please convert the categorical variable to a factor in order to implement `logreg`/`polyreg`.", call. = FALSE)
    par_list[[1]] <- data.frame(
      param = c("mean", "sd"),
      value = c(mean(df[[col_nm[1]]], na.rm = TRUE), sd(df[[col_nm[1]]], na.rm = TRUE))
    )
    # change the used method to "norm" instead of "sample"
    used_methods[1] <- "norm"
  }

  # for the remaining variables,
  # extract betas and sigma when "norm"
  # extract betas and level labels when "logreg"
  # extract betas per category when "polyreg"
  # extract betas and zetas for category boundaries when "polr"
  for (i in 2:length(params)) {

    if(used_methods[[i]]=="norm"){
      # disclosure control check
      # compute degrees of freedom
      dof <- nrow(df) - (length(params[[i]]$beta))
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."))

      # store parameters
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
      if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[i]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
      dof <- nrow(df)  - length(betas)
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."), call.=FALSE)
      # potential disclosure control for dominance rule
      # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[i] has a cell contains more than 90% of the total observations."), call.=FALSE)

      # store parameters
      par_list[[i]] <- data.frame(
        varname = c("intercept", rownames(params[[i]]$coefficients)[-1], "", ""),
        param = c(paste0("b", 0:(length(betas)-1)),  "label(0)", "label(1)"),
        value = c(betas, names(pt))
      )
    }

    if(used_methods[[i]]=="polyreg"){
      # extract betas
      betas <- as.data.frame(coef(params[[i]]))
      values <- tidyr::pivot_longer(cols = tidyselect::everything(), betas, names_to ="variable", values_to = "value")
      param_combined <- expand.grid(paste0("b", 0:(ncol(betas)-1)),  rownames(betas))
      # disclosure control check
      tt <- table(df[,i])
      pt <- prop.table(tt)
      if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[i]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
      dof <- nrow(df) - nrow(param_combined)
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."), call.=FALSE)
      # potential disclosure control for dominance rule
      # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[i] has a cell contains more than 90% of the total observations."), call.=FALSE)

      # store parameters
      par_list[[i]] <- data.frame(
        varname = params[[i]]$coefnames,
        param = paste0(param_combined$Var1, "_", param_combined$Var2),
        value = values[,2]
      )
    }

    if(used_methods[[i]]=="polr"){
      # extract zetas
      zetas <- as.data.frame(params[[i]]$zeta)
      # specify the column name
      colnames(zetas) <- "Zeta"
      parameters <- as.data.frame(coef(params[[i]]))
      # extract betas
      betas <- parameters[!rownames(parameters) %in% rownames(zetas), 1, drop=F]

      # disclosure control check
      tt <- table(df[,i])
      pt <- prop.table(tt)
      if (any(tt < 10)) stop(glue::glue("Disclosure control (as per CBS guideline #1): {col_nm[i]} should have minimum 10 observations per cell to proceed."), call.=FALSE)
      dof <- nrow(df) - nrow(parameters)
      if(dof < 10) stop(glue::glue("Disclosure control (as per CBS guideline #2): {col_nm[i]} should have minimum 10 degrees of freedom to proceed."), call.=FALSE)
      # potential disclosure control for dominance rule
      # if(max(pt) > .9) stop(glue::glue("Disclosure control: {col_nm[i] has a cell contains more than 90% of the total observations."), call.=FALSE)

      # store parameters
      par_list[[i]] <- data.frame(
        varname = c(paste("Zeta", rownames(zetas)), rownames(betas)),
        param = c(paste0("z","_", rownames(zetas)) , paste0("b", 1:nrow(betas))),
        value = c(zetas$Zeta, betas$Value)
      )
    }
  }

  names(par_list) <- paste0(col_nm, " | ", used_methods)

  return(par_list)
}
