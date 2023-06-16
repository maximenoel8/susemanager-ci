############ Unique to uyuni ########################

IMAGE="opensuse154-ci-pro"
GIT_PROFILES_REPO="https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"
IMAGES=["rocky8o", "opensuse154o", "opensuse154-ci-pro", "sles15sp4o", "ubuntu2204o"]
PRODUCT_VERSION="uyuni-pr"
MAIL_TEMPLATE_ENV_FAIL="../mail_templates/mail-template-jenkins-pull-request-env-fail.txt"
MAIL_TEMPLATE="../mail_templates/mail-template-jenkins-pull-request.txt"
MAIL_SUBJECT="$status acceptance tests on Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
CUCUMBER_BRANCH="master"
CUCUMBER_GITREPO="https://github.com/uyuni-project/uyuni.git"
CUCUMBER_COMMAND="export PRODUCT='Uyuni' && run-testsuite"
URL_PREFIX="https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-prs-ci-tests"

############### GENERIC PART BETWEEN THE TWO PIPELINE ########################
##  This variables are not correctly describe
SLE_CLIENT_REPO=${SLE_CLIENT_REPO}
RHLIKE_CLIENT_REPO=${RHLIKE_CLIENT_REPO}
DEBLIKE_CLIENT_REPO=${DEBLIKE_CLIENT_REPO}
OPENSUSE_CLIENT_REPO=${OPENSUSE_CLIENT_REPO}
PULL_REQUEST_REPO=${PULL_REQUEST_REPO}
MASTER_OTHER_REPO=${MASTER_OTHER_REPO}
MASTER_SUMAFORM_TOOLS_REPO=${MASTER_SUMAFORM_TOOLS_REPO}
TEST_PACKAGES_REPO=${TEST_PACKAGES_REPO}
MASTER_REPO=${MASTER_REPO}
UPDATE_REPO=${UPDATE_REPO}
ADDITIONAL_REPO_URL=${ADDITIONAL_REPO_URL}
CUCUMBER_GITREPO=${cucumber_gitrepo}
CUCUMBER_BRANCH=${cucumber_ref}
