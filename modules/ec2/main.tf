# Frontend Security Group
resource "aws_security_group" "frontend_sg" {
  name   = "frontend-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend Security Group
resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
#   ingress {
#   from_port       = 3000
#   to_port         = 3000
#   protocol        = "tcp"
#   security_groups = [aws_security_group.alb_sg.id]
# }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database Security Group
resource "aws_security_group" "database_sg" {
  name   = "database-sg"
  vpc_id = var.vpc_id

  # MongoDB from Backend EC2
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }


  # MySQL from Backend EC2
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }


  # SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


##ec2
# Frontend EC2
resource "aws_instance" "frontend" {
  ami                    = var.ubuntu_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  key_name               = var.key_name

  user_data = file("${path.module}/user_data/docker.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "frontend-ec2"
  }
}

# Backend EC2
resource "aws_instance" "backend" {
  ami                    = var.ubuntu_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_name

  user_data = file("${path.module}/user_data/docker.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "backend-ec2"
  }
}

# Database EC2
resource "aws_instance" "database" {
  ami                    = var.ubuntu_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[2]
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "database-ec2"
  }
}

##bastion host
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id

  ingress {
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
    Name = "bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.ubuntu_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "bastion-host"
  }
}

