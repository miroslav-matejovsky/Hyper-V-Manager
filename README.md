# Hyper-V Machines

PowerShell module that supports easier management of Hyper-V machines, especially create by Packer

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
$ExecutionContext.SessionState.LanguageMode

Import-Module Hyper-V-Machine -Force -Verbose

Remove-Module Hyper-V-Machine -Force -ErrorAction SilentlyContinue
$env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","Machine")
Invoke-HyperVMachine help
```
