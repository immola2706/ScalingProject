// use AWS terraform provider
provider "aws" {
	region = "us-east-1"
}

data "aws_ami" "jenkins-master" {
  most_recent = true
  owners      = ["self"]

  filter {
	name   = "name"
	values = ["jenkins-master-2.107.2"]
  }
}

data "aws_ami" "jenkins-slave" {
  most_recent = true
  owners      = ["self"]

  filter {
	name   = "name"
	values = ["jenkins-slave"]
  }
}
resource "aws_instance" "jenkins_master" {
  ami                    = "${data.aws_ami.jenkins-master.id}"
  instance_type          = "${var.jenkins_master_instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.jenkins_master_sg.id}"]
  subnet_id              = "${element(var.vpc_private_subnets, 0)}"

  root_block_device {
	volume_type           = "gp2"
	volume_size           = 30
	delete_on_termination = false
  }

  tags {
	Name   = "jenkins_master"
	Author = "mlabouardy"
	Tool   = "Terraform"
  }
}
resource "aws_route53_record" "masterdns" {
  zone_id = "${var.hosted_zone_id}"
  name    = "jenkins.slowcoder.com"
  type    = "A"

  alias {
	name                   = "${aws_elb.jenkins_elb.dns_name}"
	zone_id                = "${aws_elb.jenkins_elb.zone_id}"
	evaluate_target_health = true
  }
}
// Scale out
resource "aws_cloudwatch_metric_alarm" "high-cpu-jenkins-slaves-alarm" {
  alarm_name          = "high-cpu-jenkins-slaves-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
	AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-out.arn}"]
}

resource "aws_autoscaling_policy" "scale-out" {
  name                   = "scale-out-jenkins-slaves"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}

// Scale In
resource "aws_cloudwatch_metric_alarm" "low-cpu-jenkins-slaves-alarm" {
  alarm_name          = "low-cpu-jenkins-slaves-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions {
	AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-in.arn}"]
}

resource "aws_autoscaling_policy" "scale-in" {
  name                   = "scale-in-jenkins-slaves"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}