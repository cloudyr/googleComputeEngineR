# googleComputeEngineR 0.2.0

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

# googleComputeEngineR 0.1.0

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