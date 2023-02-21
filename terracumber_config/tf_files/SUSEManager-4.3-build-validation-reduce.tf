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
  images      = [ "opensuse154o", "sles15sp2o", "sles15sp3o", "sles15sp4o" ]

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
module "centos7-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.tf.local"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //ceos7-client_additional_repos

}

module "centos7-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //ceos7-minion_additional_repos

}

module "rocky8-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //rocky8-minion_additional_repos

}

module "rocky9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //rocky9-minion_additional_repos

}

module "ubuntu1804-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //ubuntu1804-minion_additional_repos

}

module "ubuntu2004-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //ubuntu2004-minion_additional_repos

}

module "ubuntu2204-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-debian10"
  image              = "debian10o"
  provider_settings = {
    memory             = 4096
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //debian10-minion_additional_repos

}

module "debian11-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    memory             = 4096
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //debian11-minion_additional_repos

}

module "opensuse154arm-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "4.3-released"
  name               = "min-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //opensuse154arm-minion_additional_repos

}

module "slemicro52-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    memory             = 2048
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //slemicro52-minion_additional_repos

}

module "alma9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //alma9-minion_additional_repos

}

module "oracle9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    memory             = 4096
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //oracle9-minion_additional_repos

}

module "slemicro53-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    memory             = 2048
  }

  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //slemicro52-minion_additional_repos

}

module "centos7-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky8-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2204-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "mnoel-bv-43-pxy.tf.local"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
  name               = "terminal-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    manufacturer       = "HP"
    product            = "ProLiant DL360 Gen9"
  }
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "ctl"
  provider_settings = {
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration


  centos7_client_configuration    = module.centos7-client.configuration
  centos7_minion_configuration    = module.centos7-minion.configuration
  centos7_sshminion_configuration = module.centos7-sshminion.configuration

  rocky8_minion_configuration    = module.rocky8-minion.configuration
  rocky8_sshminion_configuration = module.rocky8-sshminion.configuration

  rocky9_minion_configuration    = module.rocky9-minion.configuration
  rocky9_sshminion_configuration = module.rocky9-sshminion.configuration

  alma9_minion_configuration    = module.alma9-minion.configuration

  oracle9_minion_configuration    = module.oracle9-minion.configuration

  ubuntu1804_minion_configuration    = module.ubuntu1804-minion.configuration
  ubuntu1804_sshminion_configuration = module.ubuntu1804-sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204-minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204-sshminion.configuration

  debian10_minion_configuration    = module.debian10-minion.configuration

  debian11_minion_configuration    = module.debian11-minion.configuration

  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration

  slemicro52_minion_configuration    = module.slemicro52-minion.configuration

  slemicro53_minion_configuration    = module.slemicro53-minion.configuration

  sle15sp4_buildhost_configuration = module.sles15sp4-buildhost.configuration

  sle15sp4_terminal_configuration = module.sles15sp4-terminal.configuration

}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
