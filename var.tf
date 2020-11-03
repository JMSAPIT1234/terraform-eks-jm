variable "region" {
  default     = "me-south-1"
  description = "AWS region"
}

variable "cluster_name" {
  default = "devops-eks-terra"
}

variable "private_subnet" {
  default = ["subnet-041a4b6d15743a52a","subnet-0a9e2431dc7987ec1"]
}

variable "vpc_id" {
  default = "vpc-0511bd5d887e46266"
}

variable "ssh_cidr" {
  default     = ""
  description = "The CIDR blocks from which to allow incoming ssh connections to the EKS nodes."
}

variable "eks_version" {
  default     = "1.18"
  description = "Kubernetes version to use for the cluster."
}

variable "permissions_boundary" {
  default     = ""
  description = "If provided, all IAM roles will be created with this permissions boundary attached."
}

variable "cluster_private_access" {
  default     = true
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
}

variable "cluster_public_access" {
  default     = true
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
}

variable "workstation_cidr" {
  default     = []
  description = "CIDR blocks from which to allow inbound traffic to the Kubernetes control plane."
}

variable "route_table_id" {
    default   = ["rtb-007e700c868c9f371"]
    description = "Route table id"
}

variable "vpc_cidr" {
    default = "10.153.4.0/22"
}

variable "nodes_defaults" {
  description = "Default values for target groups as defined by the list of maps."

  default = {
    name                 = "eks-nodes"    # Name for the eks workers.
    ami_id               = "ami-074353661095a7cd9" # AMI ID for the eks workers. If none is provided, Terraform will searchfor the latest version of their EKS optimized worker AMI.
    asg_desired_capacity = "2"            # Desired worker capacity in the autoscaling group.
    asg_max_size         = "3"            # Maximum worker capacity in the autoscaling group.
    asg_min_size         = "2"            # Minimum worker capacity in the autoscaling group.
    instance_type        = "t3.medium"     # Size of the workers instances.
    key_name             = "devops-eks-key"      # The key name that should be used for the instances in the autoscaling group
    ebs_optimized        = false          # sets whether to use ebs optimization on supported types.
    public_ip            = false          # Associate a public ip address with a worker
  }
}

variable "disk_size" {
  default     = 20
  description = "The root device size for the worker nodes."
}
