project_name = "qag"
aws_profile  = "tii"
region       = "us-east-1"

cluster_version                = "1.35"
vpc_cidr                       = "10.0.0.0/16"
az_count                       = 3
public_access_cidrs            = ["0.0.0.0/0"]
cluster_endpoint_public_access = true

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3
