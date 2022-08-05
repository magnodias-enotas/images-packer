variable "ami_name" {
  type    = string
  default = "nomad-consul-windows-docker-{{isotime \"2006-01-02-150405\"}}"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "consul_version" {
  type    = string
  default = "1.9.0"
}
variable "nomad_version" {
  type    = string
  default = "1.2.3"
}
variable "docker_version" {
  type    = string
  default = "20.10.14"
}
variable "datadog_version" {
  type    = string
  default = "7.36.1"
}


# https://www.packer.io/docs/builders/amazon/ebs
source "amazon-ebs" "windows" {
  ami_name      = var.ami_name
  instance_type = "t3.medium"
  access_key    = ""
  secret_key    = ""
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = true
  winrm_insecure = true

  # This user data file sets up winrm and configures it so that the connection
  # from Packer is allowed. Without this file being set, Packer will not
  # connect to the instance.
  user_data_file = "winrm_bootstrap.txt"
}

# https://www.packer.io/docs/provisioners
build {
  sources = ["source.amazon-ebs.windows"]

  provisioner "powershell" {
    script = "disable-uac.ps1"
  }

  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "choco install nomad -y --version=${var.nomad_version};",
      "Write-Host 'Completed Nomad installation...'",
      "choco install consul -y --version=${var.consul_version};",
      "Write-Host 'Completed Consul installation...'",
      "choco install -ia=\"ADDLOCAL=\"MainApplication,NPM\"\" datadog-agent -y --version=${var.datadog_version};",
      "Write-Host 'Completed Datadog Agent installation...'"
    ]
  }

  provisioner "powershell" {
    pause_before = "5s"
    inline = [
      "Write-Host 'Starting Docker installation...'",
      "Write-Host 'Installing NuGet Provider...'",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Write-Host 'Installing Docker Provider...'",
      "Install-Module -Name DockerMsftProvider -AllowClobber -Confirm:$false -Force",
      "Write-Host 'Installing Package...'",
      "Install-Package -Name docker -ProviderName DockerMsftProvider -Confirm:$false -Force",
      "Write-Host 'Completed Docker installation...'"
    ]
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  provisioner "powershell" {
    inline = [
      "& 'C:/Program Files/Amazon/EC2Launch/ec2launch' reset --block",
      "& 'C:/Program Files/Amazon/EC2Launch/ec2launch' sysprep --shutdown --block",
    ]
  }
}
