locals {
  mixed_instances_policy = (
    var.mixed_instances_policy == null ? null : {
    instances_distribution = var.mixed_instances_policy.instances_distribution
    launch_template        = aws_launch_template.main
    override               = var.mixed_instances_policy.override
  })
}

resource "aws_autoscaling_group" "main" {
  count = var.ha_mode ? 1 : 0

  name                = var.name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]

  termination_policies = var.termination_policies

  dynamic "mixed_instances_policy" {
    for_each = (local.mixed_instances_policy != null ?
      [local.mixed_instances_policy] : [])
    content {
      dynamic "instances_distribution" {
        for_each = (
          mixed_instances_policy.value.instances_distribution != null ?
          [mixed_instances_policy.value.instances_distribution] : [])
        content {
          on_demand_allocation_strategy = lookup(
            instances_distribution.value, "on_demand_allocation_strategy", null)
          on_demand_base_capacity = lookup(
            instances_distribution.value, "on_demand_base_capacity", null)
          on_demand_percentage_above_base_capacity = lookup(
            instances_distribution.value, "on_demand_percentage_above_base_capacity", null)
          spot_allocation_strategy = lookup(
            instances_distribution.value, "spot_allocation_strategy", null)
          spot_instance_pools = lookup(
            instances_distribution.value, "spot_instance_pools", null)
          spot_max_price = lookup(
            instances_distribution.value, "spot_max_price", null)
        }
      }
      launch_template {
        launch_template_specification {
          launch_template_id = mixed_instances_policy.value.launch_template.id
          version            = mixed_instances_policy.value.launch_template.version
        }
        dynamic "override" {
          for_each = (mixed_instances_policy.value.override != null ?
            mixed_instances_policy.value.override : [])
          content {
            instance_type = lookup(override.value, "instance_type", null)
            weighted_capacity = lookup(override.value, "weighted_capacity", null)
          }
        }
      }
    }
  }

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = lookup(var.tags, "Name", null) == null ? ["Name"] : []

    content {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

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

  timeouts {
    delete = "15m"
  }
}
