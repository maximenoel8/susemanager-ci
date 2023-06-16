// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
}

variable "CUCUMBER_GITREPO" {
  type = string
}

variable "CUCUMBER_BRANCH" {
  type = string
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
}

variable "MAIL_TEMPLATE" {
  type = string
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Failed acceptance tests on Pull Request: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
}

variable "ENVIRONMENT" {
  type = string
  default = "1"
}

variable "HYPER" {
  type = string
  default = "romulus.mgr.prv.suse.net"
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-ci@suse.de"
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

// Repository containing the build for the tested Uyuni Pull Request
variable "PULL_REQUEST_REPO" {
  type = string
}

variable "MASTER_REPO" {
  type = string
}

variable "MASTER_OTHER_REPO" {
  type = string
}

variable "MASTER_SUMAFORM_TOOLS_REPO" {
  type = string
}

variable "UPDATE_REPO" {
  type = string
}

variable "ADDITIONAL_REPO_URL" {
  type = string
}

variable "TEST_PACKAGES_REPO" {
  type = string
}

// Repositories containing the client tools RPMs
variable "SLE_CLIENT_REPO" {
  type = string
}

variable "RHLIKE_CLIENT_REPO" {
  type = string
}

variable "DEBLIKE_CLIENT_REPO" {
  type = string
}

variable "OPENSUSE_CLIENT_REPO" {
  type = string
}

variable "IMAGE" {
  type = string
}

variable "GIT_PROFILES_REPO" {
  type = string
}

variable "IMAGES" {
  type = list(string)
}

variable "PRODUCT_VERSION" {
  type = list(string)
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
  uri = "qemu+tcp://${var.HYPER}/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = var.PRODUCT_VERSION

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  mirror      = "minima-mirror.mgr.prv.suse.net"
  use_mirror_images = true

  images = var.IMAGES

  use_avahi    = false
  name_prefix  = "suma-pr${var.ENVIRONMENT}-"
  domain       = "mgr.prv.suse.net"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry      = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = var.GIT_PROFILES_REPO

  server_http_proxy = "http-proxy.mgr.prv.suse.net:3128"
  custom_download_endpoint = "ftp://minima-mirror.mgr.prv.suse.net:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:00"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:04:00:01"
      }
      additional_repos_only = true
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
        master_repo_other = var.MASTER_OTHER_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
        testing_overlay_devel = "http://minima-mirror.mgr.prv.suse.net/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/",
      }
      image = var.IMAGE
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
      server_mounted_mirror = "minima-mirror.mgr.prv.suse.net"
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:04:00:02"
      }
      additional_repos_only = true
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
        master_repo_other = var.MASTER_OTHER_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
        testing_overlay_devel = "http://minima-mirror.mgr.prv.suse.net/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/",
        proxy_pool = "http://minima-mirror.mgr.prv.suse.net/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Uyuni-Proxy-POOL-x86_64-Media1/",
        tools_update = var.OPENSUSE_CLIENT_REPO
      }
      image = var.IMAGE
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:04"
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:05"
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8o"
      name = "min-rocky8"
      provider_settings = {
        mac = "aa:b2:92:04:00:06"
        memory = 2048
        vcpu = 2
      }
      additional_repos = {
        client_repo = var.RHLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      image = "ubuntu2204o"
      name = "min-ubuntu2204"
      provider_settings = {
        mac = "aa:b2:92:04:00:07"
      }
      additional_repos = {
        client_repo = var.DEBLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      // FIXME: cloudl-init fails if venv-salt-minion is not avaiable
      // We can set "install_salt_bundle = true" as soon as venv-salt-minion is available Uyuni:Stable
      install_salt_bundle = false
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:92:04:00:09"
        memory = 2048
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = var.IMAGE
      name = "min-kvm"
      additional_grains = {
        hvm_disk_image = {
          leap = {
            hostname = "suma-pr1-min-nested"
            image = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2"
            hash = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
          }
          sles = {
            hostname = "suma-pr1-min-nested"
            image = "http://minima-mirror.mgr.prv.suse.net/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2"
            hash = "http://minima-mirror.mgr.prv.suse.net/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2.sha256"
          }
        }
      }
      provider_settings = {
        mac = "aa:b2:92:04:00:0a"
      }
      additional_repos_only = true
      additional_repos = {
        client_repo = var.OPENSUSE_CLIENT_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }
  nested_vm_host = "suma-pr1-min-nested"
  nested_vm_mac =  "aa:b2:92:04:00:0b"
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.101.0/24"
  }
}


resource "null_resource" "add_test_information" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "file" {
    source      = "../../susemanager-ci/terracumber_config/scripts/set_custom_header.sh"
    destination = "/tmp/set_custom_header.sh"
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.server.hostname}"
    }
  }
}


output "configuration" {
  value = module.cucumber_testsuite.configuration
}