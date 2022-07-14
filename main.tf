provider "aws" {
  region     = "us-east-1"
  access_key = "access key"
  secret_key = "secret key"
}



#1 create vpc
resource "aws_vpc" "VPC1" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "terraform-vpc"
  }
}



#2 create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC1.id

  tags = {
    Name = "tf-igw"
  }
}



#3 create custom route table
resource "aws_route_table" "first-route-table" {
  vpc_id = aws_vpc.VPC1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.igw.id 
  }

  tags = {
    Name = "tf-route-table"
  }
}



#4 create a subnet
resource "aws_subnet" "first-subnet" {
  vpc_id = aws_vpc.VPC1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-subnet1"
  }
}



#5 associate subnet to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.first-subnet.id
  route_table_id = aws_route_table.first-route-table.id
} 



#6 create security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.VPC1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}



#7 create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.first-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}



#8 assign an elastic ip to network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.igw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}



#9 create Ubuntu server & install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"  
  availability_zone = "us-east-1a"
  key_name = "terraform -key"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }  

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo YOUR VERY FIRST TERRAFORM WEB SERVER > /var/www/html/index.html'
              EOF

  tags = {
    "Name" = "tf-server1"
  }
}

output "server_private_id" {
  value = aws_instance.web-server-instance.private_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}



# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "tf-vpc"
#   }
# }



# resource "aws_subnet" "first-subnet" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "tf-subnet1"
#   }
# }




# resource "aws_instance" "my-first-server" {
#   ami           = "ami-052efd3df9dad4825"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "first-terraform-server"
#   }
# }
