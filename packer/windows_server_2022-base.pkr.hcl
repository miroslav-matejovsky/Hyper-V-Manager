# base image for Windows Server 2022 with applied updates and ssh enabled
# this image takes longer to build due to the updates, so it is recommended to build this image first and then use it as a base for other images
locals {
  vm_name = "hvm_windows_server_2022_${var.type}"
}

variable "type" {
  type        = string
  description = "Type of Windows Server installation (desktop or core)"
  default     = "desktop"
  # default     = "core"
  validation {
    condition     = contains(["desktop", "core"], var.type)
    error_message = "Type must be either 'desktop' or 'core'."
  }
}

# packer build -var 'type=code' windows_server_2022-base.pkr.hcl

source "hyperv-iso" "windows_server_2022" {
  vm_name          = local.vm_name
  output_directory = "base-${local.vm_name}"

  # https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022
  iso_url      = "https://go.microsoft.com/fwlink/p/?linkid=2195280" // Windows Server 2022 ISO
  iso_checksum = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"

  secondary_iso_images = ["install\\${var.type}\\secondary.iso"]
  guest_additions_mode = "disable"

  boot_command     = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait        = "1s"
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""

  cpus                  = 2
  memory                = 4096
  disk_size             = 61440
  enable_dynamic_memory = true
  switch_name           = "Default Switch"
  generation            = 2
  # headless does not work with Windows Server 2022, maybe not starting properly?
  headless                         = false
  enable_secure_boot               = false
  enable_virtualization_extensions = false
  enable_mac_spoofing              = true

  // WinRM connection settings
  communicator   = "winrm"
  winrm_timeout  = "1h"
  winrm_username = "Administrator"
  winrm_password = "password"
  winrm_port     = 5985
  winrm_insecure = true
  winrm_use_ssl  = false
}

build {
  sources = [
    "source.hyperv-iso.windows_server_2022"
  ]

  provisioner "windows-update" {
  }

  provisioner "powershell" {
    script            = "./install/enable-ssh-server.ps1"
    elevated_user     = "Administrator"
    elevated_password = "password"
  }
}
