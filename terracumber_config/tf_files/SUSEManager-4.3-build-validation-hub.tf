// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-build-validation"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-4.3"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results 4.3 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 4.3 Build Validation: Environment setup failed"
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

variable "SERVER_REGISTRATION_CODE" {
  type = string
  default = null
}

terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://yuggoth.mgr.prv.suse.net/system"
}


module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "mnoel-bv-43-"
  use_avahi   = true
  domain      = "tf.local"
  images      = [ "opensuse154o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "rocky8o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "mnoel_disks"
    bridge      = "br0"
    additional_network = "192.168.43.0/24"
  }
}

module "server-hub" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "srv-hub"
  provider_settings = {
    memory             = 8192
    vcpu               = 4
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 500

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server-hub_additional_repos

}

module "server-host1" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "srv-host1"
  provider_settings = {
    memory             = 8192
    vcpu               = 4
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 500

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server-host1_additional_repos

}

module "server-host2" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "srv-host2"
  provider_settings = {
    memory             = 8192
    vcpu               = 4
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 500

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server-host2_additional_repos

}

module "proxy-host2" {
  source             = "./modules/proxy"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "pxy-host2"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-srv-host2.tf.local"
    username = "admin"
    password = "admin"
  }
  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  install_proxy_pattern     = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  ssh_key_path              = "./salt/controller/id_rsa.pub"

  //proxy-host2_additional_repos

}

module "sles15sp3-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    memory             = 4096
    vcpu               = 1
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy-host1.tf.local"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp3-client_additional_repos

}

module "sles15sp4-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 4096
    vcpu               = 1
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy-host2.tf.local"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp4-client_additional_repos

}


module "sles15sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "ssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    memory             = 4096
    vcpu               = 1
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}


module "sles15sp3-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    memory             = 4096
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy-host1.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp3-minion_additional_repos

}

module "sles15sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 4096
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy-host2.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp4-minion_additional_repos

}

module "sles15sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    memory             = 4096
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy-host2.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp5-minion_additional_repos

}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "ctl"
  provider_settings = {
    memory             = 16384
    vcpu               = 4
  }
  swap_file_size = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server-host2.configuration
  proxy_configuration  = module.proxy-host2.configuration

  sle15sp3_client_configuration    = module.sles15sp3-client.configuration
  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
  sle15sp5_sshminion_configuration    = module.sles15sp5-sshminion.configuration

  sle15sp4_client_configuration    = module.sles15sp4-client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration

}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}