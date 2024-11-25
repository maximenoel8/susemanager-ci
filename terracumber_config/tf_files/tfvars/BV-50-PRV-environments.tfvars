############ Provo unique variables ############

DOMAIN            = "mgr.prv.suse.net"
MIRROR            = "minima-mirror-ci-bv.mgr.prv.suse.net"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.prv.suse.net"
USE_MIRROR_IMAGES = true
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"
ENVIRONMENT_CONFIGURATION = {
  "release" = {
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
    base = {
      core = {
        provider = "core"
        images = [ "sles15sp4o", "opensuse155o", "slemicro55o", "sles15sp5o" ]
        pool = "ssd"
        bridge = "br1"
      }
      old_sle ={
        provider = "tatooine"
        images = [ "sles12sp5o" ]
        pool        = "ssd"
        bridge      = "br1"
      }
      res = {
        provider = "tatooine"
        images = [ "almalinux8o", "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o", "libertylinux9o" ]
        pool        = "ssd"
        bridge      = "br1"
      }
      new_sle = {
        provider = "florina"
        images = [ "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o"  ]
        pool        = "ssd"
        bridge      = "br1"
      }
      retail = {
        provider = "terminus"
        images = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "opensuse155o", "opensuse156o", "slemicro55o" ]
        pool        = "ssd"
        bridge      = "br1"
      }
      debian = {
        provider = "trantor"
        images = [ "ubuntu2004o", "ubuntu2204o", "ubuntu2404o", "debian11o", "debian12o" ]
        pool        = "ssd"
        bridge      = "br1"
      }
      arm = {
        provider = "suma-arm"
        images = [ "opensuse155armo", "opensuse156armo" ]
        pool        = "ssd"
        bridge      = "br0"
      }
    }
    hypervisor = "romulus.mgr.prv.suse.net"
    additional_network = "192.168.50.0/24"
    prefix = "suma-bv-50-"
  }
}
