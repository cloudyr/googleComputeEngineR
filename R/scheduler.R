#' Schedule running a docker image upon a VM
#' 
#' Utility function to start a VM to run a docker container on a schedule.  
#' You will need to create and build the Dockerfile first.
#' 
#' @param docker_image the hosted docker image to run on a schedule
#' @param vm A VM object to schedule the script upon that you can SSH into
#' @param schedule The schedule you want to run via cron
#' 
#' @details 
#' 
#' You may need to run \link{gce_vm_scheduler} yourself first and then set 
#'   up SSH details if not defaults, to pass to argument \code{vm}
#' 
#' You can create a Dockerfile with your R script installed by 
#'   running it through \code{containeRit::dockerfile}.  It also takes care of any dependencies.
#'   
#' It is recommended to create a script that is self contained in output and input, 
#' e.g. don't save files to the VM, instead upload or download any files 
#' from Google Cloud Storage via authentication via \code{googleAuthR::gar_gce_auth()} 
#' then downloading and uploading data using \code{library(googleCloudStorageR)} or similar. 
#' 
#' Once the script is working locally, build it and upload to a repository 
#'   so it can be reached via argument \code{docker_image}
#' 
#' You can build via Google cloud repository build triggers, 
#'   in which case the name can be created via \link{gce_tag_container}
#' or build via \link{docker_build} to build on another VM or locally, 
#' then push to a registry via \link{gce_push_registry}
#'   
#' Any Docker image can be run, it does not have to be an R one. 
#' 
#' @examples 
#' 
#' \dontrun{
#' # create a Dockerfile of your script
#' if(!require(containeRit)){
#'   remotes::install_github("o2r-project/containerit")
#'   library(containeRit)
#' }
#' 
#' 
#' ## create your scheduled script, example below named schedule.R
#' ## it will run the script whilst making the dockerfile
#' container <- dockerfile("schedule.R",
#'                         copy = "script_dir",
#'                         cmd = CMD_Rscript("schedule.R"),
#'                         soft = TRUE)
#' write(container, file = "Dockerfile")
#' 
#' ## upload created Dockerfile to GitHub, 
#'   then use a Build Trigger to create Docker image "demoDockerScheduler"
#' ## built trigger uses "demo-docker-scheduler" as must be lowercase
#' 
#' ## After image is built:
#' ## Create a VM to run the schedule
#' vm <- gce_vm_scheduler("my_scheduler")
#' 
#' ## setup any SSH not on defaults
#' vm <- gce_vm_setup(vm, username = "mark")
#' 
#' ## get the name of the just built Docker image that runs your script
#' docker_tag <- gce_tag_container("demo-docker-scheduler", project = "gcer-public")
#' 
#' ## Schedule the docker_tag to run every day at 0453AM
#' gce_schedule_docker(docker_tag, schedule = "53 4 * * *", vm = vm)
#' 
#' 
#' }
#' 
#' @return The crontab schedule of the VM including your script
#' @family scheduler functions
#' @export
gce_schedule_docker <- function(docker_image, 
                                schedule = "53 4 * * *", 
                                vm = gce_vm_scheduler()){
  
  assertthat::assert_that(
    assertthat::is.string(docker_image)
  )
  
  ## upload cron tab that will call a script that runs docker of the image specified
  docker_call <- sprintf("sudo /usr/bin/docker run %s", docker_image)
  
  ## copy cron over
  #http://www.unix.com/unix-for-dummies-questions-and-answers/105785-build-crontab-text-file.html
  cron_copy <- "export backup_date=`date +20%y%m%d-%H%M%S` && \
  mkdir -p backup && sudo chmod 777 -R backup && \
  sudo service docker start && \
  crontab -l > backup/crontab.${backup_date} && \
  crontab -l > backup/crontab.out"
  gce_ssh(vm, cron_copy, wait = TRUE)
  tmp <- tempfile()
  on.exit(unlink(tmp))
  
  tryCatch({
    gce_ssh_download(vm, "backup/crontab.out", tmp)
  }, error = function(ex) {
    myMessage("No existing crontab to download")
    add_line(paste("# empty line", Sys.time()), tmp)
  })
             
  add_line(paste(schedule, docker_call), tmp)
  readLines(tmp)
  gce_ssh_upload(vm, tmp, "backup/crontab.out")
  new_cron <- "crontab backup/crontab.out && crontab -l"
  # '(crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -'
  gce_ssh(vm, new_cron, wait = TRUE)
  
}

#' Create or start a scheduler VM
#' 
#' This starts up a VM with cron and docker installed that can be used to schedule scripts
#' 
#' @param vm_name The name of the VM scheduler to create or return
#' @inheritDotParams gce_vm
#' 
#' @return A VM object
#' @family scheduler functions
#' @export
gce_vm_scheduler <- function(vm_name = "scheduler", ...){
  assertthat::assert_that(
    assertthat::is.string(vm_name)
  )
  
  dots <- list(...)
  if(is.null(dots$image_project)) dots$image_project <- "debian-cloud"
  if(is.null(dots$image_family)) dots$image_family <- "debian-9"
  
  dots$name <- vm_name
  
  if(is.null(dots$metadata)){
    startup_file <- system.file("startupscripts", "installdocker.sh", package = "googleComputeEngineR")
    dots$metadata <- list("startup-script" = readChar(startup_file,
                                                      nchars = file.info(startup_file)$size))
  }
  
  vm <- do.call(gce_vm, args = dots)
  myMessage("On first boot, wait for docker to be installed before using", level = 3)
  
  vm
}