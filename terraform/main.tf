terraform {
  backend "s3" {
  bucket = "cs291a"
  key = "terraform/ec2.cs291.com.tfstate"
  region = "us-west-2"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.2021*-arm64-gp2"]  # Change "2.0.2021" to update to latest
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

data "aws_iam_policy_document" "lambda-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_route53_zone" "cs291-com" {
  name = "cs291.com."
  private_zone = false
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_default_route_table" "cs291a" {
  default_route_table_id = aws_vpc.cs291a.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cs291a.id
  }
  tags = {
    Name = "cs291a"
  }
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.lambda-role-policy.json
  name = "ScalableInternetServicesLambda"
}

resource "aws_iam_role_policy_attachment" "aws-lambda-basic-execution-role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda.name
}

resource "aws_instance" "ec2-cs291-com" {
  associate_public_ip_address = true
  ami = data.aws_ami.ubuntu.id
  depends_on = [aws_internet_gateway.cs291a]
  disable_api_termination = true
  ebs_optimized = true
  instance_type = "t4g.micro"
  key_name = "admin"
  lifecycle {
    ignore_changes = [user_data]
  }
  subnet_id = aws_subnet.cs291a-a.id
  tags = {
    Name = "ec2.cs291.com"
  }
  user_data = file("user_data.sh")
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.outbound_http.id, aws_security_group.outbound_smtp.id, aws_security_group.outbound_ssh.id, aws_security_group.outbound_tls.id]
}

resource "aws_internet_gateway" "cs291a" {
  tags = {
    Name = "cs291a"
  }
  vpc_id = aws_vpc.cs291a.id
}

resource "aws_route53_record" "ec2-cs291-com" {
  name    = "ec2.cs291.com"
  ttl     = "300"
  type    = "A"
  records = [aws_instance.ec2-cs291-com.public_ip]
  zone_id = data.aws_route53_zone.cs291-com.zone_id
}

resource "aws_security_group" "allow_http" {
  description = "Allow HTTP inbound traffic"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  name = "allow_http"
  tags = {
    Name = "allow_http"
  }
  vpc_id = aws_vpc.cs291a.id
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
  vpc_id = aws_vpc.cs291a.id
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
  vpc_id = aws_vpc.cs291a.id
}

resource "aws_security_group" "outbound_smtp" {
  description = "Allow SMTP outbound traffic"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "SMTP to anywhere"
    from_port = 25
    protocol = "tcp"
    to_port = 25
  }
  name = "outbound_smtp"
  tags = {
    Name = "outbound_smtp"
  }
  vpc_id = aws_vpc.cs291a.id
}

resource "aws_security_group" "outbound_ssh" {
  description = "Allow SSH outbound traffic"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH to anywhere"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  name = "outbound_ssh"
  tags = {
    Name = "outbound_ssh"
  }
  vpc_id = aws_vpc.cs291a.id
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
  vpc_id = aws_vpc.cs291a.id
}

resource "aws_subnet" "cs291a-a" {
  availability_zone = "us-west-2a"
  cidr_block = "10.0.0.0/18"
  vpc_id = aws_vpc.cs291a.id

  tags = {
    Name = "cs291a-2a"
  }
}

resource "aws_subnet" "cs291a-b" {
  availability_zone = "us-west-2b"
  cidr_block = "10.0.64.0/18"
  vpc_id = aws_vpc.cs291a.id

  tags = {
    Name = "cs291a-2b"
  }
}


resource "aws_vpc" "cs291a" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    Name = "cs291a"
  }
}
