# Persistent RStudio on Google Compute Engine

By default the Docker container will not remember any files or changes if relaunched.

This Dockerfile installs tools on top of the defualt `rocker/tidyverse` to help.

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

For a way of using RStudio more like when using it locally, this build also includes `googleCloudStorageR` which can store data to Google's dedicated store via its `gcs_first` and `gcs_last` functions.  Putting these in a `.Rprofile` file will save the projects workspace data to its own bucket, if they have a `_gcssave.yaml` file in the folder.  This `.yaml` tells `googleCloudStorageR` which bucket to save the folder to.

The buckt to save to is also set in an environment argument `GCS_SESSION_BUCKET` - this is used on first load. 

You can save this via your local computer, then launch an RStudio server with the same `.Rprofile` settings to load the files again.  Create a similar named project/working directory, and set up a `_gcssave.yaml` with the `loaddir` field set to the name of the folder you uploaded (as it will have a different name to your own local folder.)

When you restart that folder or call `gcs_first` manually, the saved files should be downloaded to your instance.  When you quit, a copy will be uploaded with the same file path, and the next time you launch a project of that name it should download automatically.  It will only download files to your folder that don't exist, so local changes wonøt be overwritten. 

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







