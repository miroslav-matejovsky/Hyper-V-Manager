packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

locals {
  vm_name = "hvm_example_core"
}

source "hyperv-vmcx" "td-installer-test" {
  vm_name          = local.vm_name
  output_directory = "output-${local.vm_name}"

  clone_from_vmcx_path = "base-hvm_windows_server_2022_core"

  # faster builds ~1 minute
  headless         = true
  skip_export      = true
  skip_compaction  = true
  shutdown_command = "shutdown /s /f /d p:4:1 /c \"Packer Shutdown\""

  cpus                             = 2
  memory                           = 4096
  enable_dynamic_memory            = true
  switch_name                      = "Default Switch"
  generation                       = 2
  enable_secure_boot               = false
  enable_virtualization_extensions = false
  disk_size                        = 61440
  enable_mac_spoofing              = true

  communicator = "ssh"
  ssh_username = "Administrator"
  ssh_password = "password"
  ssh_port     = 22
}

build {
  sources = [
    "source.hyperv-vmcx.td-installer-test"
  ]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Hello, World!'"
    ]
    elevated_user     = "Administrator"
    elevated_password = "password"
  }

}
