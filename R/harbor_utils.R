# Return a string of random letters and numbers, with an optional prefix.
random_name <- function(prefix = NULL, length = 6) {
  chars <- c(letters, 0:9)
  rand_str <- paste(sample(chars, length), collapse = "")
  paste(c(prefix, rand_str), collapse = "_")
}

# Given a string, indent every line by some number of spaces.
# The exception is to not add spaces after a trailing \n.
indent <- function(str, indent = 0) {
  gsub("(^|\\n)(?!$)",
    paste0("\\1", paste(rep(" ", indent), collapse = "")),
    str,
    perl = TRUE
  )
}

pluck <- function(x, name, type) {
  if (missing(type)) {
    lapply(x, "[[", name)
  } else {
    vapply(x, "[[", name, FUN.VALUE = type)
  }
}
