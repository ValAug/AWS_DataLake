#---main/root---

module "data" {
  source = "./analytic"
  bucket_name = "informationlogs"
}
module "network" {
  source = "./networking"
  ec2_count = 1
}