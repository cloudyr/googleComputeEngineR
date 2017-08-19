# Persistent RStudio on Google Compute Engine

By default the Docker container will not remember any files or changes if relaunched.

This Dockerfile installs tools on top of the default `rocker/tidyverse` to help.

## GitHub

Generally GitHub is the best place to keep code within projects.  

### Installation

`git` and `openssh-client` are installed so you can configure RStudio's Git client - the best sources for troubleshooting are:

* [Happy with Git](http://happygitwithr.com/)
* [This post on RBloggers](https://www.r-bloggers.com/rstudio-and-github/)

The key sticking point looks to be you have to push to GitHub using the command line first, and to make sure you add these lines:

```
git remote add origin https://github.com/your-github-user/github-repo.git
git config remote.origin.url git@github.com:your-github-user/github-repo.git
```

After one successful shell pull and push, you should then be able to use the RStudio Git UI without putting in your username and password.  You will unfortunetly need to repeat this after each stop/start of RStudio though, unless you save the container to your own private repo via `googleComputeEngineR::gce_push_repository` (todo - copy local github ssh keys to an instance?)

You can then use GitHub via private and public repos to keep your code and data safe.  When RStudio is launched, pull in your project, work on it, then push up again.  You can then stop the RStudio instance without losing your code.

You don't have to use GitHub - Google also offers Git repos that are private within the project - [Cloud Source Repositories](https://cloud.google.com/source-repositories/).  Set the remote to those as detailed [here](https://cloud.google.com/source-repositories/docs/adding-repositories-as-remotes).

## Google Cloud Storage

However, using Git is not quite the same as running your own RStudio on your own laptop - you need to set up a Git repo for each project and that is a cost if you want to keep them private.

For a way of using RStudio more like when using it locally, this build also includes `googleCloudStorageR` which can store data to Google's dedicated store via its `gcs_first` and `gcs_last` functions.  This is automatically put into an `.Rprofile` file that will save the projects workspace data to its own bucket, if they have a `_gcssave.yaml` file in the folder.  This `.yaml` tells `googleCloudStorageR` which bucket to save the folder to.

The bucket to save to is also set in an environment argument `GCS_SESSION_BUCKET` - this is used on first load. 

Thus, you can save an RStudio project via your local computer, then launch an RStudio server in the cloud with the `loaddir:` argument set to that directory name to load the files onto your cloud server.  Once done, when you quit the R session it will save your work to its own new folder, that when you stop/start a Docker container with RStudio within and create a project with the same name, will automatically load.

It will only download files to your folder that don't exist, so local changes won't be overwritten if they already exist. 

If you upload to GCS, make sure you only load the versions you want - delete the GCS folder if you want to stop backups via `gcs_delete_all()`

Example `_gcssave.yaml`:

```yaml
## The GCS bucket to save/load R workspace from
bucket: gcer-store-my-rstudio-files

## set to FALSE if you dont want to load on R session startup
load_on_startup: TRUE

## on first load and init, whether to look for a different directory on GCS than present getwd()
loaddir: /Users/mark/the/folder/on/local

## regex to only save these files to GCS
pattern:
```

An advantage on using R on a GCE instance is that you can reuse the authentication used to launch the VM for other cloud services, via `googleAuthR::gar_gce_auth()` so you don't need to supply your own auth file.

To use, the VM needs to be supplied with a bucket name environment.  Using a seperate bucket means the same files can be transferred across Docker RStudio stop/starts and VMs.  This can be set in the instance metadata, that will get copied over to an environment argument R can see.  

# Workflow steps

## On local computer

1. Create Google Cloud Bucket to save your R sessions to - you can do this via the web UI or similar to below:

```r
library(googleCloudStorageR)

## make the bucket to save to
projectId = "your-project"
bucket_name <- paste("gcer", projectId, Sys.Date(), sep ="-")
bs <- gcs_list_buckets(projectId)

if(bucket_name %in% bs$name){
  message("Bucket found")
  b <- bucket_name
} else {
  b <- gcs_create_bucket(bucket_name, 
                         projectId, 
                         location = "europe-west2", 
                         storageClass = "REGIONAL")
}
gcs_global_bucket(b)
```
2. Add that bucket to your `.Renviron` as the `GCS_SESSION_BUCKET` argument:
```
GCS_SESSION_BUCKET=gcer-bucket-name
```
3. Add `gcs_first` and `gcs_last` to your `.RProfile` file. 
4. Create RStudio Project
5. Make R stuff
6. Add a `_gcssave.yaml` file specifying GCS bucket to save to.
7. Exit RStudio project.  You should see a message similar to: 
```r
Saving data to Google Cloud Storage:
your-gcs-bucket
2017-08-18 23:25:43 -- File size detected as 1.3 Mb
```

When you startup that project again you should see:
```r
[Workspace loaded from: 
gs://your-gcs-bucket/Users/the-rproject-folder]
```

## On cloud RStudio server

Now the R data is saved to GCS under the local folder name.  We can load this data in an RStudio server cloud instance via:

1. Launch the RStudio Server image `gcr.io/gcer-public/persistent-rstudio` that has appropriate libraries loaded.

```r
vm <- gce_vm("mark-rstudio",
             template = "rstudio",
             username = "mark", password = 'mypassword',
             predefined_type = "n1-standard-2",
             dynamic_image = "gcr.io/gcer-public/persistent-rstudio")
```

2. Add metadata to the VM specifying the session bucket to load: either in the web UI or via:

```r
gce_set_metadata(vm, list(GCS_SESSION_BUCKET = "your-bucket"))
```
3. Login to RStudio server and create an RStudio project
4. Transfer the local RStudio project to this cloud VM by creating a `_gcssave.yaml` file at the root of the project with these entries:

```yaml
bucket: your-gcs-bucket
loaddir: your-local-directory-name
```
4. Close and re-open the RStudio project.  Your local files should now load from GCS
5. Do work, then exit the project.  It will be saved to a new folder on GCS
6. Shutdown the VM to avoid charges.
7. Restart the VM and repeat step 3, creating an RStudio project with the exact same name as before.  
8. The files from GCS should now automatically load as you are using same bucket (via VM metadata) and filepath (via RStudio Project name)


