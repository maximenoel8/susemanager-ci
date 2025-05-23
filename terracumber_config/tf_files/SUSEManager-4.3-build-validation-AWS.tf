
// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-43/job/SUSEManager-432-AWS"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results Manager4.3-WS-MU $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Manager4.3-AWS-MU: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-noise@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-noise@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = string
}

variable "SCC_PASSWORD" {
  type = string
}

variable "GIT_USER" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "REGION" {
  type = string
  default = null
}

variable "MIRROR"{
  type = string
  default = null
}

variable "AVAILABILITY_ZONE" {
  type = string
  default = null
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

variable "KEY_NAME" {
  type = string
  default = "testing-suma"
}

variable "SERVER_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "PROXY_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "SLES_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "ALLOWED_IPS" {
  type = list(string)
  default = []
}

variable "NAME_PREFIX" {
  type = string
  default = "manager-4-3-qe-build-validation-aws"
}

locals {
  domain            = "suma.ci.aws"
}

provider "aws" {
  region     = var.REGION
}

module "base" {
  source = "./modules/base"

  cc_username              = var.SCC_USER
  cc_password              = var.SCC_PASSWORD
  name_prefix              = var.NAME_PREFIX
  mirror                   = var.MIRROR
  testsuite                = true
  use_avahi                = false
  use_eip_bastion          = false
  is_server_paygo_instance = false
  product_version            = "4.3-released"
  provider_settings = {
    availability_zone = var.AVAILABILITY_ZONE
    region            = var.REGION
    ssh_allowed_ips   = var.ALLOWED_IPS
    key_name          = var.KEY_NAME
    key_file          = var.KEY_FILE
    route53_domain    = local.domain
    bastion_host      = "${var.NAME_PREFIX}-bastion.${local.domain}"
  }
}

module "mirror" {
  source = "./modules/mirror"
  base_configuration = module.base.configuration
  disable_cron = true
  provider_settings = {
    public_instance = true
  }
  image = "opensuse156o"
}

module "server" {
  source                     = "./modules/server"
  base_configuration = merge(module.base.configuration,
  {
    mirror = null
  })
  name                       = "server"
  main_disk_size             = 200
  repository_disk_size       = 1500
  database_disk_size         = 0
  server_registration_code   = var.SERVER_REGISTRATION_CODE

  java_debugging                 = false
  auto_accept                    = false
  monitored                      = true
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
  create_first_user              = false
  mgr_sync_autologin             = false
  create_sample_channel          = false
  create_sample_activation_key   = false
  create_sample_bootstrap_script = false
  publish_private_ssl_key        = false
  use_os_released_updates        = true
  disable_download_tokens        = false
  disable_auto_bootstrap         = true
  large_deployment               = true
  ssh_key_path                   = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "m6a.xlarge"
  }

  //server_additional_repos

}

module "proxy" {
  source                    = "./modules/proxy"
  base_configuration        = module.base.configuration
  server_configuration      = module.server.configuration
  product_version           = "4.3-released"
  name                      = "proxy"
  proxy_registration_code   = var.PROXY_REGISTRATION_CODE

  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  install_proxy_pattern     = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  proxy_containerized       = false
  ssh_key_path              = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "c6i.large"
  }
}

module "sles12sp5_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "cli-sles12sp5"
  image              = "sles12sp5"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  additional_packages = [ "chrony" ]
}

module "sles15sp3_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp3"
  image                = "sles15sp3o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}


module "sles15sp4_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp4"
  image                = "sles15sp4o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}


module "sles15sp5_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp5"
  image                = "sles15sp5o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp6_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp6"
  image                = "sles15sp6o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp7_client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp7"
  image                = "sles15sp7o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "ubuntu2004_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004"
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "rhel9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  server_configuration = module.server.configuration
  product_version    = "4.3-released"
  name               = "min-rhel9"
  image              = "rhel9"
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "rocky8_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-rocky8"
  image              = "rocky8"
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles12sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles12sp5"
  image              = "sles12sp5"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  additional_packages = [ "chrony" ]
}

module "sles15sp3_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp4_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

// This is an x86_64 SLES 15 SP5 minion (like sles15sp5-minion),
// dedicated to testing migration from OS Salt to Salt bundle
module "salt_migration_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  name               = "min-salt-migration"
  product_version    = "4.3-released"
  image              = "sles15sp5o"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp6_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp6"
  image              = "sles15sp6o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp7_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp7"
  image              = "sles15sp7o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "ubuntu2004_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "rocky8_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-rocky8"
  image              = "rocky8"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true

  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles12sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5"
  use_os_released_updates = false
  sles_registration_code = var.SLES_REGISTRATION_CODE
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
  provider_settings = {
    instance_type = "t3a.medium"
  }
  additional_packages = [ "chrony" ]
}

module "sles15sp3_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp4_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp6_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp6"
  image              = "sles15sp6o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp7_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp7"
  image              = "sles15sp7o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "ubuntu2204_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "ubuntu2204_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  server_configuration = module.server.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204"
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //ubuntu2204-minion_additional_repos

}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"
  provider_settings = {
    instance_type = "c6i.xlarge"
  }
  product_version    = "4.3-released"

  swap_file_size = null
  no_mirror = true
  is_using_build_image = false
  is_using_scc_repositories = true
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration    = module.server.configuration
  proxy_configuration     = module.proxy.configuration

  sle12sp5_client_configuration    = module.sles12sp5_client.configuration
  sle12sp5_minion_configuration    = module.sles12sp5_minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5_sshminion.configuration

  sle15sp3_client_configuration    = module.sles15sp3_client.configuration
  sle15sp3_minion_configuration    = module.sles15sp3_minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3_sshminion.configuration

  sle15sp4_client_configuration    = module.sles15sp4_client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4_minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4_sshminion.configuration

  sle15sp5_client_configuration    = module.sles15sp5_client.configuration
  sle15sp5_minion_configuration    = module.sles15sp5_minion.configuration
  sle15sp5_sshminion_configuration = module.sles15sp5_sshminion.configuration

  salt_migration_minion_configuration = module.salt_migration_minion.configuration

  sle15sp6_client_configuration    = module.sles15sp6_client.configuration
  sle15sp6_minion_configuration    = module.sles15sp6_minion.configuration
  sle15sp6_sshminion_configuration = module.sles15sp6_sshminion.configuration

  rhel9_minion_configuration       = module.rhel9_minion.configuration

  rocky8_minion_configuration    = module.rocky8_minion.configuration
  rocky8_sshminion_configuration = module.rocky8_sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004_minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004_sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204_minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204_sshminion.configuration


//  debian12_minion_configuration    = module.debian12_minion.configuration
//  debian12_sshminion_configuration = module.debian12_sshminion.configuration
}

output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}

output "aws_mirrors_private_name" {
  value = module.mirror.configuration.hostnames
}

output "aws_mirrors_public_name" {
  value = module.mirror.configuration.public_names
}

output "configuration" {
  value = {
    controller = module.controller.configuration
    bastion = {
      hostname = lookup(module.base.configuration, "bastion_host", null)
    }
  }
}
