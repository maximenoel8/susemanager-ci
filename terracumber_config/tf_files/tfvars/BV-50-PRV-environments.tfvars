############ Provo unique variables ############

DOMAIN            = "mgr.prv.suse.net"
MIRROR            = "minima-mirror-ci-bv.mgr.prv.suse.net"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.prv.suse.net"
USE_MIRROR_IMAGES = true
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"
ENVIRONMENT_CONFIGURATION = {
  "suma-bv-50-" = {
    mac = {
      controller     = "aa:b2:92:04:00:00"
      server         = "aa:b2:92:04:00:01"
      proxy          = "aa:b2:92:04:00:02"
      suse-minion    = "aa:b2:92:04:00:04"
      suse-sshminion = "aa:b2:92:04:00:05"
      rhlike-minion  = "aa:b2:92:04:00:06"
      deblike-minion = "aa:b2:92:04:00:07"
      build-host     = "aa:b2:92:04:00:09"
      kvm-host       = "aa:b2:92:04:00:0a"
    }
    hypervisor = "romulus.mgr.prv.suse.net"
    additional_network = "192.168.101.0/24"
    pool = "ssd"
    bridge = "br1"
  }
}
