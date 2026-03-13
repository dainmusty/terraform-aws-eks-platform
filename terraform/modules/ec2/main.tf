locals {
  public_instances = flatten([
    for i in range(length(var.public_instance_count)) : [
      for j in range(var.public_instance_count[i]) : {
        name = "${var.ami_names[i]}-${j + 1}"
        ami  = var.ami_ids[i]
        type = var.instance_types[i]

        additional_tags = try(var.tag_value_public_instances[i][j], {})
      }
    ]
  ])

  private_instances = flatten([
    for i in range(length(var.private_instance_count)) : [
      for j in range(var.private_instance_count[i]) : {
        name = "${var.ami_names[i]}-${j + 1}"
        ami  = var.ami_ids[i]
        type = var.instance_types[i]

        additional_tags = try(var.tag_value_private_instances[i][j], {})
      }
    ]
  ])
}


# Launch EC2 instances in public subnets
resource "aws_instance" "public" {
  for_each = {
    for idx, inst in local.public_instances :
    inst.name => inst
  }

  ami           = each.value.ami
  instance_type = each.value.type
  key_name      = var.key_name
  subnet_id     = element(var.public_subnet_ids, index(var.ami_ids, each.value.ami) % length(var.public_subnet_ids))
  security_groups = [var.public_sg_id]
  #iam_instance_profile = var.instance_profile_name
  user_data = file("${path.module}/../../scripts/public_userdata.sh") # Update the user_data script as needed
  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = merge(
    {
      Name = "${var.ResourcePrefix}-public-${each.key}"
    },
    each.value.additional_tags
  )

  depends_on = []
}

# Launch EC2 instances in private subnets
resource "aws_instance" "private" {
  for_each = {
    for idx, inst in local.private_instances :
    inst.name => inst
  }

  ami           = each.value.ami
  instance_type = each.value.type
  key_name      = var.key_name
  subnet_id     = element(var.private_subnet_ids, index(var.ami_ids, each.value.ami) % length(var.private_subnet_ids))
  security_groups = [var.private_sg_id]
  #iam_instance_profile = var.instance_profile_name
  user_data = templatefile("${path.module}/../../scripts/private_userdata.sh", {})

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = merge(
    {
      Name = "${var.ResourcePrefix}-private-${each.key}"
    },
    each.value.additional_tags
  )

  depends_on = []
}


