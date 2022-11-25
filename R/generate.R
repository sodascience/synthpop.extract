#' Generate synthetic data from a parameter list
#'
#' @param par_list the parameter list
#' @param n sample size (default = 1000)
#'
#' @return a data frame
#'
#' @importFrom stats as.formula coef model.matrix rbinom rmultinom rnorm runif sd
#' @importFrom utils globalVariables
#' @importFrom tidyselect where
#' @export
synp_gen_syndat <- function(par_list, n = 1000) {
  # extract name of used methods
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
    # store them as a fator
    syndat <- data.frame(v1 = as.factor(rbinom(n = n, size = 1, prob = p)))
    levels(syndat[,1]) <- c(cur_df[cur_df[,1] == "label(0)", 2],
                            cur_df[cur_df[,1] == "label(1)", 2])
  }
  if (methods[1]=="polyreg"){
    ind_mat <- rmultinom(n=n, size=1, prob=cur_df$probability)
    idx <- apply(ind_mat, 2, function(x) which(x==1))
    # store them as a factor
    syndat <- data.frame(v1 = factor(cur_df$cat_label[idx], levels = cur_df$cat_label))
  }
  if (methods[1]=="polr"){
    ind_mat <- rmultinom(n=n, size=1, prob=cur_df$probability)
    idx <- apply(ind_mat, 2, function(x) which(x==1))
    # store them as ordered factor
    syndat <- data.frame(v1 = ordered(cur_df$cat_label[idx], levels = cur_df$cat_label))
  }
  colnames(syndat) <- col_nm[1]

  # for the remaining variable,
  # build a model using the parameters and
  # generate synthetic data using previously synthesized data
  for (i in 2:length(par_list)) {
    cur_df <- par_list[[i]]

    # xp = design matrix
    # previously synthesized data (=predictors for the current variable)
    xp <- model.matrix(as.formula(paste("~", paste(colnames(syndat), collapse ="+"))), data = syndat)
    betas <- as.matrix(as.numeric(cur_df[grepl("^b", cur_df[,2]), 3]))

    if (methods[i] == "norm"){
      m <- xp %*% betas
      s <- cur_df[cur_df[,2] == "sd", 3]
      # create synthetic data
      syndat[,col_nm[i]] <- rnorm(n = n, mean = m, sd = s)
    }

    if (methods[i] == "logreg"){
      scaleidx <- apply(xp, 2, function(x) length(unique(x)) > 2)
      xp[,scaleidx] <- scale(xp[,scaleidx], scale=FALSE)
      p   <- 1/(1 + exp(-(xp %*% betas)))
      # create synthetic data (factor)
      #syndat[, col_nm[i]] <- as.factor(runif(nrow(p)) <= p)
      syndat[,col_nm[i]] <- as.factor(rbinom(nrow(p), 1, p))

      levels(syndat[,i]) <- c(cur_df[cur_df[,2] == "label(0)", 3],
                              cur_df[cur_df[,2] == "label(1)", 3])
    }

    if (methods[i] == "polyreg"){
      # first, re-scale them to [0,1] as synthpop did
      # (despite being not ideal as we don't have augmented data "xf", which synthpop uses to scale)
      toscale <- apply(xp, 2, function(z) (is.numeric(z) & (any(z < 0) | any(z > 1))))
      rsc <- apply(xp[, toscale, drop = FALSE], 2, range)
      for (l in names(toscale[toscale == TRUE])) xp[, l] <- (xp[, l] - rsc[1,l])/(rsc[2,l] - rsc[1,l])

      # reformat the parameters
      separate_cols <- stringr::str_split(cur_df$param, pattern="_", simplify = TRUE)
      cur_df$param <- separate_cols[,1]
      cur_df$category <- separate_cols[,2]
      # exclude the varname & param columns and convert it to matrix
      betas <- as.matrix(tidyr::pivot_wider(cur_df, names_from = "category", values_from = "value")[,-c(1,2)])
      # compute probabilities for each category
      probs <- matrix(NA, nrow = n, ncol= ncol(betas)+1) # storage for probabilities
      for (k in 1:ncol(betas)){
        probs[,k+1] <- exp(xp %*% as.matrix(betas[,k]))/(1 + rowSums(exp(xp %*% betas)))
      }
      probs[,1] <- 1 - rowSums(probs[,-1]) # reference category
      colnames(probs) <- c("ref", unique(cur_df$category))

      # get the indices for categories
      un <- rep(runif(nrow(xp)), each = ncol(probs))
      draws <- un > apply(probs, 1, cumsum)
      idx   <- 1 + apply(draws, 2, sum)

      # create synthetic data (factor)
      syndat[,col_nm[i]] <- factor(colnames(probs)[idx] , levels=colnames(probs))
    }

    if (methods[i] == "polr"){
      # extract zetas
      zetas <- cur_df[stringr::str_detect(cur_df[,2], "^z_"), 3]
      # extract betas
      betas <- cur_df[stringr::str_detect(cur_df[,2], "^b"), 3]
      # linear predictor
      linearpred <- xp[,-1] %*% as.matrix(betas) # exclude intercept
      # compute logits for each zeta (cut-offs)
      logits <- matrix(NA, nrow = n, ncol = length(zetas)) # storage for logits
      for(m in 1:length(zetas)){
        logits[,m] <- zetas[m] - linearpred
      }
      odds <- exp(logits)
      # transform logit back to prob (cumulative)
      prob <- odds / (1 + odds)

      # get the indices for categories
      un <- matrix(rep(runif(nrow(xp)), each = ncol(prob)), ncol = ncol(prob), byrow = T)
      draws <- un > prob
      idx   <- 1 + rowSums(draws)

      # extract the category names
      categories <- cur_df[stringr::str_detect(cur_df[,2], "^z_"), 2]
      regex_cat_names <- "((?<=^z\\_).+(?=\\|))|((?<=\\|).+$)"
      cat_names_dup <- stringr::str_extract_all(categories, regex_cat_names)
      cat_names <- unique(unlist(cat_names_dup))

      # create synthetic data (ordered factor)
      syndat[,col_nm[i]] <- ordered(cat_names[idx], levels = cat_names)
    }

    # As synthpop models spit out the betas in such an order that factor variables come after the numerical variables... this seems to happen in `numtocat.syn` in the main `syn` function.
    if (all(c("factor", "numeric") %in% sapply(syndat, class))) { # in case there are only either factor or numeric variables, `relocate` throws an error
      utils::globalVariables("where")
      syndat <- dplyr::relocate(syndat, tidyselect::where(is.factor), .after = tidyselect::where(is.numeric))
    }
  }
  return(syndat[,col_nm]) # rearrange the columns as the original order
}

