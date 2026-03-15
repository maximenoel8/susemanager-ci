@Library('suse-ci-library') _

pipeline {
    agent { label 'sumaform-cucumber' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '3'))
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'cucumber_ref', defaultValue: 'Manager-5.1')
        string(name: 'server_container_repository', defaultValue: 'registry.suse.de/suse/sle-15-sp7/update/products/multilinuxmanager51/update/containerfile')
        string(name: 'container_project', defaultValue: 'Devel:Galaxy:Manager:MUTesting:5.1')
        // ... (Include the rest of the parameters from your file here)
    }

    environment {
        // These replace your 'mutableParams'
        SUMAFORM_BACKEND = "libvirt"
        BIN_PATH = "/usr/bin/tofu"
        BIN_PLUGINS_PATH = "/usr/bin"
        PRODUCT_VERSION_DISPLAY = "5.1-released"
        NON_MU_CHANNELS_TASKS_FILE = "susemanager-ci/jenkins_pipelines/data/non_MU_channels_tasks_51.json"
        DEPLOYMENT_TFVARS = "susemanager-ci/terracumber_config/tf_files/tfvars/sle-update-tfvars/mlm51_sles_sle_update_nue.tfvars"
    }

    stages {
        stage('Execute Validation') {
            steps {
                // Call the library, merging Jenkins params with our Env vars
                runBuildValidation(params + [
                    sumaform_backend: env.SUMAFORM_BACKEND,
                    bin_path: env.BIN_PATH,
                    bin_plugins_path: env.BIN_PLUGINS_PATH,
                    product_version_display: env.PRODUCT_VERSION_DISPLAY,
                    non_MU_channels_tasks_file: env.NON_MU_CHANNELS_TASKS_FILE,
                    deployment_tfvars: env.DEPLOYMENT_TFVARS
                ])
            }
        }
    }
}