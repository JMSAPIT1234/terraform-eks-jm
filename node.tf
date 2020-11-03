resource "aws_security_group" "eks-nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-nodes.id
  source_security_group_id = aws_security_group.eks-nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_allow_ssh" {
  count = length(var.ssh_cidr) != 0 ? 1 : 0

  description       = "The CIDR blocks from which to allow incoming ssh connections to the EKS nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.eks-nodes.id
  cidr_blocks       = [var.ssh_cidr]
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-nodes.id
  source_security_group_id = aws_security_group.eks-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

locals {
  eks-nodes-userdata = <<USERDATA
#!/bin/bash -xe
CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.cluster.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.cluster.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster_name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${var.region},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.cluster.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet kube-proxy
USERDATA
}

resource "aws_launch_configuration" "node" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = var.nodes_defaults["ami_id"]
  instance_type               = var.nodes_defaults["instance_type"]
  key_name                    = var.nodes_defaults["key_name"]
  name_prefix                 = "eks-node"
  security_groups             = [aws_security_group.eks-nodes.id]
  user_data_base64            = base64encode(local.eks-nodes-userdata)
  ebs_optimized               = var.nodes_defaults["ebs_optimized"]

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    delete_on_termination = true
    volume_size = var.disk_size
  }
}

resource "aws_autoscaling_group" "autoscaling-group" {
  desired_capacity     = var.nodes_defaults["asg_desired_capacity"]
  launch_configuration = aws_launch_configuration.node.id
  max_size             = var.nodes_defaults["asg_max_size"]
  min_size             = var.nodes_defaults["asg_min_size"]
  name                 = "${var.nodes_defaults["name"]}-asg"

  vpc_zone_identifier = flatten([var.private_subnet])

  tag {
    key                 = "Name"
    value               = "${var.nodes_defaults["name"]}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
