terraform {
  backend "s3" {
    bucket = "infrastructure-remote-state"
    key = "booksconcepts/stage/frontend.tfstate"
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

module "stage_route" {
  source = "../../modules/route"
  
  domain = "${var.env}.${data.terraform_remote_state.route.domain}"
  env = "${var.env}"
  global_zone_id = "${data.terraform_remote_state.route.zone_id}"
}


module "certificate" {
  source = "../../modules/certificate"

  domain = "${var.env}.${data.terraform_remote_state.route.domain}"
  zone_id = "${module.stage_route.zone_id}"
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  
  env = "${var.env}"
  certificate_arn = "${module.certificate.certificate_arn}"
  domain = "${var.env}.${data.terraform_remote_state.route.domain}"
  zone_id = "${module.stage_route.zone_id}"
}

module "pipeline" {
  source = "../../modules/frontend-pipeline"

  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"

  env = "${var.env}"
  deploy_bucket = "${module.cloudfront.build_bucket}"
  distribution_id = "${module.cloudfront.distribution_id}"
  repo_name = "${var.repo_name}"
  repo_owner = "${var.repo_owner}"
  branch = "${var.env}"
}

