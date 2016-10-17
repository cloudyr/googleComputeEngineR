#' Open a cloud SSH browser for an instance
#' 
#' This will open an SSH from the browser session if \code{getOption("browser")} is not NULL
#' 
#' You will need to login the first time with an email that has access to the instance.
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/ssh-in-browser}
#' 
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @return Opens a browser window to the SSH session, returns the SSH URL.
#' @importFrom utils browseURL
#' @export
#' @family ssh functions
gce_ssh_browser <- function(instance,
                            project = gce_get_global_project(), 
                            zone = gce_get_global_zone()){
  
  instance <- as.gce_instance_name(instance)
  
  ssh_url <- sprintf("https://ssh.cloud.google.com/projects/%s/zones/%s/instances/%s?projectNumber=%s",
                     project, zone, instance, project)
  
  if(!is.null(getOption("browser"))){
    utils::browseURL(ssh_url)
  }

  ssh_url
  
}


#' Setup a SSH connection with GCE from a new SSH key-pair
#' 
#' Uploads ssh-keys to an instance
#' 
#' @details 
#' 
#' This loads a public ssh-key to an instance's metadata.  It does not use the project SSH-Keys, that may be set seperatly.
#' 
#' You will need to generate a new SSH key-pair if you have not connected to the instance before. 
#' 
#' Instructions for this can be found here: \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}.  Once you have generated run this function once to initiate setup.
#' 
#' If you have historically connected via gcloud or some other means, ssh keys may have been generated automatically.  These will be looked for and used if found, at \code{file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")}
#' 
#' @param user The username you used to generate the key-pair
#' @param key.pub The filepath location of the public key, only needed first call per session
#' @param key.private The filepath location of the private key, only needed first call per session
#' @param instance Name of the instance of run ssh command upon
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys}
#' 
#' @return TRUE if successful
#' 

#' 
#' @export
#' @family ssh functions
gce_ssh_setup <- function(user,
                          instance,
                          key.pub = NULL,
                          key.private = NULL,
                          project = gce_get_global_project(),
                          zone = gce_get_global_zone()){
  
  instance <- as.gce_instance_name(instance)
  
  if(!is.null(key.pub) & !is.null(key.private)){
    myMessage("Using ssh-key files given as ", 
              key.pub," / ", key.private, 
              level = 3)
    
    stopifnot(file.exists(key.pub))
    stopifnot(file.exists(key.private))
    
    .gce_env$ssh_key <- normalizePath(key.private)
    key.pub.content  <- readChar(key.pub, 10000)
  } else {
    ## Check to see if they have been set already
    g_public  <- file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")
    
    if(file.exists(g_public)){
      ## you already have the key
      g_private <- file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine")
      
      myMessage("Using existing key in ", 
                g_public, 
                level = 3)
      
      if(file.exists(g_private)){
        .gce_env$ssh_key <- g_private
      } else {
        stop("Problem reading google_compute_engine key. Recreate ssh-keys and try again.")
      }
      
      key.pub.content <- readChar(g_public, 10000)
      
      }
    
  }
  
  myMessage("Set private SSH key", level = 3)
  
  ## set global ssh username
  gce_set_global_ssh_user(user)
  
  ## get existing metadata
  ins <- gce_get_instance(instance, project = project, zone = zone)
  ins_meta <- ins$metadata$items
  if(!is.null(ins_meta$key)){
    keys <- unlist(strsplit(ins_meta[ins_meta$key == "ssh-keys","value"], "\n"))
  } else {
    keys <- character(1)
  }

  
  new_key <- paste0(user, ":ssh-rsa ", key.pub.content, collapse = "")
  
  if(any(new_key %in% paste0(keys,"\n"))){
    
    myMessage("Public SSH key already in metadata of this instance", level = 3)
    
  } else {
    job <- gce_set_metadata(list(`ssh-keys` = paste(c(new_key, keys), collapse = "\n", sep ="")), 
                            instance = instance, 
                            project = project, 
                            zone = zone)
    gce_check_zone_op(job$name, verbose = FALSE) 
    myMessage("Public SSH key upload to instance", level = 3)
  }
  

  TRUE
  
}

## Get the saved private ssh key
gce_global_ssh_private <- function(){
  .gce_env$ssh_key
}

## Get the saved ssh user
gce_get_global_ssh_user <- function(){

  if(!exists("user", envir = .gce_env)){
    myMessage("SSH username not set globally, run gce_ssh_setup() to set it.")
    return(NULL)
  }
  
  .gce_env$user
  
}

## Set the global SSH username
gce_set_global_ssh_user <- function(username = NULL){
  
  if(is.null(username)){
    user_env <- Sys.getenv("GCE_SSH_USER")
    if(user_env == "") {
      return(NULL)
    } else {
      username <- user_env
    }
  }
  
  myMessage("Set SSH Username to ", username, level = 3)
  .gce_env$user <- username
  .gce_env$user
}

#' Remotely execute ssh code, upload & download files.
#'
#' Assumes that you have ssh & scp installed.  
#' 
#' Only works connecting to linux based instances.
#' 
#' On Windows you will need to install an ssh command line client.
#' 
#' You will need to generate a new SSH key-pair if you have not connected to the instance before.
#' 
#' Otherwise, instructions for this can be found here: \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}.  
#' 
#' When you have generated it run \link{gce_ssh_setup} once to initiate setup.
#'
#' Uploads and downloads are recursive, so if you specify a directory,
#' everything inside the directory will also be downloaded.
#' 
#' @inheritParams gce_ssh_setup
#' @param instance Name of the instance of run ssh command upon
#' @param ... Shell commands to run. Multiple commands are combined with
#'   \code{&&} so that execution will halt after the first failure.
#' @param username User name used to generate ssh-keys. Usually your login to your local workstation or Google account alias.
#' @param local,remote Local and remote paths.
#' @param overwrite If TRUE, will overwrite the local file if exists.
#' @param verbose If TRUE, will print command before executing it.
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @param wait Whether then SSH output should be waited for or run it asynchronously.
#' @param capture_text whether to return the output of the SSH command into an R text
#' 
#' @author Scott Chamberlin \email{myrmecocystus@@gmail.com}
#' @seealso \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}
#' @return If capture_text is TRUE, the text of the SSH command result.
#' 
#' 
#' @examples 
#' 
#' \dontrun{
#' 
#'   gce_ssh("rbase", "sudo journalctl -u rbase", user = "mark")
#' 
#' }
#' 
#' @export
#' @family ssh functions
gce_ssh <- function(instance, 
                    ..., 
                    username = gce_get_global_ssh_user(), 
                    key.pub = NULL,
                    key.private = NULL,
                    wait = TRUE,
                    capture_text = FALSE,
                    project = gce_get_global_project(),
                    zone = gce_get_global_zone()) {
  
  instance <- as.gce_instance_name(instance)
  
  if(is.null(gce_global_ssh_private()) | is.null(gce_get_global_ssh_user())){
    myMessage("Setting up ssh keys...")

    gce_ssh_setup(username, instance = instance, project = project, zone = zone,
                  key.pub = key.pub,
                  key.private = key.private)
  }
  
  if(is.null(gce_get_global_ssh_user())) stop("Must set username")
  
  username <- gce_get_global_ssh_user()
  
  lines <- paste(c(...), collapse = " \\\n&& ")
  if (lines == "") stop("Provide commands", call. = FALSE)

  if(capture_text) {
    # Assume that the remote host uses /tmp as the temp dir
    temp_remote <- tempfile("gcer_cmd", tmpdir = "/tmp")
    temp_local <- tempfile("gcer_cmd")
    on.exit(unlink(temp_local))
    
    cmd <- paste0(
      "ssh ", ssh_options(),
      " ", username, "@", gce_get_external_ip(instance, project = project, zone = zone, verbose = FALSE),
      " ", shQuote(paste(lines, ">", temp_remote))
    )
    
    do_system(instance, cmd, wait = wait, project = project, zone = zone)
    gce_ssh_download(instance, temp_remote, temp_local, project = project, zone = zone)

    text <- readLines(temp_local, warn = FALSE)
    out <- text
    
  } else {
    
    cmd <- paste0(
      "ssh ", ssh_options(),
      " ", username, "@", gce_get_external_ip(instance, project = project, zone = zone, verbose = FALSE),
      " ", shQuote(lines)
    )
    
    out <- do_system(instance, cmd, wait = wait, project = project, zone = zone)
    
  }
  
  out
}

ssh_options <- function() {
  opts <- c(
    BatchMode = "yes",
    StrictHostKeyChecking = "no",
    UserKnownHostsFile = file.path(tempdir(), "hosts")
  )
  private_key <- gce_global_ssh_private()
  
  if(!file.exists(private_key)) stop("Couldn't find private key")
  
  paste0(paste0("-o ", names(opts), "=", opts, collapse = " "), 
         " -i ", 
         private_key)
}


#' @export
#' @rdname gce_ssh
gce_ssh_upload <- function(instance,
                           local, 
                           remote, 
                           user = gce_get_global_ssh_user(), 
                           key.pub = NULL,
                           key.private = NULL,
                           verbose = FALSE,
                           wait = TRUE,
                           project = gce_get_global_project(), 
                           zone = gce_get_global_zone()) {

  instance <- as.gce_instance_name(instance)
  
  if(is.null(gce_global_ssh_private()) | is.null(gce_get_global_ssh_user())){
    myMessage("Setting up ssh keys...")
    gce_ssh_setup(user, instance = instance, project = project, zone = zone,
                  key.pub = key.pub,
                  key.private = key.private)
  }
  
  if(is.null(gce_get_global_ssh_user())) stop("Must set username")
  
  cmd <- paste0(
    "scp -r ", ssh_options(),
    " ", local,
    " ", user, "@", gce_get_external_ip(instance, project = project, zone = zone, verbose = FALSE), ":", remote
  )

  do_system(instance, cmd, wait = wait, project = project, zone = zone)
}

#' @export
#' @rdname gce_ssh
gce_ssh_download <- function(instance,
                             remote, 
                             local, 
                             user = gce_get_global_ssh_user(),
                             key.pub = NULL,
                             key.private = NULL,
                             verbose = FALSE, 
                             overwrite = FALSE,
                             wait = TRUE,
                             project = gce_get_global_project(), 
                             zone = gce_get_global_zone()) {

  instance <- as.gce_instance_name(instance)
  
  if(is.null(gce_global_ssh_private()) | is.null(gce_get_global_ssh_user())){
    myMessage("Setting up ssh keys...")
    gce_ssh_setup(user, instance = instance, project = project, zone = zone,
                  key.pub = key.pub,
                  key.private = key.private)
  }
  
  if(is.null(gce_get_global_ssh_user())) stop("Must set username")
  
  local <- normalizePath(local, mustWork = FALSE)

  if (file.exists(local) && file.info(local)$isdir) {
    # If `local` exists and is a dir, then just put the result in that directory
    local_dir <- local
    need_rename <- FALSE

  } else {
    # If `local` isn't an existing directory, put the result in the parent
    local_dir <- dirname(local)
    need_rename <- TRUE
  }

  # A temp dir for the downloaded file(s)
  local_tempdir <- tempfile("download", local_dir)
  local_tempfile <- file.path(local_tempdir, basename(remote))

  if (need_rename) {
    # Rename to local name
    dest <- file.path(local_dir, basename(local))
  } else {
    # Keep original name
    dest <- file.path(local_dir, basename(remote))
  }

  if (file.exists(dest) && !overwrite) {
    stop("Destination file already exists.")
  }

  dir.create(local_tempdir)

  # Rename the downloaded files when we exit
  on.exit({
    if (file.exists(dest)) unlink(dest, recursive = TRUE)
    file.rename(local_tempfile, dest)
    unlink(local_tempdir, recursive = TRUE)
  })

  external_ip <- gce_get_external_ip(instance, project = project, zone = zone, verbose = FALSE)
  # This ssh's to the remote machine, tars the file(s), and sends it to the
  # local host where it is untarred.
  cmd <- paste0(
    "ssh ", ssh_options(),
    " ", user, "@", external_ip, " ",
    sprintf("'cd %s && tar cz %s'", dirname(remote), basename(remote)),
    " | ",
    sprintf("(cd %s && tar xz)", local_tempdir)
  )

  do_system(instance, cmd, wait = wait, project = project, zone = zone)
}


do_system <- function(instance, 
                      cmd, 
                      wait = TRUE,
                      project = gce_get_global_project(), 
                      zone = gce_get_global_zone()
                      ) {
  
  instance <- as.gce_instance_name(instance)
  
  cli_tools()
  external_ip <- gce_get_external_ip(instance, project = project, zone = zone, verbose = FALSE)
  # check to make sure port 22 open, otherwise ssh commands will fail
  if (!is_port_open(external_ip, 22)) {
    stop("port 22 is not open for ", external_ip, call. = FALSE)
  }
  myMessage(cmd, level = 2)
  status <- system(cmd, wait = wait)
  if (status != 0) {
    stop("ssh failed\n", cmd, call. = FALSE)
  }

  invisible(TRUE)
}

#' Test to see if a TCP port is open
#' 
#' Taken via https://github.com/sckott/analogsea/blob/e728772013ad286750e0e89dc261a36fa31d4647/R/is_port_open.R
#'
#' @param host ip or host name to connect to
#' @param port port to connect to
#' @param timeout how many secs to let it try
#' @noRd
#' @author Bob Rudis \email{bob@@rudis.net}
#' @examples \dontrun{
#' is_port_open("httpbin.org", 80)
#' is_port_open("httpbin.org", 22)
#' }
is_port_open <- function(host, port=22, timeout=1) {
  
  WARN <- getOption("warn")
  options(warn = -1)
  
  con <- try(socketConnection(host, port, blocking = TRUE, timeout = timeout),
             silent = TRUE)
  
  if (!inherits(con, "try-error")) {
    close(con)
    options(warn = WARN)
    TRUE
  } else {
    options(warn = WARN)
    FALSE
  }
  
}

#' See if ssh or scp is installed
#' From https://github.com/sckott/analogsea/blob/master/R/zzz.R
#' @keywords internal
cli_tools <- function(ip){
  tmp <- Sys.which(c("ssh","scp"))
  if (any(tmp == "")) {
    nf <- paste0(names(tmp)[tmp == ""], collapse = ", ")
    stop(sprintf("\n%s not found on your computer\nInstall the missing tool(s) and try again", nf))
  }
}
