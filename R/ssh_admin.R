

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



# sets environment of the private ssh key and outputs the public key for use in SSH calls
set_ssh_keys <- function(key.pub = NULL, key.private = NULL) {
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
      
      if(!file.exists(g_private)){
        stop("Problem reading google_compute_engine key. Recreate ssh-keys and try again.")
      }
      
      myMessage("Using existing public key in ", 
                g_public, 
                level = 3)
      
      .gce_env$ssh_key <- g_private
      key.pub.content <- readChar(g_public, 10000)
      
    }
    
  }
  
  myMessage("Set private SSH key", level = 3)
  
  .gce_env$ssh_key_public <- key.pub.content
  key.pub.content
}



#' Setup a SSH connection with GCE from a new SSH key-pair
#' 
#' Uploads ssh-keys to an instance
#' 
#' @details 
#' 
#' This loads a public ssh-key to an instance's metadata.  It does not use the project SSH-Keys, that may be set seperatly.
#' 
#' You will need to generate a new SSH key-pair if you have not connected to an instance before. 
#' 
#' Instructions for this can be found here: \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}.  Once you have generated run this function once to initiate setup.
#' 
#' If you have historically connected via gcloud or some other means, ssh keys may have been generated automatically.  These will be looked for and used if found, at \code{file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")}
#' 
#' @param username The username you used to generate the key-pair
#' @param key.pub The filepath location of the public key, only needed first call per session
#' @param key.private The filepath location of the private key, only needed first call per session
#' @param instance Name of the instance of run ssh command upon
#' @param overwrite Will check if SSH settings already set and overwrite them if TRUE
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
gce_ssh_setup <- function(instance,
                          username = gce_get_global_ssh_user(),
                          key.pub = NULL,
                          key.private = NULL,
                          overwrite = FALSE,
                          project = gce_get_global_project(),
                          zone = gce_get_global_zone()){
  
  ins <- as.gce_instance(instance)
  
  if(!overwrite){
    if(check_ssh_set()){
      myMessage("Using existing local SSH settings.", level = 2)
      return(TRUE)
    } else {
      myMessage("Configuring SSH...", level = 3)
    }
  }
  
  key.pub.content <- set_ssh_keys(key.pub = key.pub, 
                                  key.private = key.private)
  
  ## set global ssh username
  sshuser <- gce_set_global_ssh_user(username)
  
  if(is.null(sshuser)){
    stop("Couldn't set SSH username")
  }
  
  ## get metadata
  ins_meta <- ins$metadata$items
  if(!is.null(ins_meta$key)){
    keys <- unlist(strsplit(ins_meta[ins_meta$key == "ssh-keys","value"], "\n"))
  } else {
    keys <- character(1)
  }
  
  ## make SSH Key metadata for upload to instance
  new_key <- paste0(sshuser, ":", key.pub.content, collapse = "")
  upload_me <- list(`ssh-keys` = paste(c(new_key, keys), collapse = "\n", sep =""))
  
  if(any(new_key %in% paste0(keys,"\n"))){
    
    myMessage("Public SSH key already in metadata of this instance", level = 3)
    
  } else {
    job <- gce_set_metadata(upload_me, 
                            instance = ins, 
                            project = project, 
                            zone = zone)
    gce_check_zone_op(job$name, verbose = FALSE) 
    myMessage("Public SSH key uploaded to instance", level = 3)
  }
  
  TRUE
  
}

#' Get the current SSH settings for an instance
#' 
#' @param instance An instance to check
#' 
#' @return A data.frame of SSH users and public keys
#' 
#' @export
gce_check_ssh <- function(instance){
  
  instance <- gce_get_instance(instance)
  
  metadata <- instance$metadata$items
  
  ssh_keys <- metadata[metadata$key == "ssh-keys","value"]
  
  keys <- vapply(strsplit(ssh_keys, ":"), function(x) c(x[[1]], x[[2]]), character(2))
  
  myMessage("Local SSH settings are ", check_ssh_set())
  myMessage("Current local settings: ", gce_get_global_ssh_user(), ", 
            private key: ", gce_global_ssh_private(), ",
            public key: ", gce_global_ssh_public())
  myMessage("Returning SSH keys on instance: ")
  
  data.frame(username = keys[1,], public.key = keys[2,], stringsAsFactors = FALSE)
  
}


## Get the saved private ssh key
gce_global_ssh_private <- function(){
  
  if(!exists("ssh_key", envir = .gce_env)){
    myMessage("SSH keys not set globally, run gce_ssh_setup() to set it.", level = 3)
    return(NULL)
  }
  .gce_env$ssh_key
}

## Get the saved ssh user
gce_get_global_ssh_user <- function(){
  
  if(!exists("user", envir = .gce_env)){
    myMessage("SSH username not set globally, run gce_ssh_setup() to set it.", level = 3)
    return(NULL)
  }
  
  .gce_env$user
  
}

## Get public key
gce_global_ssh_public <- function(){
  
  if(!exists("ssh_key_public", envir = .gce_env)){
    myMessage("SSH keys not set globally, run gce_ssh_setup() to set it.", level = 3)
    return(NULL)
  }
  
  .gce_env$ssh_key_public
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

check_ssh_set <- function(){
  
  if(all(
    !is.null(gce_get_global_ssh_user()),
    !is.null(gce_global_ssh_public()),
    !is.null(gce_global_ssh_private()))){
    return(TRUE)
  }
  
  FALSE
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
