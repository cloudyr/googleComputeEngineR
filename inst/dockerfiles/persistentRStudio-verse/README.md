# Persistent RStudio on Google Compute Engine

This Dockerfile installs tools on top of the default `rocker/verse` to help persist files over Docker containers. 

There are three ways to save files between Docker sessions:

1. Write files to the host VM file system - this is through the -v flag upon Docker startup
2. Use Git to pull/push from Git repositories. 
3. Use `googleCloudStorageR` to save and read R working directories between machines

A combination of the above should be used for what best fits your workflow. 

## Using base VM

These files will dissappear if you delete the VM, so it is recommend if they are important to write them somewhere else as well using say the below two methods.

If relying on this, you will probably want to create a larger VM disk than the default 10GBs using the `disk_size_gb` argument:

```r
vm <- gce_vm("vm-larger-disk", 
             predefined_type = "n1-standard-1", 
             template = "rstudio", 
             username = "mark", password = "blah",
             disk_size_gb = 100)
```

## GitHub

Generally git is the best place for code under version control across many computers.  The below details how you can pull code to your Docker container each restart without needing to resupply your GitHub SSH keys.

See also these references:

* https://www.r-bloggers.com/rstudio-and-github/
* http://happygitwithr.com/ 

The below assumes you have started a VM using the `persistent-rstudio` image, which includes SSH tools:

```r
vm <- gce_vm("vm-ssh", 
             predefined_type = "n1-standard-1", 
             template = "rstudio", 
             username = "mark", password = "blah", 
             dynamic_image = "gcr.io/gcer-public/persistent-rstudio")
```

### First time you launch a VM:

1. Once the VM is launched, log in to RStudio Server at the IP provided by the script
2. Go to `Tools > Global Options > Git/SVN > Create RSA Key`
2. Click on "View public key"" then add it to GitHub here: https://github.com/settings/keys
3. Open the terminal in RStudio via `Tools > Shell...`, and configure you GitHub email and username:

```
git config --global user.email "your@githubemail.com"
git config --global user.name "GitHubUserName"
```
4. Check it works - you should see your GitHub details via `cat .gitconfig` and SSH keys in `ls .ssh`, `ssh -T git@github.com` should succeed. 

### A new GitHub project

Do the below for each new RStudio Project to download from GitHub:

1. On GitHub, click the `Clone or download` green button and copy the `Clone with SSH` URI. **Do not copy the browser URL! - it won't work**
2. Put the URI on RStudio Server via `New Project > Version Control > Git > Repository URL`
3. The first connect you may need to input "yes" in the scary dropdown
4. Make changes, push to GitHub via the RStudio Git pane

### Restarting the VM/Docker

This configuration should now persist across Docker sessions e.g. you can stop/start the VM and still have GitHub configured. 

1. Stop the RStudio server via the Web UI or `gce_vm_stop()`
2. Restart it via the Web UI or `gce_vm_start()`
3. Login to RStudio via the URL, then open terminal and check your older configurations are there via `cat .gitconfig` and SSH keys in `ls .ssh` and `ssh -T git@github.com` works

## Using googleCloudStorageR

This can be combined with the above GitHub settings to persist the GitHub settings over VMs.

The authentication for the `googleCloudStorageR` backups is re-using the credentials you used to launch the VM

It is not intended as a replacement for Git - it only adds files if they are not present locally.  I use it to copy projects over to more powerful VMs as required.

### On local computer

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

Choose a bucket region that is closest to you and your VM for best performance

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

### On cloud RStudio server

Now the R data is saved to GCS under the local folder name.  We can load this data in an RStudio server cloud instance via:

1. Launch the RStudio Server image `gcr.io/gcer-public/persistent-rstudio` that has appropriate libraries loaded.

```r
vm <- gce_vm("mark-rstudio",
             template = "rstudio",
             username = "mark", password = 'mypassword',
             predefined_type = "n1-standard-2",
             dynamic_image = "gcr.io/gcer-public/persistent-rstudio")

```
2. Add a `GCS_SESSION_BUCKET` metadata, either via webUI or via:

```r
gce_set_metadata(list(GCS_SESSION_BUCKET = "your-session-bucket"), vm)
```

3. Login to RStudio server and create an RStudio project
4. Transfer the local RStudio project to this cloud VM by creating a `_gcssave.yaml` file at the root of the project with these entries:

```yaml
bucket: your-gcs-bucket
loaddir: your-local-directory-name
```
5. Close and re-open the RStudio project.  Your local files should now load from GCS
6. Do work, then exit the project.  It will be saved to a new folder on GCS

### Persisting GitHub with googleCloudStorageR

You can also use the above in conjunction with the GitHub setup to persist over VMs.  

To do so, you need to :

1. Keep the same RStudio login username, 
2. Use the same bucket for `GCS_SESSION_BUCKET` or in the `_gcssave.yaml`
3. Use this Dockerfile's image - `gcr.io/gcer-public/persistent-rstudio`

The configurations of GitHub that are saved in `.ssh` and `.gitconfig` folders in your home directory will be backed up to Google Cloud Storage.  

#### Saving GitHub configurations

1. Add a `_gcssave.yaml` file to your home folder that will download/upload the configurations. 

```yaml
## The GCS bucket to save/load R workspace from
bucket: gcer-store-my-rstudio-files

## regex to only save these files to GCS
pattern: "id_rsa|.gitconfig"
```

2. With no project open and your working directory the base (e.g. `getwd()` is `/home/you`) save the yaml file and quit the R session:

```r
q(save = "no")
```

You should see a message saying its saving the home folder. Upon restart, that folder will load from the bucket. 

#### Loading GitHub configurations

1. Start another VM, with the same details as before:

```r
vm2 <- gce_vm("mark-rstudio",
             template = "rstudio",
             username = "mark", password = 'mypassword',
             predefined_type = "n1-standard-2",
             dynamic_image = "gcr.io/gcer-public/persistent-rstudio")

gce_set_metadata(list(GCS_SESSION_BUCKET = "your-session-bucket"), vm2)
```

2. Upon logging in, you should see a message saying its loading data from GCS:

```r
[Workspace loaded from: 
gs://your-session-bucket/home/you]
```

3. You should now be able to run `ssh -T git@github.com` successfully
4. Pull/push (private) GitHub repos via the steps outlined in the GitHub section above.

You can now delete VMs and start up new ones using RStudio Docker, and the GitHub configurations will persist so long as you follow the steps above. 

### Details on how the above is working

This build includes the newest version of `googleCloudStorageR` and `googleComputeEngineR` which have had functions added to help with the workflow above.

The functions can store data to Google's dedicated store via `googleCloudStorageR`s `gcs_first` and `gcs_last` functions.  This Dockerbuild puts the functions into a custom `.Rprofile` file that will save the projects workspace data to its own bucket, if they have a `_gcssave.yaml` file in the folder, or if the directory matches one already saved.  

The `.yaml` tells `googleCloudStorageR` which bucket to save the folder to, or if not present an environment argument `GCS_SESSION_BUCKET` - this is used on first load when no `.yaml` file is present. 

Thus, you can save an RStudio project via your local computer, then launch an RStudio server in the cloud with the `loaddir:` argument set to that directory name to load the files onto your cloud server.  Once done, when you quit the R session it will save your work to its own new folder, that when you stop/start a Docker container with RStudio within and create a project with the same name, will automatically load.

It will only download files to your folder that don't exist, so local changes won't be overwritten if they already exist.  It is not git, treat it more as a backup that will load if the files are not already present (such as when you relaunch a Docker container)

If you upload to GCS, make sure to load the directory and files you want - delete the GCS folder if you want to stop backups via `gcs_delete_all()`

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

To use, the VM needs to be supplied with a bucket name environment.  Using a seperate bucket means the same files can be transferred across Docker RStudio stop/starts and VMs.  This is set in the instance running the Docker's metadata, that will get copied over to an environment argument R can see.  

