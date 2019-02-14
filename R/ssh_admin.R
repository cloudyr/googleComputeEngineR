

ssh_options <- function(instance) {
  opts <- c(
    BatchMode = "yes",
    StrictHostKeyChecking = "no",
    UserKnownHostsFile = paste0("'",file.path(tempdir(), "hosts"),"'")
  )
  
  if(exists("ssh", instance)){
    private_key <- instance$ssh$key.private
  }

  if(!file.exists(private_key)) stop("Couldn't find private key")
  
  c(paste0("-o ", names(opts), "=", opts, collapse = " "), 
    " -i ", 
    paste0("'",private_key,"'"))
}

#' Add SSH details to a gce_instance
#' 
#' 
#' @param instance The gce_instance
#' @param username SSH username to login with
#' @param key.pub filepath to public SSH key
#' @param key.private filepath to the private SSK key
#' @param overwrite Overwrite existing SSH details if they exist
#' 
#' @details 
#' 
#' You will only need to run this yourself if you save your SSH keys somewhere other 
#'   than \code{$HOME/.ssh/google_compute_engine.pub} or use a different username than 
#'   your local username as found in \code{Sys.info[["user"]]}, otherwise it will configure 
#'   itself automatically the first time you use \link{gce_ssh} in an R session.
#' 
#' If key.pub is NULL then will look for default Google credentials at 
#'   \code{file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")}
#'   
#' @return The instance with SSH details included in $ssh
#' 
#' @examples 
#' 
#' \dontrun{
#'   
#'   library(googleComputeEngineR)
#'   
#'   vm <- gce_vm("my-instance")
#'   
#'   ## if you have already logged in via gcloud, the default keys will be used
#'   ## no need to run gce_ssh_addkeys
#'   ## run command on instance            
#'   gce_ssh(vm, "echo foo")
#'   
#'   
#'   ## if running on Windows, use the RStudio default SSH client
#'   ## e.g. add C:\Program Files\RStudio\bin\msys-ssh-1000-18 to your PATH
#'   ## then run: 
#'   vm2 <- gce_vm("my-instance2")
#' 
#'   ## add SSH info to the VM object
#'   ## custom info
#'   vm <- gce_ssh_setup(vm,
#'                       username = "mark", 
#'                       key.pub = "C://.ssh/id_rsa.pub",
#'                       key.private = "C://.ssh/id_rsa")
#'                       
#'   ## run command on instance            
#'   gce_ssh(vm, "echo foo")
#'   #> foo
#' 
#'   ## example to check logs of rstudio docker container
#'   gce_ssh(vm, "sudo journalctl -u rstudio")
#' 
#' }
#' @family ssh functions
#' @export
gce_ssh_addkeys <- function(instance,
                            key.pub = NULL,
                            key.private = NULL,
                            username = Sys.info()[["user"]],
                            overwrite = FALSE){
  
  stopifnot(is.gce_instance(instance))
  
  if(exists("ssh", instance)){
    if(!overwrite){
      myMessage("SSH keys already set", level = 1)
      return(instance)
    } else {
      myMessage("Overwriting SSH keys data on local instance object", level = 3)
    }
  }
  
  if(!is.null(key.pub) & !is.null(key.private)){
    myMessage("Using ssh-key files given as ", 
              key.pub," / ", key.private, 
              level = 3)
    
    stopifnot(file.exists(key.pub))
    stopifnot(file.exists(key.private))
    
    key.private <- normalizePath(key.private)
    key.pub.content  <- readChar(key.pub, 10000)
  } else {
    ## Check to see if they have been set already
    g_public  <- file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")
    
    if(file.exists(g_public)){
      ## you already have the key
      g_private <- file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine")
      
      if(!file.exists(g_private)){
        stop("Problem reading google_compute_engine key. Recreate ssh-keys and try again.",
             .call = FALSE)
      }
      
      myMessage("Using existing public key in ", 
                g_public, 
                level = 1)
      
      key.private <- g_private
      key.pub.content <- readChar(g_public, 10000)
      
    } else {
      stop("No SSH public/private key given and no google_compute_engine.pub not found.", 
           .call = FALSE)
    }
    
  }
  
  instance$ssh <- list(
    username = username,
    key.pub = key.pub.content,
    key.private = key.private
  )
  
  instance
  
}

#' Setup a SSH connection with GCE from a new SSH key-pair
#' 
#' Uploads ssh-keys to an instance
#' 
#' @details 
#' 
#' This loads a public ssh-key to an instance's metadata.  It does not use the project SSH-Keys, that may be set separately.
#' 
#' You will need to generate a new SSH key-pair if you have not connected to an instance before. 
#' 
#' Instructions for this can be found here: \url{https://cloud.google.com/compute/docs/instances/connecting-to-instance}.  Once you have generated run this function once to initiate setup.
#' 
#' If you have historically connected via gcloud or some other means, ssh keys may have been generated automatically.  
#' 
#' These will be looked for and used if found, at \code{file.path(Sys.getenv("HOME"), ".ssh", "google_compute_engine.pub")}
#' 
#' @param username The username you used to generate the key-pair
#' @param key.pub The filepath location of the public key
#' @param key.private The filepath location of the private key
#' @param instance Name of the instance of run ssh command upon
#' @param ssh_overwrite Will check if SSH settings already set and overwrite them if TRUE
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys}
#' 
#' @return TRUE if successful
#' @examples 
#' 
#' \dontrun{
#'   
#'   library(googleComputeEngineR)
#'   
#'   vm <- gce_vm("my-instance")
#'   
#'   ## if you have already logged in via gcloud, the default keys will be used
#'   ## no need to run gce_ssh_addkeys
#'   ## run command on instance            
#'   gce_ssh(vm, "echo foo")
#'   
#'   
#'   ## if running on Windows, use the RStudio default SSH client
#'   ## e.g. add C:\Program Files\RStudio\bin\msys-ssh-1000-18 to your PATH
#'   ## then run: 
#'   vm2 <- gce_vm("my-instance2")
#' 
#'   ## add SSH info to the VM object
#'   ## custom info
#'   vm <- gce_ssh_setup(vm,
#'                       username = "mark", 
#'                       key.pub = "C://.ssh/id_rsa.pub",
#'                       key.private = "C://.ssh/id_rsa")
#'                       
#'   ## run command on instance            
#'   gce_ssh(vm, "echo foo")
#'   #> foo
#' 
#'   ## example to check logs of rstudio docker container
#'   gce_ssh(vm, "sudo journalctl -u rstudio")
#' 
#' }
#' @export
#' @family ssh functions
gce_ssh_setup <- function(instance,
                          key.pub = NULL,
                          key.private = NULL,
                          ssh_overwrite = FALSE,
                          username = Sys.info()[["user"]]){
  
  stopifnot(is.gce_instance(instance))
  pz <- gce_extract_projectzone(instance)
  project <- pz$project
  zone <- pz$zone
  
  ins <- gce_ssh_addkeys(instance,
                         key.pub = key.pub,
                         key.private = key.private,
                         username = username,
                         overwrite = ssh_overwrite)
  
  ## get fresh metadata just in case things have changed
  cloud_keys <- gce_check_ssh(instance)
  
  if(ins$ssh$username %in% cloud_keys$username){
    myMessage("Username SSH key already exists", level = 1)
  } else {
    ## make SSH Key metadata for upload to instance.
    new_key <- paste0(ins$ssh$username, ":", ins$ssh$key.pub, collapse = "")
    if(!is.null(cloud_keys)){
      upload_me <- list(`ssh-keys` = paste(c(new_key, cloud_keys), collapse = "\n", sep =""))
    } else {
      upload_me <- list(`ssh-keys` = new_key)
    }

    job <- gce_set_metadata(upload_me, 
                            instance = ins, 
                            project = project, 
                            zone = zone)
    gce_wait(job, verbose = FALSE) 
    myMessage("Public SSH key uploaded to instance", level = 3)
  }
  
  ins
  
}

#' Calls API for the current SSH settings for an instance
#' 
#' @param instance An instance to check
#' 
#' @return A data.frame of SSH users and public keys
#' 
#' @export
gce_check_ssh <- function(instance){
  stopifnot(is.gce_instance(instance))
  pz <- gce_extract_projectzone(instance)
  
  instance <- gce_get_instance(instance, project = pz$project, zone = pz$zone)
  
  ssh_keys <- gce_get_metadata(instance, "ssh-keys")$value
  
  if(!is.null(ssh_keys)){
    keys <- vapply(strsplit(ssh_keys, ":"), function(x) c(x[[1]], x[[2]]), character(2))    
    out <-   data.frame(username = keys[1,], public.key = keys[2,], stringsAsFactors = FALSE)
  } else {
    out <- NULL
  }
  
  myMessage("Current local settings: ", instance$ssh$username, ", 
            private key: ", instance$ssh$key.private, ",
            public key: ", instance$ssh$key.pub, level = 1)
  myMessage("Returning SSH keys on instance", level = 2)
  
  out
}

check_ssh_set <- function(instance){

  if(exists("ssh",instance)){
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
cli_tools <- function(){
  tmp <- Sys.which(c("ssh","scp"))
  if (any(tmp == "")) {
    nf <- paste0(names(tmp)[tmp == ""], collapse = ", ")
    if(.Platform$OS.type == "windows"){
      stop(sprintf("\n%s not found on your computer\nInstall the missing tool(s) and try again. See ?gce_ssh for workarounds, including using the RStudio native SSH client.", nf))
    } else {
      stop(sprintf("\n%s not found on your computer\nInstall the missing tool(s) and try again", nf))
    }

  }
}
