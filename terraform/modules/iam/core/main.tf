# Permission Boundary
#########################################
# Shared Permission Boundary Policy
#########################################

resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.company_name}-${var.env}-permission-boundary"
  description = "Unified permission boundary for EKS, VPC Flow Logs, CloudWatch, Grafana, Prometheus, and S3 access roles."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # --- S3 Logs (VPC Flow, Config, General) ---
      {
        Sid    = "AllowS3LogAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*"
        ]
      },

      # --- CloudWatch Logs for VPC Flow / Config / Prometheus ---
      {
        Sid    = "AllowCloudWatchLogsAccess",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },

      # --- CloudWatch Metrics for Grafana / Prometheus ---
      {
        Sid    = "AllowCloudWatchMetricsAccess",
        Effect = "Allow",
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },

      # --- EC2 Describe for Prometheus ---
      {
        Sid      = "AllowEC2DescribeInstances",
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances"],
        Resource = "*"
      },

      # --- Basic Admin and Config Permissions ---
      {
        Sid    = "AllowAdminAndConfigOps",
        Effect = "Allow",
        Action = [
          "iam:ListRoles",
          "iam:GetRole",
          "iam:PassRole",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "s3:ListAllMyBuckets",
          "config:PutConfigurationRecorder",
          "config:PutDeliveryChannel",
          "config:StartConfigurationRecorder",
          "config:StopConfigurationRecorder"
        ],
        Resource = "*"
      },

      # --- Explicit Deny for Privilege Escalation ---
      {
        Sid    = "DenyPrivilegeEscalation",
        Effect = "Deny",
        Action = [
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole",
          "iam:UpdateAssumeRolePolicy"
        ],
        Resource = "*"
      }
    ]
  })
}


# -------------------------------------------------------
#  Role for VPC Flow Logs
# -------------------------------------------------------

# IAM Role for VPC Flow Logs if cloud-watch-logs is used as destination
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.company_name}-${var.env}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  permissions_boundary = aws_iam_policy.permission_boundary.arn

  tags = {
    Name = "${var.env}-vpc-flow-logs-role"
  }
}


# IAM Policy for VPC Flow Logs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${var.log_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::${var.log_bucket_name}"
      }
    ]
  })
}


# --- Admin Role ---
data "aws_iam_policy_document" "admin_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.admin_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "admin_role" {
  name                 = "${var.company_name}-${var.env}-admin-role"
  assume_role_policy   = data.aws_iam_policy_document.admin_assume.json
  permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "admin_policy" {
  name        = "admin-full-access"
  description = "Full admin access for admin role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

# # RBAC Instance Profile
# resource "aws_iam_instance_profile" "rbac_instance_profile" {
#   name = var.rbac_instance_profile_name
#   role = aws_iam_role.admin_role.name
# }


# --- Config Role ---
data "aws_iam_policy_document" "config_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.config_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config_role" {
  name                 = "${var.company_name}-${var.env}-config-role"
  assume_role_policy   = data.aws_iam_policy_document.config_assume.json
  permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "config_policy" {
  name        = "aws-config-policy"
  description = "Policy for AWS Config role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["config:*", "s3:GetBucketAcl", "s3:PutObject"],
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*"
        ]
      }
    ]
  })
}

# --- S3 Full Access Role ---
data "aws_iam_policy_document" "s3_full_access_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.s3_full_access_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_full_access_role" {
  name                 = "${var.company_name}-${var.env}-s3-full-access-role"
  assume_role_policy   = data.aws_iam_policy_document.s3_full_access_assume.json
  permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3-full-access"
  description = "Policy for full read/write S3 access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:*"],
        Resource = [
          var.operations_bucket_arn,
          "${var.operations_bucket_arn}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_s3_full_access_policy" {
  role       = aws_iam_role.s3_full_access_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}


# --- S3 RW Access Role ---
data "aws_iam_policy_document" "s3_rw_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.s3_rw_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_rw_role" {
  name                 = "${var.company_name}-${var.env}-s3-rw-role"
  assume_role_policy   = data.aws_iam_policy_document.s3_rw_assume.json
  permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "s3_rw_access" {
  name        = "S3AccessToBucket"
  description = "Allow read/write access to the specified S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_rw_policy" {
  role       = aws_iam_role.s3_rw_role.name
  policy_arn = aws_iam_policy.s3_rw_access.arn
}


# --- Grafana Role ---
data "aws_iam_policy_document" "grafana_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.grafana_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "grafana_policy" {
  name        = "${var.env}-grafana-policy"
  description = "Policy for Grafana role"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      },
      
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "grafana_role" {
  name                 = "${var.company_name}-${var.env}-grafana-role"
  assume_role_policy   = data.aws_iam_policy_document.grafana_assume.json
  #permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "${var.env}-cloudwatch-policy"
  description = "Policy for CloudWatch role"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_policy_attachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}



# --- Prometheus Role ---
data "aws_iam_policy_document" "prometheus_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.prometheus_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "prometheus_role" {
  name                 = "${var.company_name}-${var.env}-prometheus-role"
  assume_role_policy   = data.aws_iam_policy_document.prometheus_assume.json
  #permissions_boundary = aws_iam_policy.permission_boundary.arn

}

resource "aws_iam_policy" "prometheus_policy" {
  name        = "${var.env}-prometheus-policy"
  description = "Policy for Prometheus role"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

# Will take care these later
# # Instance profiles
# resource "aws_iam_instance_profile" "grafana_instance_profile" {
#   name = var.grafana_instance_profile_name
#   role = aws_iam_role.grafana_role.name
# }

# resource "aws_iam_instance_profile" "prometheus_instance_profile" {
#   name = var.prometheus_instance_profile_name
#   role = aws_iam_role.prometheus_role.name
# }




############################################
# IAM Roles for EKS Cluster and Node Groups
############################################

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster_role" {

  name = "${var.env}-cluster-role"



  assume_role_policy = jsonencode({

    Version = "2012-10-17",

    Statement = [{

      Action = "sts:AssumeRole",

      Effect = "Allow",

      Principal = {

        Service = "eks.amazonaws.com"

      }

    }]

  })

}

# Attach required policies to the EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    #"arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" you can add this if using VPC CNI custom networking
  ])
  role       = aws_iam_role.cluster_role.name
  policy_arn = each.key
}
########################################


########################################
# EKS Node Group Role
resource "aws_iam_role" "node_group_role" {
  name = "${var.env}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

 

# Attach required policies to the Node Group Role
resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each = toset([
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
  "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group_role.name

}

########################################