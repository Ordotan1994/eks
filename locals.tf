locals {
  # The list of AZs in the region
  selected_azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}