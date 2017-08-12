# Persistent RStudio on Google Compute Engine

By default the Docker container will not remember any files or changes if relaunched.

This Dockerfile installs tools on top of the defualt `rocker/tidyverse` to help.

## GitHub

Generally GitHub is the best place to keep code within projects.  `openssh-client` is installed so you can configure RStudio's Git client - the best sources for troubleshooting are:

* [Happy with Git](http://happygitwithr.com/)
* [This post on RBloggers](https://www.r-bloggers.com/rstudio-and-github/)

