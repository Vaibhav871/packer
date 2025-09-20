packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "base_ami" {
  type    = string
  default = "ami-02d26659fd82cf299" # Ubuntu LTS base AMI
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "nomad_version" {
  type    = string
  default = "1.10.5"
}

variable "nomad_download_url" {
  type    = string
  default = "https://releases.hashicorp.com/nomad/1.10.5/nomad_1.10.5_linux_amd64.zip"
}

source "amazon-ebs" "nomad" {
  region                 = var.aws_region
  source_ami             = var.base_ami
  instance_type          = var.instance_type
  ssh_username           = var.ssh_username
  ami_name               = format(
    "nomad-ami-%s-%s",
    replace(var.nomad_version, ".", "-"),
    regex_replace(timestamp(), ":|\\.", "-")
  )
  vpc_id                 = ""                        # Optional: fill if needed
  subnet_id              = ""                        # Optional: pass your subnet ID or variable
  associate_public_ip_address = true
  ami_description        = "Nomad AMI built with Packer"
  force_deregister       = true
  force_delete_snapshot  = true

  launch_block_device_mappings{
    device_name          = "/dev/sda1"
    volume_size          = var.root_volume_size
    volume_type          = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = format("nomad-ami-%s-%s", replace(var.nomad_version, ".", "-"), regex_replace(timestamp(), ":|\\.", "-"))
    Environment = "Production"
    Project     = "Infra"
  }

  iam_instance_profile   = "" # Adjust or remove if not used
}

build {
  sources = ["source.amazon-ebs.nomad"]

provisioner "file" {
  source      = "scripts/install_nomad.sh"
  destination = "/tmp/install_nomad.sh"
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/install_nomad.sh",
    "sudo /tmp/install_nomad.sh ${var.nomad_version} ${var.nomad_download_url}"
  ]
}
}
