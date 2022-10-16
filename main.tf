module "vpc_modules" {
  
  source = "./modules/aws_vpc"
  
  for_each = var.vpc_config

  vpc_cidr_block = each.value.vpc_cidr_block

  tags = each.value.tags
}

module "aws_subnets" {
  
  source = "./modules/aws_subnets"
  
  for_each = var.subnet_config
  
  cidr_block = each.value.cidr_block
  
  tags = each.value.tags
  
  vpc_id = module.vpc_modules[each.value.vpc_name].vpc_id
  
  availability_zone = each.value.availability_zone
}

module "internetGW_module" {
  source = "./modules/aws-internetGW"
  
  for_each = var.internetGW_config
 
  vpc_id = module.vpc_modules[each.value.vpc_name].vpc_id
  
  tags = each.value.tags

}

module "NatGW_module" {
  source = "./modules/aws_natGW"
  
  for_each = var.nat_GW_config

  elasticIP_id = module.Elastic_IP_module[each.value.eip_name].elastic_IP

  subnet_id = module.aws_subnets[each.value.subnet_name].subnet_id

  tags = each.value.tags
}

module "Elastic_IP_module" {
  source = "./modules/aws_elastic_ip"
   
   for_each = var.elastic_ip_config

   tags = each.value.tags

}

module "route_table_module" {
  source = "./modules/aws_route_table"
  
  for_each = var.route_table_config

  vpc_id = module.vpc_modules[each.value.vpc_name].vpc_id
  
  internetGW_id = each.value.private == 0 ? module.internetGW_module[each.value.gateway_name].internetGW_id : module.NatGW_module[each.value.gateway_name].natGW_id
  
  tags = each.value.tags
}

module "route_table_association" {
   source = "./modules/aws_route_table_association"
   
   for_each = var.route_table_association_config 


   route_table_id = module.route_table_module[each.value.route_table_name].route_table_id
   
   subnet_id = module.aws_subnets[each.value.subnet_name].subnet_id
}

module "aws_eks" {
  source = "./modules/aws_eks"
  
  for_each = var.aws_eks_cluster_config

  eks_cluster_name = each.value.eks_cluster_name

  subnet_ids = [module.aws_subnets[each.value.subnet1].subnet_id , module.aws_subnets[each.value.subnet2].subnet_id , module.aws_subnets[each.value.subnet3].subnet_id , module.aws_subnets[each.value.subnet4].subnet_id]

  tags = each.value.tags
}

module "aws_eks_nodegroup" {
  source = "./modules/aws_eks/aws_eks_nodegroup"
  
  for_each = var.aws_eks_node_group_config
  
  node_group_name = each.value.node_group_name
  
  eks_cluster_name = module.aws_eks[each.value.eks_cluster_name].eks_cluster
  
  subnet_ids = [module.aws_subnets[each.value.subnet1].subnet_id , module.aws_subnets[each.value.subnet2].subnet_id]
  
  node_iam_role = each.value.node_iam_role
  
  tags = each.value.tags
}

