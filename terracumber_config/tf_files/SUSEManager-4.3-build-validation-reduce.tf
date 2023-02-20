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
  use_avahi   = false
  domain      = "tf.local"
  images      = [ "opensuse154o", "sles15sp4o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "mnoel_disks"
    bridge      = "br0"
    additional_network = "192.168.43.0/24"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "srv"
  provider_settings = {
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 1700
  server_registration_code   = var.SERVER_REGISTRATION_CODE

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

  //server_additional_repos

}

module "proxy" {
  source             = "./modules/proxy"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "pxy"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-srv.tf.local"
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

  //proxy_additional_repos

}

//module "sles15sp3-client" {
//  source             = "./modules/client"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "cli-sles15sp3"
//  image              = "sles15sp3o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:ad"
//    memory             = 4096
//  }
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_register           = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //sle15sp3-client_additional_repos
//
//}
//
//module "sles15sp4-client" {
//  source             = "./modules/client"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "cli-sles15sp4"
//  image              = "sles15sp4o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:ae"
//    memory             = 4096
//  }
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_register           = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //sle15sp4-client_additional_repos
//
//}
//
//
//module "sles15sp2-minion" {
//  source             = "./modules/minion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "min-sles15sp2"
//  image              = "sles15sp2o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:b4"
//    memory             = 4096
//  }
//
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //sle15sp2-minion_additional_repos
//
//}
//
//module "sles15sp3-minion" {
//  source             = "./modules/minion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "min-sles15sp3"
//  image              = "sles15sp3o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:b5"
//    memory             = 4096
//  }
//
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //sle15sp3-minion_additional_repos
//
//}
//
//module "sles15sp4-minion" {
//  source             = "./modules/minion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "min-sles15sp4"
//  image              = "sles15sp4o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:b6"
//    memory             = 4096
//  }
//
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //sle15sp4-minion_additional_repos
//
//}
//
//module "sles15sp2-sshminion" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "minssh-sles15sp2"
//  image              = "sles15sp2o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:d4"
//    memory             = 4096
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}
//
//module "sles15sp3-sshminion" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "minssh-sles15sp3"
//  image              = "sles15sp3o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:d5"
//    memory             = 4096
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}
//
//module "sles15sp4-sshminion" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "minssh-sles15sp4"
//  image              = "sles15sp4o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:d6"
//    memory             = 4096
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}
//
//module "monitoring-server" {
//  source             = "./modules/minion"
//  base_configuration = module.base_core.configuration
//  product_version    = "4.3-released"
//  name               = "monitoring"
//  image              = "sles15sp4o"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:a3"
//    memory             = 2048
//  }
//
//  server_configuration = {
//    hostname = "mnoel-bv-43-pxy.tf.local"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  //monitoring_additional_repos
//}
//
//module "controller" {
//  source             = "./modules/controller"
//  base_configuration = module.base_core.configuration
//  name               = "ctl"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:a0"
//    memory             = 16384
//    vcpu               = 8
//  }
//  swap_file_size = null
//
//  // Cucumber repository configuration for the controller
//  git_username = var.GIT_USER
//  git_password = var.GIT_PASSWORD
//  git_repo     = var.CUCUMBER_GITREPO
//  branch       = var.CUCUMBER_BRANCH
//
//  server_configuration = module.server.configuration
//  proxy_configuration  = module.proxy.configuration
//
//  sle15sp2_minion_configuration    = module.sles15sp2-minion.configuration
//  sle15sp2_sshminion_configuration = module.sles15sp2-sshminion.configuration
//
//  sle15sp3_client_configuration    = module.sles15sp3-client.configuration
//  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
//  sle15sp3_sshminion_configuration = module.sles15sp3-sshminion.configuration
//
//  sle15sp4_client_configuration    = module.sles15sp4-client.configuration
//  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration
//  sle15sp4_sshminion_configuration = module.sles15sp4-sshminion.configuration
//
//  monitoringserver_configuration = module.monitoring-server.configuration
//}

//output "configuration" {
//  value = {
//    controller = module.controller.configuration
//  }
//}
