// Import the shared library (configure the name 'suse-ci-library' in Jenkins Global Configuration)
@Library('suse-ci-library') _

pipeline {
    agent { label 'sumaform-cucumber' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '3'))
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        string(name: 'cucumber_gitrepo', defaultValue: 'https://github.com/SUSE/spacewalk.git', description: 'Testsuite Git Repository')
        string(name: 'cucumber_ref', defaultValue: 'Manager-4.3', description: 'Branch prepared for the MU tested')
        string(name: 'tf_file', defaultValue: 'susemanager-ci/terracumber_config/tf_files/templates/build-validation-single-provider.tf', description: 'Path to the tf file to be used')
        string(name: 'sumaform_gitrepo', defaultValue: 'https://github.com/uyuni-project/sumaform.git', description: 'Sumaform Git Repository')
        string(name: 'sumaform_ref', defaultValue: 'master', description: 'Sumaform Git reference')
        string(name: 'deploy_parallelism', defaultValue: '', description: 'Define the number of parallel resource operations')
        string(name: 'terracumber_gitrepo', defaultValue: 'https://github.com/uyuni-project/terracumber.git', description: 'Terracumber Git Repository')
        string(name: 'terracumber_ref', defaultValue: 'master', description: 'Terracumber Git ref')
        extendedChoice(name: 'minions_to_run', multiSelectDelimiter: ', ', quoteValue: false, saveJSONParameterToFile: false, type: 'PT_CHECKBOX', visibleItemCount: 15, value: 'sles15sp4_minion', defaultValue: 'sles15sp4_minion', description: 'Node list to run during BV')
        booleanParam(name: 'use_previous_terraform_state', defaultValue: true, description: 'Use previous Terraform state')
        booleanParam(name: 'must_deploy', defaultValue: true, description: 'Deploy')
        booleanParam(name: 'must_run_core', defaultValue: true, description: 'Run Core features')
        booleanParam(name: 'must_sync', defaultValue: true, description: 'Sync products and channels')
        booleanParam(name: 'enable_proxy_stages', defaultValue: true, description: 'Run Proxy stages')
        booleanParam(name: 'enable_client_stages', defaultValue: true, description: 'Run Client stages')
        booleanParam(name: 'must_add_MU_repositories', defaultValue: true, description: 'Add MU channels')
        booleanParam(name: 'must_add_non_MU_repositories', defaultValue: true, description: 'Add non MU channels')
        booleanParam(name: 'must_add_keys', defaultValue: true, description: 'Add Activation Keys')
        booleanParam(name: 'must_create_bootstrap_repos', defaultValue: true, description: 'Create bootstrap repositories')
        booleanParam(name: 'must_boot_node', defaultValue: true, description: 'Bootstrap Node')
        booleanParam(name: 'must_run_tests', defaultValue: true, description: 'Run Smoke Tests')
        booleanParam(name: 'must_run_containerization_tests', defaultValue: false, description: 'Run Containerization Tests')
        booleanParam(name: 'confirm_before_continue', defaultValue: false, description: 'Confirmation button between stages')
        text(name: 'custom_repositories', defaultValue: '{}', description: 'Salt & Client Tools SLE Update Repositories')
    }

    environment {
        // We define these here so they are easily changed per job/version
        SUMAFORM_BACKEND = "libvirt"
        BIN_PATH = "/usr/bin/tofu"
        BIN_PLUGINS_PATH = "/usr/bin"
        NON_MU_CHANNELS_TASKS_FILE = "susemanager-ci/jenkins_pipelines/data/non_MU_channels_tasks_43.json"
        DEPLOYMENT_TFVARS = "susemanager-ci/terracumber_config/tf_files/tfvars/sle-update-tfvars/suma43_sle_update_nue.tfvars"
        PRODUCT_VERSION_DISPLAY = "4.3-released"
    }

    stages {
        stage('Execute Build Validation') {
            steps {
                // We pass Jenkins parameters AND environment variables to our library
                runBuildValidation(params + [
                    sumaform_backend: env.SUMAFORM_BACKEND,
                    bin_path: env.BIN_PATH,
                    bin_plugins_path: env.BIN_PLUGINS_PATH,
                    non_MU_channels_tasks_file: env.NON_MU_CHANNELS_TASKS_FILE,
                    deployment_tfvars: env.DEPLOYMENT_TFVARS,
                    product_version_display: env.PRODUCT_VERSION_DISPLAY
                ])
            }
        }
    }

    post {
        always {
            echo "Pipeline complete. Check the visual graph for stage statuses."
        }
        failure {
            echo "Pipeline failed! The specific step that caused the error is highlighted in red above."
        }
    }
}