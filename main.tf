provider "aws" {
  region = var.region
}
resource "aws_key_pair" "aws_key" {
  key_name   = "you"
  public_key = file("${path.module}/you.pub")

}
# creating the vpc for the  project 
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "devops-project-vpc"
  }
}

resource "aws_subnet" "sub_net1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.12.13.0/27"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-sunet_1 for the devops"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.12.13.32/27"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true


  tags = {
    Name = "public-subnet_2 for the devops"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "rta1" {

  subnet_id      = aws_subnet.sub_net1.id
  route_table_id = aws_route_table.route_table.id


}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id


}


resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_lb" "alb" {
  name               = "devops-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]

  subnets = [
    aws_subnet.sub_net1.id,
    aws_subnet.subnet2.id
  ]

  tags = {
    Name = "devops-alb"
  }
}
resource "aws_lb_target_group" "tg" {
  name     = "devops-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#creating the auto scaling group
resource "aws_autoscaling_group" "web_asg" {
  name = "web-asg"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.sub_net1.id,
    aws_subnet.subnet2.id
  ]

  target_group_arns = [
    aws_lb_target_group.tg.arn
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type = "ELB"
}




# creating the launch template fore the auto scaling
resource "aws_launch_template" "web" {
  name_prefix   = "web-template-"
  image_id      = "ami-091138d0f0d41ff90"
  instance_type = "t3.micro"

  key_name = aws_key_pair.aws_key.key_name

  vpc_security_group_ids = [
    aws_security_group.webSg.id
  ]
  # this for the just testing 
  # user_data = base64encode(<<-EOF
  #             #!/bin/bash
  #             apt update -y
  #             apt install nginx -y

  #             systemctl enable nginx
  #             systemctl start nginx

  #             echo "<h1>Hello from Auto Scaling Group</h1>" > /var/www/html/index.html
  #             EOF
  # )
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt update -y
              apt install docker.io -y

              systemctl start docker
              systemctl enable docker

              docker pull brijesh112007/devops-app:latest

              docker run -d -p 80:80 brijesh112007/devops-app:latest
              EOF
)
}





# for creating the instance one
# resource "aws_instance" "server1" {
#   ami                    = "ami-091138d0f0d41ff90"
#   instance_type          = "t3.micro"
#   key_name               = aws_key_pair.aws_key.key_name
#   vpc_security_group_ids = [aws_security_group.webSg.id]
#   subnet_id              = aws_subnet.sub_net1.id
#   user_data              = <<-EOF
#               #!/bin/bash
#               apt update -y
#               apt install nginx -y

#               systemctl enable nginx
#               systemctl start nginx

#               echo "<html><body><h1>Hello from Terraform</h1></body></html>" > /var/www/html/index.html
#               EOF
#   tags = {
#     Name = "devops-server1"
#   }
# }



#for creating the instance 2  
# resource "aws_instance" "server2" {
#   ami                    = "ami-091138d0f0d41ff90"
#   instance_type          = "t3.micro"
#   key_name               = aws_key_pair.aws_key.key_name
#   vpc_security_group_ids = [aws_security_group.webSg.id]

#   subnet_id = aws_subnet.subnet2.id

#   user_data = <<-EOF
#               #!/bin/bash
#               apt update -y
#               apt install nginx -y

#               systemctl enable nginx
#               systemctl start nginx

#               echo "<h1>Hello from Server 2</h1>" > /var/www/html/index.html
#               EOF

#   tags = {
#     Name = "devops-server-2"
#   }
# }


# resource "aws_lb_target_group_attachment" "attach1" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.server1.id
#   port             = 80
# }


# resource "aws_lb_target_group_attachment" "attach2" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.server2.id
#   port             = 80
# }


resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


