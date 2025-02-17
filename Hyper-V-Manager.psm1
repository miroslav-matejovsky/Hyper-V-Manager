#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

function Invoke-HyperVManager {
    <#
    .Synopsis
    A command-based CLI for managing Hyper-V virtual machines. 

    .Description
    USAGE:
        Invoke-HyperVManager -Command <command> -VmOutputFolder packer/output-<vm-name>
        Invoke-HyperVManager <command> packer/output-<vm-name>

    .LINK

    https://kevinareed.com/2021/04/14/creating-a-command-based-cli-in-powershell/

    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("import", "start", "stop", "remove", "delete", "session", "ip", "ssh", "list", "help")]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$VmOutputFolder
    )

    if (!$Command) {
        Write-Error "Command is required."
        Show-Help
        return
    }

    if ($Command -eq "help") {
        Show-Help
        return
    }

    if ($Command -eq "list") {
        # $runningVMs = Get-VM | Where-Object { $_.State -eq "Running" }
        $vms = Get-VM

        if ($vms) {
            $formatString = "{0,-20} | {1,-10} | {2,-20} | {3,-30}"
            Write-Host ($formatString -f "NAME", "STATE", "SWITCH", "IP ADDRESSES")
            foreach ($vm in $vms) {
                Write-Host ($formatString -f $vm.Name, $vm.State, ($vm.NetworkAdapters.SwitchName -join ","), ($vm.NetworkAdapters.IPAddresses -join ","))
            }
            # $vms | Select-Object Name, State, Status, @{Name="SwitchName"; Expression={ $_.NetworkAdapters.SwitchName}}, @{Name="IPAddresses"; Expression={ $_.NetworkAdapters.IPAddresses}} | 
            # Format-Table -Wrap -AutoSize
        }
        else {
            Write-Host "No Running Virtual Machines"
        }
        return
    }

    if (!$VmOutputFolder) {
        Write-Error "VM folder is required."
        Show-Help
        return
    }

    if (-Not (Test-Path -Path $VmOutputFolder -PathType Container)) {
        Write-Error "The specified output VM folder does not exist: $VmOutputFolder"
        return
    }
    $outputVmName = Split-Path -Leaf $VmOutputFolder
    if ($outputVmName -notmatch '^output-') {
        Write-Error "The output VM folder must start with 'output-': $VmOutputFolder"
        return
    }

    $vmName = $outputVmName -replace '^output-', ''

    Write-Host "VM folder: $VmOutputFolder"
    Write-Host "VM name: $vmName"

    switch ($Command) {
        "import" { 
            Import-HVM -VmName $vmName -VmOutputFolder $VmOutputFolder
            return $vmName
        }
        "start" { 
            Start-HVM -VmName $vmName -VmOutputFolder $VmOutputFolder 
            return $vmName
        }
        "session" { 
            $credential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Enter-PSSession -VMName $vmName -Credential $credential
        }
        "ip" {
            $ip = ""
            for ($i = 5; $i -gt 0; $i--) {
                $ip = Get-IP -vmName $vmName
                if ($ip) {
                    break
                }
                Write-Host "Waiting for IP address... $i"
                Start-Sleep -Seconds 1
            }
            if (-not $ip) {
                Write-Error "Unable to get IP address for VM: $vmName"
                return
            }
            Set-Clipboard -Value $ip
            Write-Host "IP: $ip"
            return $ip
        }
        "ssh" {
            $ip = Get-IP -vmName $vmName
            Write-Host "Use password 'password' to login."
            Invoke-Expression "ssh Administrator@$ip"
        }
        "stop" {
            Stop-VM -Name $vmName
            Write-Host "VM '$vmName' stopped."
        }
        "remove" { Remove-HVM -VmName $vmName }
        "delete" { Remove-HVMData -VmName $vmName -VmOutputFolder $VmOutputFolder }
        default {
            Write-Error "Unknown command: $Command"
            Show-Help
        }
    }
}

function Show-Help {
    Get-Help Invoke-HyperVManager
}

function Import-HVM {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VmName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$VmOutputFolder
    )
    if (Get-VM -Name $VmName -ErrorAction SilentlyContinue) {
        Write-Error "A VM with the name '$VmName' already exists."
        return
    }

    $vmDir = Join-Path -Path $VmOutputFolder -ChildPath "Virtual Machines"
  
    $vmcxFile = Get-ChildItem -Path $vmDir -Filter "*.vmcx" -Recurse | Select-Object -First 1
    if ($null -eq $vmcxFile) {
        Write-Host "No .vmcx files found in the specified output folder: $VmOutputFolder"
        return
    }
    $vmcxPath = $vmcxFile.FullName
  
    Write-Host "Using .vmcx file: $($vmcxPath)"
  
    Import-VM -Path $vmcxPath -Register
}

function New-HVM {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VmName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$VmOutputFolder
    )
    if (Get-VM -Name $VmName -ErrorAction SilentlyContinue) {
        Write-Error "A VM with the name '$VmName' already exists."
        return
    }
    $hdDir = Join-Path -Path $VmOutputFolder -ChildPath "Virtual Hard Disks"
    $vhdxFile = Get-ChildItem -Path $hdDir -Filter "*.vhdx" -Recurse | Select-Object -First 1
    if ($null -eq $vhdxFile) {
        Write-Host "No .vhdx files found in the specified output folder: $VmOutputFolder"
        return
    }
        
    $vhdxPath = $vhdxFile.FullName
    Write-Host "Using .vhdx file: $($vhdxPath)"

    New-VM -Name $VmName -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath $vhdxPath -SwitchName "Default Switch" -Generation 2
}

function Start-HVM {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VmName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$VmOutputFolder
    )

    $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
    if ($null -eq $vm) {
        Write-Host "No VM found with the name '$VmName'. Importing a new VM."
        Import-HVM -VmName $VmName -VmOutputFolder $VmOutputFolder
    }

    $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
    if ($null -eq $vm) {
        Write-Host "No VM found with the name '$VmName'. Creating a new VM."
        New-HVM -VmName $VmName -VmOutputFolder $VmOutputFolder
    }
    $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
    if ($null -eq $vm) {
        Write-Error "Unable to import or create new VM from vmcx or vhdx files in $VmOutputFolder"
        return
    }

    if ($vm.State -ne 'Running') {
        Start-VM -Name $VmName
        Write-Host "VM '$VmName' started."
    }
    else {
        Write-Host "VM '$VmName' is already running."
    }

    $ip = Get-IP -vmName $VmName
    Set-Clipboard -Value $ip
    Write-Host $ip
}

function Remove-HVM {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VmName
    )

    $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue

    if ($null -eq $vm) {
        Write-Host "No VM found with the name '$VmName'."
        return
    }

    if ($vm.State -eq 'Running') {
        Stop-VM -Name $VmName -Force
        Write-Host "VM '$VmName' stopped."
    }

    Remove-VM -Name $VmName -Force
    Write-Host "VM '$VmName' removed."
}

function Remove-HVMData {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VmName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$VmOutputFolder
    )

    Remove-HVM -VmName $VmName

    Remove-Item -Recurse -Force $VmOutputFolder

    Write-Host-Output "Folder $VmOutputFolder deleted."
}

function Get-Vms {
    $runningVMs = Get-VM | Where-Object { $_.State -eq "Running" }

    if ($runningVMs) {
        $runningVMs | Select-Object -ExpandProperty NetworkAdapters | 
        Select-Object VmName, MacAddress, SwitchName, IPAddresses | 
        Format-Table -Wrap -AutoSize
    }
    else {
        Write-Host "No Running Virtual Machines"
    }
}

function Get-IP {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$vmName
    )
    Write-Host "Getting IP address for VM: $vmName"
    $vm = Get-VM -Name $vmName
    $ip = $vm | Select-Object -ExpandProperty NetworkAdapters | 
    Select-Object VmName, MacAddress, SwitchName, @{Name = "IPv4Addresses"; Expression = { $_.IPAddresses -match "^\d{1,3}(\.\d{1,3}){3}$" } }
    $ip = $ip.IPv4Addresses -join ","
    return $ip
}

# Export the function to make it available when module is imported
Export-ModuleMember -Function Invoke-HyperVManager
