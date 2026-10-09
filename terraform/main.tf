# Wrapper root module (this lab's own file, not upstream's): applies CloudGoat's rce_web_app
# scenario (app/cloudgoat/scenarios/aws/rce_web_app/terraform, unchanged) as a child module with
# the variables CloudGoat's Python CLI would pass: a cgid ("rce_web_app_cgid" and ten random
# characters, as CloudGoat makes it), the AWS profile, the player's public IP as cg_whitelist (a
# list, which Isoloom's string `vars` can't express) and an SSH key pair, made once by keygen.sh
# into the lab's .keys/ (CloudGoat's CLI runs ssh-keygen the same way). The scenario reads files
# relative to Terraform's working directory: this lab's `assets` is a symlink to the scenario's
# own.
terraform {
  required_version = ">= 1.5"
  required_providers {
    random   = { source = "hashicorp/random", version = "~> 3.6" }
    external = { source = "hashicorp/external", version = "~> 2.3" }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "profile" {
  description = "The AWS CLI profile the scenario's provider (and its deploy steps) use."
  type        = string
  default     = "default"
}

variable "whitelist" {
  description = "Your public IP as a CIDR (x.x.x.x/32): the only address the scenario's instances accept."
  type        = string
  default     = "0.0.0.0/32"
}

# Refuses to create the lab before the player set their IP (not checked on destroy, so
# `isoloom down` works whatever the value).
resource "terraform_data" "whitelist_set" {
  lifecycle {
    precondition {
      condition     = can(cidrhost(var.whitelist, 0)) && var.whitelist != "0.0.0.0/32"
      error_message = "Set your public IP: PLAYER_CIDR=$(curl -s https://checkip.amazonaws.com)/32 isoloom run cloud-services"
    }
  }
}

resource "random_string" "cgid" {
  length  = 10
  upper   = false
  special = false
}

data "external" "ssh_key" {
  program = ["sh", "${path.module}/keygen.sh", abspath("${path.module}/../.keys")]
}

module "scenario" {
  source          = "../app/cloudgoat/scenarios/aws/rce_web_app/terraform"
  profile         = var.profile
  region          = var.region
  cgid            = "rce_web_app_cgid${random_string.cgid.result}"
  cg_whitelist    = [var.whitelist]
  ssh_public_key  = data.external.ssh_key.result.public
  ssh_private_key = data.external.ssh_key.result.private
}

output "lara_access_key_id" {
  value = module.scenario.cloudgoat_output_lara_access_key_id
}

output "lara_secret_key" {
  value     = module.scenario.cloudgoat_output_lara_secret_key
  sensitive = true
}

output "mcduck_access_key_id" {
  value = module.scenario.cloudgoat_output_mcduck_access_key_id
}

output "mcduck_secret_key" {
  value     = module.scenario.cloudgoat_output_mcduck_secret_key
  sensitive = true
}
