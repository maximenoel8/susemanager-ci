############ Nuremberg unique variables ############

DOMAIN            = "mgr.suse.de"
MIRROR            = "minima-mirror-ci-bv.mgr.suse.de"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.suse.de"
USE_MIRROR_IMAGES = false
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"
ENVIRONMENT_CONFIGURATION = {
  "suma-bv-50-" = {
    mac = {
      controller     = "aa:b2:93:01:03:50"
      server         = "aa:b2:93:01:03:51"
      proxy          = "aa:b2:93:01:03:52"
      suse-minion    = "aa:b2:93:01:03:54"
      suse-sshminion = "aa:b2:93:01:03:55"
      rhlike-minion  = "aa:b2:93:01:03:56"
      deblike-minion  = "aa:b2:93:01:03:57"
      build-host     = "aa:b2:93:01:03:59"
      kvm-host       = "aa:b2:93:01:03:5a"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.111.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  "suma-bv-weekly-50-" = {
    mac = {
      controller     = "aa:b2:93:01:03:5c"
      server         = "aa:b2:93:01:03:5d"
      proxy          = "aa:b2:93:01:03:5e"
      suse-minion    = "aa:b2:93:01:03:60"
      suse-sshminion = "aa:b2:93:01:03:61"
      rhlike-minion  = "aa:b2:93:01:03:62"
      deblike-minion  = "aa:b2:93:01:03:63"
      build-host     = "aa:b2:93:01:03:65"
      kvm-host       = "aa:b2:93:01:03:66"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.112.0/24"
    pool = "ssd"
    bridge = "br0"
  }
}
