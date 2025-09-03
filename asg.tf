variable "capacity_rebalance" {
  default = ""
}
module "aws_autoscaling_group" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.41.1"
  count   = var.ha_mode ? 1 : 0

  name             = var.name
  max_size         = 1
  min_size         = 1
  desired_capacity = 1
  subnet_ids = [var.subnet_id]

  health_check_type         = "EC2"
  wait_for_capacity_timeout = "1m"
  termination_policies      = var.termination_policies

  instance_type = var.instance_type

  mixed_instances_policy = var.mixed_instances_policy

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTotalCapacity",
    "WarmPoolDesiredCapacity",
    "WarmPoolWarmedCapacity",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity"
  ]

  tags = var.tags

  # values shared with the launch template
  image_id = local.ami_id
  key_name = var.ssh_key_name
  credit_specification = { cpu_credits = var.credit_specification }
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = var.ebs_root_volume_size
        volume_type = "gp3"
        encrypted   = var.encryption
        kms_key_id  = var.kms_key_id
      }
    }
  ]
  iam_instance_profile_name = aws_iam_instance_profile.main.name

  security_group_ids          = local.security_groups
  associate_public_ip_address = true
  instance_market_options     = var.use_spot_instances && var.mixed_instances_policy == null ? { market_type = "spot" } : null
  tag_specifications_resource_types = ["instance", "network-interface", "volume"]
  user_data_base64            = data.cloudinit_config.this.rendered

  metadata_http_endpoint_enabled = true
  metadata_http_tokens_required  = true
  capacity_rebalance = var.capacity_rebalance
}
