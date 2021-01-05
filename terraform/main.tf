data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

output "ip_addr" {
  value = aws_eip.ec2-cs291-com.public_ip
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_eip" "ec2-cs291-com" {
  instance = aws_instance.ec2-cs291-com.id
  vpc = true
}

resource "aws_instance" "ec2-cs291-com" {
  ami = data.aws_ami.ubuntu.id
  ebs_optimized = true
  instance_type = "t4g.micro"
  key_name = "admin"
  tags = {
    Name = "ec2.cs291.com"
  }
  user_data = file("user_data.sh")
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.outbound_http.id, aws_security_group.outbound_tls.id]
}

resource "aws_security_group" "allow_ssh" {
  description = "Allow SSH inbound traffic"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  name = "allow_ssh"
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "outbound_http" {
  description = "Allow HTTP outbound traffic"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP to anywhere"
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  name = "outbound_http"
  tags = {
    Name = "outbound_http"
  }
}

resource "aws_security_group" "outbound_tls" {
  description = "Allow TLS outbound traffic"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "TLS to anywhere"
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  name = "outbound_tls"
  tags = {
    Name = "outbound_tls"
  }
}
