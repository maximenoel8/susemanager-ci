############ Uyuni unique variables ############

IMAGE                  = "opensuse155-ci-pro"
SERVER_IMAGE           = "slemicro55o"
PROXY_IMAGE            = "slemicro55o"
IMAGES                 = ["rocky8o", "opensuse155o", "ubuntu2404o", "sles15sp4o", "slemicro55o"]
SUSE_MINION_IMAGE      = "sles15sp4o"
PRODUCT_VERSION        = "5.0-pr"
MAIL_TEMPLATE_ENV_FAIL = "../mail_templates/mail-template-jenkins-pull-request-env-fail.txt"
MAIL_TEMPLATE          = "../mail_templates/mail-template-jenkins-pull-request.txt"
MAIL_SUBJECT           = "$status acceptance tests on Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
CUCUMBER_BRANCH        = "Manager-5.0"
CUCUMBER_GITREPO       = "https://github.com/SUSE/spacewalk.git"
CUCUMBER_COMMAND       = "export PRODUCT='SUSE-Manager' && run-testsuite"
URL_PREFIX             = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-prs-ci-tests"
ADDITIONAL_REPOS_ONLY  = true
RHLIKE_MINION_IMAGE    = "rocky8o"
DEBLIKE_MINION_IMAGE   = "ubuntu2404o"
