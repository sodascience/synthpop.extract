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
