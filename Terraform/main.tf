terraform {
  required_providers {

    aws = {
    source="hashicorp/aws"

    }

  }
}

provider aws {}

//VPC
# resource "aws_vpc" "main" {
#   cidr_block       = "10.0.0.0/16"

#   tags = {
#     Name = "main"
#   }
# }


//Subnets 

resource "aws_subnet" "subnet1" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet1CIDRblock
    availability_zone = "us-west-1a"

    tags = {
      Name = "Subnet 1"
    }
  
}


resource "aws_subnet" "subnet2" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet2CIDRblock
    availability_zone = "us-west-1b"

    tags = {
      Name = "Subnet 2"
    }
  
}



//Securtity Group


resource "aws_security_group" "lbsg" {
  vpc_id = var.vpc_id
  name = "lbsg"
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    protocol = "TCP"
    to_port = 80
  }
  

  egress{
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = -1
  }


  tags = {
    "Name" = "load_balancer_sg"
  }
}



//Application Load Balancer

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lbsg.id]
  subnets = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
  

  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}


//Target Group

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

//Attach target group to instances

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.lbserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.lbserver2.id
  port             = 80
}




//EC2 Instance 1

resource "aws_instance" "lbserver1" {
    ami = var.ec2_ami
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = true
    user_data = "${file("install_yum.sh")}"
    tags = {
        Name ="lbserver1"
    }
  
}

//EC2 Instance 2

resource "aws_instance" "lbserver2" {
    ami = var.ec2_ami
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet2.id
    associate_public_ip_address = true
    user_data = "${file("install_yum.sh")}"
    tags = {
        Name ="lbserver2"
    }
  
}

//Listener 

resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.test.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.test.arn
    }
  
}






