## script to push public versions of build Dockerfiles
## to Google project gcer-public 
## as per https://cloud.google.com/container-registry/docs/access-control

## using gsutil CLI
gsutil defacl ch -u AllUsers:R gs://artifacts.gcer-public.appspot.com

gsutil acl ch -r -u -m AllUsers:R gs://artifacts.gcer-public.appspot.com

gsutil acl ch -u AllUsers:R gs://artifacts.gcer-public.appspot.com

