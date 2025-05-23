data "aws_vpc" "default" {
  default = true
}

# Security Group for Jenkins Master
resource "aws_security_group" "jenkins_master_sg" {
  name = "jenkins-master-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080  
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere (replace with your desired IP range)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere (replace with your desired IP range)
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Security Group for Jenkins Agent
resource "aws_security_group" "jenkins_agent_sg" {
  name = "jenkins-agent-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Replace with your desired IP range
  }

  # Add additional ingress rules for specific ports required by Jenkins Agent
  # For example, if the Agent needs to communicate with EKS on port 443:
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Replace with your desired IP range
  }

  # Add additional ingress rule for Sonar Qube
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Replace with your desired IP range
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Jenkins Master EC2 Instance
resource "aws_instance" "jenkins_master" {
  ami           = var.jenkins_master_ami
  instance_type = var.jenkins_master_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.jenkins_master_sg.id,
  ]

  tags = {
    Name = var.jenkins_master_name
  }
}

# Jenkins Agent EC2 Instance
resource "aws_instance" "jenkins_agent" {
  ami           = var.jenkins_agent_ami
  instance_type = var.jenkins_agent_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.jenkins_agent_sg.id,
  ]

  root_block_device {
    volume_size = 20 # Specify the size of the root EBS volume in GB
  }

  tags = {
    Name = var.jenkins_agent_name
  }

  user_data = <<-EOF
                #!/bin/bash
                # Update package lists
                sudo apt update
                # Install curl (needed to download NodeSource setup script)
                sudo apt install -y curl
                # Download and run the NodeSource setup script for Node.js 18.x
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                # Install Node.js
                sudo apt install -y nodejs
              EOF
}
