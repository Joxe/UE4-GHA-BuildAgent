# UE4 build agent for GitHub Actions

This repo makes it easy to create VM images for the build agents that power your UE4 game's build system.

The following configuration is supported:

- VM provider: GCE
- VM OS: Win64, Ubuntu Linux (untested)
- VCS for game project: Git
- Build system: GitHub Actions
- Compiler toolchain: Visual Studio 2019 Build Tools

# How to use
### Windows

`packer build -var project_id=<your GCE project ID> -var zone=<zone which the builder VM should be run in> -var image_name=<name> UE4-GCE-Win64-Git-GitHubActions-MSVC.json` -- this will build a VM image and store it within the chosen GCE project.

### Linux

**Linux is currently untested on Google Cloud!**

`packer build -var project_id=<your GCE project ID> -var zone=<zone which the builder VM should be run in> -var image_name=<name> UE4-GCE-Linux-Git-GitHubActions.json` -- this will build a VM image and store it within the chosen GCE project.

Later on, you can create VM instances from the image. You can give them additional disk, up to 2TB.

Example:
```
gcloud compute instances create build-agent-1 --image=my-build-agent-image --boot-disk-type=pd-ssd --boot-disk-size=200GB --metadata=github-scope=falldamagestudio/UE4-GHA-Game,github-pat=<redacted>,runner-name=build-agent-1
```

The VM will automatically connect to the GitHub Actions org/repo at startup, and will be ready to process build jobs.
