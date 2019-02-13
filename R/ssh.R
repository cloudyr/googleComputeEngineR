#' Open a cloud SSH browser for an instance
#' 
#' This will open an SSH from the browser session if \code{getOption("browser")} is not NULL
#' 
#' You will need to login the first time with an email that has access to the instance.
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/ssh-in-browser}
#' 
#' @param instance the instance resource
#' 
#' @return Opens a browser window to the SSH session, returns the SSH URL.
#' @importFrom utils browseURL
#' @export
#' @family ssh functions
gce_ssh_browser <- function(instance){
  
  instance <- as.gce_instance(instance)
  pz <- gce_extract_projectzone(instance)
  
  ssh_url <- sprintf("https://ssh.cloud.google.com/projects/%s/zones/%s/instances/%s?projectNumber=%s",
                     pz$project, pz$zone, as.gce_instance_name(instance), pz$project)
  
  if(!is.null(getOption("browser"))){
    utils::browseURL(ssh_url)
  }

  ssh_url
  
}

#' Remotely execute ssh code, upload & download files.
#' 
#' @description 
#' Assumes that you have ssh & scp installed.  If on Windows see website and examples for workarounds. 
#' 
#' @details 
#' 
#' Only works connecting to linux based instances.
#' 
#' On Windows you will need to install an ssh command line client - see examples for an example using RStudio's built in client. 
#' 
#' You will need to generate a new SSH key-pair if you have not connected to the instance before via say the gcloud SDK.
#' 
#' To customise SSH connection see \link{gce_ssh_setup}
#' 
#' \code{capture_text} is passed to \code{stdout} and \code{stderr} of \link{system2} 
#' 
#' Otherwise, instructions for generating SSH keys can be found here: \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}.
#'
#' Uploads and downloads are recursive, so if you specify a directory,
#' everything inside the directory will also be downloaded.
#' 
#' @inheritParams gce_ssh_setup
#' @param ... Shell commands to run. Multiple commands are combined with
#'   \code{&&} so that execution will halt after the first failure.
#' @param local,remote Local and remote paths.
#' @param overwrite If TRUE, will overwrite the local file if exists.
#' @param verbose If TRUE, will print command before executing it.
#' @param wait Whether then SSH output should be waited for or run it asynchronously.
#' @param capture_text Possible values are "", to the R console (the default), NULL or FALSE (discard output), TRUE (capture the output in a character vector) or a character string naming a file.
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}
#' 
#' @examples 
#' 
#' \dontrun{
#'   
#'   
#'   vm <- gce_vm("my-instance")
#'   
#'   ## if you have already logged in via gcloud, the default keys will be used
#'   ## no need to run gce_ssh_addkeys
#'   ## run command on instance            
#'   gce_ssh(vm, "echo foo")
#'   #> foo
#'   
#'   ## if running on Windows, use the RStudio default SSH client
#'   ## e.g. add C:\Program Files\RStudio\bin\msys-ssh-1000-18 to your PATH
#'   ## then run: 
#'   vm2 <- gce_vm("my-instance2")
#' 
#'   ## add SSH info to the VM object
#'   ## custom info
#'   vm2 <- gce_ssh_setup(vm2,
#'                       username = "mark", 
#'                       key.pub = "C://.ssh/id_rsa.pub",
#'                       key.private = "C://.ssh/id_rsa")
#'                       
#'   ## run command on instance            
#'   gce_ssh(vm2, "echo foo")
#'   #> foo
#' 
#' 
#' }
#' 
#' @export
#' @family ssh functions
gce_ssh <- function(instance, 
                    ..., 
                    key.pub = NULL,
                    key.private = NULL,
                    wait = TRUE,
                    capture_text = "",
                    username = Sys.info()[["user"]]) {
  
  stopifnot(is.gce_instance(instance))
  
  instance <- gce_ssh_setup(instance = instance, 
                            username = username,
                            key.pub = key.pub,
                            key.private = key.private)
  
  username <- instance$ssh$username
  
  lines <- paste(c(...), collapse = " \\\n&& ")
  if (lines == "") stop("Provide commands", call. = FALSE)
    
  sargs <- c(
    ssh_options(instance),
    paste0(username, "@", gce_get_external_ip(instance, verbose = FALSE)),
    shQuote(lines)
  )
    
  do_system(instance, cmd = "ssh", sargs = sargs, wait = wait, capture = capture_text)
  
}

#' @export
#' @rdname gce_ssh
gce_ssh_upload <- function(instance,
                           local, 
                           remote, 
                           username = Sys.info()[["user"]], 
                           key.pub = NULL,
                           key.private = NULL,
                           verbose = FALSE,
                           wait = TRUE) {

  stopifnot(is.gce_instance(instance))
  
  instance <- gce_ssh_setup(instance = instance, 
                            username = username,
                            key.pub = key.pub,
                            key.private = key.private)
  
  username <- instance$ssh$username
  
  sargs <- c(
    "-r ", ssh_options(instance),
    local,
    paste0(username, "@", gce_get_external_ip(instance, verbose = FALSE), ":", remote))

  do_system(instance, cmd = "scp", sargs = sargs, wait = wait)
}

#' @export
#' @rdname gce_ssh
gce_ssh_download <- function(instance,
                             remote, 
                             local, 
                             username = Sys.info()[["user"]], 
                             key.pub = NULL,
                             key.private = NULL,
                             verbose = FALSE, 
                             overwrite = FALSE,
                             wait = TRUE) {

  stopifnot(is.gce_instance(instance))
  
  instance <- gce_ssh_setup(instance = instance, 
                            username = username,
                            key.pub = key.pub,
                            key.private = key.private)
  
  username <- instance$ssh$username
  
  sargs <- c(
    "-r ", ssh_options(instance),
    paste0(username, "@", gce_get_external_ip(instance, verbose = FALSE), ":", remote),
    local)
  
  do_system(instance, cmd = "scp", sargs = sargs, wait = wait)
}


do_system <- function(instance, 
                      cmd = "ssh",
                      sargs = character(),
                      wait = TRUE,
                      capture = ""
                      ) {
  
  stopifnot(is.gce_instance(instance))
  
  ## check ssh/scp installed
  cli_tools()
  
  external_ip <- gce_get_external_ip(instance, verbose = FALSE)
  # check to make sure port 22 open, otherwise ssh commands will fail
  if (!is_port_open(external_ip, 22)) {
    stop("port 22 is not open for ", external_ip, call. = FALSE)
  }
  
  ## do the command
  myMessage(cmd, " ", paste(sargs, collapse = " "), level = 2)
  

  status <- system2(cmd, args = sargs, wait = wait, stdout = capture, stderr = capture)


  
  if(capture == TRUE){
    ## return the command text to local R
    
    ## maybe a warning available in attr(status, "status) or attr(status, "errmsg)
    if(!is.null(attr(status, "status"))){
      myMessage("Remote error: ", 
                attr(status, "status"), attr(status, "errmsg"), level = 3)
    }

    ## status is the output text
    ## parse out the connection warning
    host_warn <- status[grepl("^Warning: Permanently added .* to the list of known hosts", status)]
    myMessage(host_warn, level = 3)
    status <- status[!grepl("^Warning: Permanently added .* to the list of known hosts", status)]
    out <- status
    
  } else {
    ## status if error code (0 for success)
    if (status == 127) {
      stop("ssh failed\n", cmd, paste(sargs, collapse = " "), call. = FALSE)
    }
    
    ## output may be written to file if capture = "filepath"
    if(is.character(capture) && file.exists(capture)){
      myMessage("Wrote output to ", capture, level = 2)
    }
    
    myMessage("status: ", status, " wait: ", wait, level = 2)
    out <-   invisible(TRUE)
  }
    

  out

}