resource "aws_key_pair" "node-key" {
  key_name   = "cluster-keypair"
  public_key = file(local.key_file_name)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-chat"
  cidr = "10.0.0.0/16"

  azs                     = ["us-east-1a", "us-east-1b"]
  public_subnets          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_names     = ["public-subnet-1", "public-subnet-2", "public-subnet-3"]
  map_public_ip_on_launch = true
}


data "template_file" "master_user_data" {
  template = file("${path.module}/user_data/master.sh")

  vars = {
    token = "test"
  }
}

resource "aws_instance" "master" {
  ami                         = local.ami
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.node-key.key_name
  vpc_security_group_ids      = [aws_security_group.node_sg.id]
  user_data                   = data.template_file.master_user_data.rendered
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Name = "master-node"
  }
}

data "template_file" "worker_user_data" {
  template = file("${path.module}/user_data/worker.sh")

  vars = {
    token     = "test"
    master_ip = aws_instance.master.private_ip
  }
}

resource "aws_instance" "node" {
  count                       = 2
  ami                         = local.ami
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.node-key.key_name
  vpc_security_group_ids      = [aws_security_group.node_sg.id]
  user_data                   = data.template_file.worker_user_data.rendered
  subnet_id                   = module.vpc.public_subnets[count.index + 1]
  associate_public_ip_address = true

  depends_on = [aws_instance.master]

  tags = {
    Name = "worker-node-${count.index + 1}"
  }
}

resource "aws_security_group" "node_sg" {
  name        = "node-security-group"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ssh_commands_to_worker_nodes" {
  value       = [for public_dns in aws_instance.node.*.public_dns : "ssh ubuntu@${public_dns}"]
  description = "SSH commands to connect to Kubernetes worker nodes"
}

output "ssh_commands_to_master_node" {
  value       = "ssh ubuntu@${aws_instance.master.public_dns}"
  description = "SSH commands to connect to Kubernetes master node"
}

output "master_node_public_ip" {
  value       = aws_instance.master.public_ip
  description = "Public IP of the master node"
}
