resource "aws_ec2_transit_gateway_vpc_attachment" "secondary_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = aws_vpc.vpc_secondary.id
  subnet_ids         = [aws_subnet.private_subnet_secondary.id]

  tags = {
    Name = "secondary-vpc-tgw-attachment"
  }
}

#####Routes to VPCs####
resource "aws_route" "main_to_secondary" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id
}

resource "aws_route" "secondary_to_main" {
  route_table_id         = aws_route_table.private_rt_secondary.id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id
}
