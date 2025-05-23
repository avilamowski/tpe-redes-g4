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


resource "aws_launch_template" "worker_lt" {
  name_prefix   = "worker-lt-"
  image_id      = local.ami
  instance_type = local.instance_type
  key_name      = aws_key_pair.node-key.key_name

  vpc_security_group_ids = [aws_security_group.node_sg.id]

  user_data = base64encode(data.template_file.worker_user_data.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "worker-node-autoscaled"
    }
  }
}

resource "aws_autoscaling_group" "worker_asg" {
  name_prefix         = "worker-asg-"
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.worker_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "worker-node-autoscaled"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  autoscaling_group_name = aws_autoscaling_group.worker_asg.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "This metric monitors high CPU usage"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
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

output "worker_nodes_in_asg" {
  value       = aws_autoscaling_group.worker_asg.name
  description = "Auto Scaling Group name for the worker nodes"
}

output "ssh_commands_to_master_node" {
  value       = "ssh ubuntu@${aws_instance.master.public_dns}"
  description = "SSH commands to connect to Kubernetes master node"
}

output "master_node_public_ip" {
  value       = aws_instance.master.public_ip
  description = "Public IP of the master node"
}
