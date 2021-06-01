#---provider---

provider "aws" {
  default_tags {

    tags = {
      Enviroment = "DataLake-test"
      Project    = "DataLake-infrastructure"
    }
  }
  region = "us-east-1"
}