# Terraform Konfiguration für zwei VMs (Prod & Test)

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://62.210.89.4:8006/"
  api_token = "terraform-user@pve!terraform-token=a03789d3-3f4c-4a5f-9fd1-cf0fbd27eae1"
  insecure  = true
}

# 1. DEINE BESTEHENDE VM (Importiert & Managed)
resource "proxmox_virtual_environment_vm" "fastapi_vm" {
  node_name = "sd-177082"
  vm_id     = 102
  name      = "VM2"
  
  on_boot         = true
  keyboard_layout = "en-us"
  scsi_hardware   = "virtio-scsi-single"

  cpu {
    cores = 4 # Hier haben wir vorhin auf 4 erhöht!
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
    type    = "virtio"
  }

  network_device {
    bridge   = "vmbr1"
    firewall = true
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = "local"
    interface    = "ide2"
    size         = 3
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = 57
    iothread     = true
  }
}

# 2. DIE NEUE TEST-VM (Wird jetzt erstellt)
resource "proxmox_virtual_environment_vm" "fastapi_vm_test" {
  node_name = "sd-177082"
  vm_id     = 104 # Neue ID für die Test-VM
  name      = "fastapi-test-clone"
  tags      = ["test", "terraform"]

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096 # Etwas weniger RAM für den Test
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr1"
  }

  # Da wir hier kein Template klonen, erstellt Terraform eine leere VM.
  # In der Praxis würde man hier 'clone { datastore_id = "..." }' nutzen.
  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = 20
  }
}