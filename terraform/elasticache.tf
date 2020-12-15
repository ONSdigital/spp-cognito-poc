resource "aws_elasticache_cluster" "poc_client" {
  cluster_id           = "spp-cognito-poc-client"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  subnet_group_name    = aws_elasticache_subnet_group.poc_client.name
  security_group_ids   = [aws_security_group.poc_elasticache.id]
}

resource "aws_elasticache_subnet_group" "poc_client" {
  name       = "spp-cognito-poc-client"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_security_group" "poc_elasticache" {
  name        = "spp-cognito-poc-elasticache"
  description = "elasticache"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
