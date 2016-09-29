#' Metadata Object
#' 
#' 
#' @param items A named list of key = value pairs
#' 
#' @return Metadata object
#' 
#' @family Metadata functions
#' @keywords internal
Metadata <- function(items) {
  
  testthat::expect_named(items)
  
  key_values <- lapply(names(items), function(x) list(key = jsonlite::unbox(x), 
                                                      value = jsonlite::unbox(items[[x]])))
  
  structure(list(items = key_values), 
            class = c("list","gar_Metadata"))
}
