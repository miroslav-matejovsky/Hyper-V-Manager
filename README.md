# Hyper-V Manager

PowerShell module that supports easier management of [Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/hyper-v-overview?pivots=windows) machines,
especially virtual machines created by [Packer](https://www.packer.io/)

## Installation

Clone this repository to your powershell module path, e.g.: `C:\Users\username\Documents\WindowsPowerShell\Modules\Hyper-V-Manager`
or `$env:PSModulePath` or `$PROFILE/../Modules`. Then run `Import-Module Hyper-V-Manager -Force`.

## Building images with Packer

### Create base images

In `packer` directory you can find `windows_server_2022-base.pkr.hcl` file. This file is used to create base image for Hyper-V.
You can run it with `packer build  windows_server_2022-base.pkr.hcl`  or `packer build -var 'type=code' windows_server_2022-base.pkr.hcl` command.
Base image should not be imported to Hyper-V Manager, it is used as a base for other images.

### Create example images

In `packer` directory you can find `example-core.pkr.hcl` and `example-desktop.pkr.hcl` files. These files are used to create example images for Hyper-V.
You can run it with `packer build  example-core.pkr.hcl`  or `packer build example-desktop.pkr.hcl` command.

## Import and start output images with Hyper-V Manager

After creating images with Packer, you can import them to Hyper-V Manager with `Invoke-HyperVManager` function.

```pwsh
Invoke-HyperVManager start output-hvm_example_core
Invoke-HyperVManager start output-hvm_example_desktop
```

## Force import during development

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
$ExecutionContext.SessionState.LanguageMode

Import-Module Hyper-V-Manager -Force -Verbose
Update-Help -Force

Remove-Module Hyper-V-Manager -Force -ErrorAction SilentlyContinue
$env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","Machine")
Invoke-HyperVManager help
```
