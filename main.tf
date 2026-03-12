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
    cores = 4
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
    bridge  = "vmbr1"
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

# 2. DIE NEUE TEST-VM (Klon von VM 102)
resource "proxmox_virtual_environment_vm" "fastapi_vm_test" {
  node_name = "sd-177082"
  vm_id     = 104
  name      = "fastapi-test-clone"
  tags      = ["test", "terraform"]

  # HIER IST DER FIX: Wir klonen die bestehende VM 102
  clone {
    vm_id = 102
    full  = true # Erstellt eine unabhängige Kopie
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr1"
  }

  # Cloud-Init: Bereitet die VM für Ansible vor
  initialization {
    user_account {
      username = "ipatsaf"
      # FIX: Der Key muss zwingend in eckigen Klammern stehen [ "key" ]
      keys     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxdlhZBtGgDrl4K281tBOyaqfWh5AW7SGO6kIHD3OVOIUZY+YzUdFWOe9eY5SHi7VtZ1DYb4DcroEN7JQn/7yCb7kAhtkqVMTcisQs3+UDBo4smSqEeTxnj0WROQpQr0i2dxkAHw61wi+eeBbe05oktZTXuf8yrwjq7obVSOcY4vmbnUGgYehQJ5VS+jILzHfJNd10CH94MkKsvh1TQjj1KbMuhsPCZR+Y6jMcPuHjcYDb8rv7dqni1x/09YHY6LDkEuisqESoAExXi7TwrEq7i4nbfg/spYocJ+bkCf4byA9s7RupV9frAau2Phj5lwGybQdF4KU+BzAu6r5TIt7pIXhhKK7XE+UGZ82UwwU9gxd+DAHi7Gf7qHfZ8kMPx8mhinxnmsJccpI9trtk1CNTZgiXAnPEofGesLMYqQXMfiee+1K0dk1aC00AWBonERRT4lVWcFcie/KnhwdySqmZ5mBr91KiRfdd9DjIpn2qTMCFF1wIbIL6mVZEh+2C8VcxYS4WqiB8uBvriMsY+jqhs46vByThDIcW47HwvcaK0ZXtA6haZOeGMNk0bwytOYZHEw71Qcxry4ZSc8iwqEQm4T+hAjMRjo4p9mOy56t+m3ylkVj+hsNM27DGx3GTLmki5zg3LHGJvGnVEX7PeuZI2VAXnuvIiNDCYVb43MaCkw== manqo@MacBookPro-285.box"]
    }
    
    ip_config {
      ipv4 {
        address = "dhcp" # Holt sich automatisch eine IP für Ansible
      }
    }
  }
}