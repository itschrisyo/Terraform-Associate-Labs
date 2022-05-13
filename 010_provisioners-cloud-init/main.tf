terraform {
  cloud {
    organization = "terraform-lab-edson"

    workspaces {
      name = "provisioners"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.13.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

data "aws_vpc" "main" {
  id = "vpc-5bcd7721"
}

resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "My Server SG"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["73.129.20.207/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_labs"
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDj/JJt+8PKl+EyBc4VhP76kHN6Wvv77JvGZf9x0Ubpehz8SkrRAVW8hCVO6PyvGGwCS5lg5Y7hb7V3tRSpmJPwcOkZgu5Z3iggQa71lTv8IfPsn7KhMgYWJoDwWTDSqeLEjzLRS3uPKnsljI47xjkctf+9YBHERiCOkou/gIL1Y5rYeSuUok40xy/kTgnxGzxI0VgSNmTgdTFrFudTWqt9A2FsVn9iYS0s1OfzrNgY5w2Q2gMZB9fDf4wuoXOE9PXYlxx7t6wVVKPn409EVFj33qUdh/9ma5ncbgOy4YootWMBZMrt3KTSAnUbxHK9syvutHdO0V+iIgFGGUS0t+4hRuFM9t9iGFDlgxUiohLq2FXGpvnVhAhb02BxayVvRSRio0qeayxXXiND920qLAc/Q2/Cl5XItG+hSw8idDzGnnMXf0aGmsX5tya8BFVVpdBWx12nMmXkOWmHjYr8cIxHOOU4lAnMRAvNhpaQFFOUuuf8HVKcle585brhyTVabd0= cedson@TENA000308.local"
}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

resource "aws_instance" "tf_labserver" {
  ami           = "ami-087c17d1fe0178315"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  user_data = data.template_file.user_data.rendered
  tags = {
    Name = "TFLabServer"
  }
}

output "public_ip" {
    value = aws_instance.tf_labserver.public_ip
}