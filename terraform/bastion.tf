resource "aws_instance" "bastion" {
  #checkov:skip=CKV_AWS_88:Bastion host requires public IP for SSH access
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  associate_public_ip_address = true
  monitoring                  = true
  ebs_optimized               = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.ebs.arn

    tags = {
      Name        = "${var.project_name}-bastion-root"
      Description = "Root volume for bastion host"
    }
  }

  tags = {
    Name        = "${var.project_name}-bastion"
    Description = "Bastion host for BookStore infrastructure"
  }

  depends_on = [aws_iam_role_policy.bastion_policy]
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_kms_key" "ebs" {
  #checkov:skip=CKV2_AWS_64:KMS policy will be added later
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EnableRootPermissions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::<ACCOUNT_ID>:root"
      }
      Action   = "kms:*"
      Resource = "*"
    }]
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
