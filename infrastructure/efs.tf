resource "aws_efs_file_system" "efs" {}

resource "aws_efs_access_point" "lambda_access_point" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/dynamodb-full-text-search"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "755"
    }
  }
  posix_user {
    uid = 1001
    gid = 1001
  }
}

resource "aws_security_group" "efs_sg" {
  name   = "efs_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_default_security_group.default_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "mount_target_public" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet_public.id
  security_groups = [aws_security_group.efs_sg.id]
}
