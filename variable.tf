#---variable/root

variable "zone_id" {
  type    = string
  default = ""
}


variable "region_number" {
  default = {
    us-west-2 = 1
    us-west-1 = 2
    us-east-1 = 3

  }
}

variable "az_number" {
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}