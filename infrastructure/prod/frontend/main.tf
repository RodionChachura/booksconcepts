terraform {
  backend "s3" {
    bucket = "infrastructure-remote-state"
    key = "booksconcepts/prod/frontend.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "route" {
  backend = "s3"
  config {
    bucket = "infrastructure-remote-state"
    key = "booksconcepts/global/route.tfstate"
    region = "eu-central-1"
  }
}

module "frontend" {
  source = "../../modules/certificate"

  domain = "${data.terraform_remote_state.route.domain}"
  zone_id ="${data.terraform_remote_state.route.zone_id}"
}
