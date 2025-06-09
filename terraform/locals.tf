locals {
  ami           = "ami-080e1f13689e07408" # Ubuntu 22.04 LTS (HVM), SDD Volume Type
  instance_type = "t2.medium"

  #change the location of the key file
  key_file_name = "~/.ssh/id_rsa.pub"
  region        = "us-east-1"
}
