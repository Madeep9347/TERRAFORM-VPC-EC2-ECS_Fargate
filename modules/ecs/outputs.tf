# output "ecs_cluster_id" {
#   description = "The ID of the ECS Cluster"
#   value       = aws_ecs_cluster.fargate_cluster.id
# }

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}



