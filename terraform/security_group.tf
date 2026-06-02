resource "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = module.vpc.vpc_id

  # DEMO: SSH open to the entire internet — never do this
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
    Project = var.project_name
  }
}
