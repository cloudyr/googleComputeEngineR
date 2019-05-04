# 0.3.0

* Fixed broken passing of `zone` and `project` arguments in `gce_vm`, `gce_vm_template`, `gce_get_external_ip`, and `gce_set_metadata`.
* remove `gce_auth()` to favour auth with JSON key (#79)
* Fix project-id error if numbers in project (#72)
* Block users using "rstudio" as a login name
* Remove defunct example from `gce_schedule_docker`
* Support GPU images for Tensorflow, keras etc. (#101) via `gce_vm_gpu()` and `gce_vm(template = "rstudio-gpu")` (#101)
* Support common instance metadata by supply `gce_set_metadata(instance = "project-wide")`
* Support minCpuPlatform in instance creation and via  `gce_set_mincpuplatform()` (#112)
* Add ability to specify a startup-script in `gce_vm_container()`
* Switch RStudio templates to use startup-scripts and metadata
* Switch to applying a nginx proxy service to deal with port routing for templates
* Add `gce_startup_logs()` to track whts going on when launching an instance
* Vectorise `gce_vm_delete`, `gce_vm_stop`, `gce_vm_start` and `gce_vm_reset` functions so you can pass in a list of instances
* Add `gce_vm_cluster()` to make it easier to create clusters for `future`

# 0.2.0

## Changes

- Update website
- Bug fixes
- Add R-Datalab Dockerfile example
- Let Rstudio users be added with staff rights so they can install packages etc.
- Add ability to specify disk size when creating a VM (#38) - thanks @jburos
- Add firewall functions (#34)
- Add global operation class
- Add `open_webports` argument to `gce_vm` that will open web ports 80 and 443 if necessary
- Add GPU functions
- Migrate to use `system2` instead of `system` for cross-platform SSH (#35)
- `gce_shiny_addapp` is now much more useful
- Add `gce_schedule_docker` and `gce_vm_scheduler` for easy Dockerfile scheduling
- Add `gce_vm_logs` to quickly browse to an instance logs online
- Fix custom machine types creation (#63) - thanks @Blaza
- Set environment vars on VMs from metadata via `gce_metadata_env`

# 0.1.0

## Major changes

- Start, stop and restart VMs
- Create instances using cloudinit
- Browser based SSH
- SSH from R
- Metadata
- Docker
- Google container registry
- VM templates
- Future asynch cluster computing