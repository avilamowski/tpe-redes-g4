locals {
  ami           = "ami-080e1f13689e07408" # Ubuntu 22.04 LTS (HVM), SDD Volume Type
  instance_type = "t2.medium"

  #change the location of the key file
  key_file_name = "~/.ssh/id_rsa.pub"
  region        = "us-east-1"
}

/*
ssh_commands_to_master_node = "ssh ubuntu@ec2-54-243-0-23.compute-1.amazonaws.com"
ssh_commands_to_worker_nodes = [
  "ssh ubuntu@ec2-18-206-223-153.compute-1.amazonaws.com",
  "ssh ubuntu@ec2-44-211-170-16.compute-1.amazonaws.com",
]
*/
