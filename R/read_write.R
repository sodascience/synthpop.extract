#' Read all the sheets in an xlsx workbook into a list of data frames
#'
#' @param path the file path of the xslx workbook
#' @param ... arguments passed to `readxl::read_xlsx()`
#'
#' @return a list of data frames
#' @export
synp_read_sheets <- function(path, ...) {
  # get the sheet names
  col_nm <- readxl::excel_sheets(path)

  # read in the data from each sheet
  par_list <- lapply(col_nm, function(x) as.data.frame(readxl::read_excel(path, sheet = x, ...)))

  names(par_list) <- col_nm
  return(par_list)
}


#' Write the parameter list to an excel file for exporting
#'
#' @param par_list the parameter list
#' @param path the file path of the xslx workbook
#'
#' @export
synp_write_sheets <- function(par_list, path) {
  writexl::write_xlsx(par_list, path)
  cat(glue::glue("Parameters written to file {path}!\n"))
}
