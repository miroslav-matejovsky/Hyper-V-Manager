# Hyper-V Manager

PowerShell module that supports easier management of Hyper-V machines, especially create by Packer

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
$ExecutionContext.SessionState.LanguageMode

Import-Module Hyper-V-Manager -Force -Verbose
Update-Help -Force

Remove-Module Hyper-V-Manager -Force -ErrorAction SilentlyContinue
$env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","Machine")
Invoke-HyperVManager help
```
