def call(Map params) {
    script {
        // --- 1. Global Setup ---
        env.bootstrap_timeout = 800
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${env.resultdir}/${BUILD_NUMBER}"
        def localSumaformDirPath = "${env.resultdir}/sumaform/"

        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; export CAPYBARA_TIMEOUT=60; export DEFAULT_TIMEOUT=500; export CUCUMBER_PUBLISH_QUIET=true;"
        env.common_params = "--outputdir ${env.resultdir} --tf ${params.tf_file} --gitfolder ${localSumaformDirPath} --terraform-bin ${params.bin_path}"
        if (params.deploy_parallelism) env.common_params += " --parallelism ${params.deploy_parallelism}"

        def deployed = false

        try {
            stage('Initialize') {
                sh "mkdir -p ${env.resultdir}"
                git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                dir("susemanager-ci") { checkout scm }
                currentBuild.description = nameDisplay(params) // Calls your extracted helper
            }

            stage('Build containers') {
                if (params.container_project && params.mi_project && params.must_deploy) {
                    sh "python3 -m venv ${WORKSPACE}/venv"
                    // ... Your container build python script execution here ...
                }
            }

            stage('Deploy Environment') {
                if (params.must_deploy) {
                    sh "source /home/jenkins/.credentials; ./terracumber-cli ${env.common_params} --runstep gitsync --gitrepo ${params.sumaform_gitrepo}"

                    // ... Your custom_repositories.json logic ...
                    // ... Your python3 prepare_tfvars.py logic ...

                    sh """
                        source /home/jenkins/.credentials
                        export TERRAFORM=${params.bin_path}
                        ./terracumber-cli ${env.common_params} --runstep provision --tf_configuration_files "${localSumaformDirPath}terraform.tfvars"
                    """
                    runCucumberRakeTarget(target: 'utils:generate_build_validation_features')
                    deployed = true
                }
            }

            stage('Sanity check') {
                def nodesHandler = getNodesHandler(params)
                runCucumberRakeTarget(target: 'cucumber:build_validation_sanity_check', disableMinions: nodesHandler.envVariableListToDisable)
                env.controller_hostname = sh(script: "cd ${localSumaformDirPath}; tofu output -json configuration | jq -r '.controller.hostname'", returnStdout: true).trim()
            }

            // --- ALL STAGES INCLUDED ---

            stage('Products & Channels Sync') {
                if (params.must_sync && (deployed || !params.must_deploy)) {
                    def nodesHandler = getNodesHandler(params)
                    runCucumberRakeTarget(target: 'cucumber:build_validation_reposync', disableMinions: nodesHandler.envVariableListToDisable)
                }
            }

            if (params.enable_proxy_stages) {
                stage('Proxy Stages') {
                    if (params.must_add_MU_repositories) runCucumberRakeTarget(target: 'cucumber:build_validation_add_maintenance_update_repositories_proxy')
                    if (params.must_add_keys) runCucumberRakeTarget(target: 'cucumber:build_validation_add_activation_key_proxy')
                    if (params.must_create_bootstrap_repos) runCucumberRakeTarget(target: 'cucumber:build_validation_create_bootstrap_repository_proxy')
                    if (params.must_boot_node) runCucumberRakeTarget(target: 'cucumber:build_validation_init_proxy')
                }
            }

            if (params.enable_monitoring_stages) {
                stage('Monitoring Stages') {
                    if (params.must_add_MU_repositories) runCucumberRakeTarget(target: 'cucumber:build_validation_add_maintenance_update_repositories_monitoring_server')
                    if (params.must_boot_node) runCucumberRakeTarget(target: 'cucumber:build_validation_init_monitoring')
                }
            }

            if (params.enable_client_stages) {
                stage('Client Stages') {
                    def nodesHandler = getNodesHandler(params)
                    def tests = [:]

                    nodesHandler.nodeList.each { node ->
                        tests["${node}"] = {
                            def tempDisableList = nodesHandler.envVariableList.toList() - node.replaceAll('sles', 'sle').toUpperCase()
                            def nodeTag = node.replace('sles1','sle1')

                            stage("Test ${node}") {
                                if (params.must_add_MU_repositories) {
                                    runCucumberRakeTarget(target: "cucumber:build_validation_add_maintenance_update_repositories_${nodeTag}", disableMinions: tempDisableList)
                                    echoHtmlReportPath("build_validation_add_maintenance_update_repositories_${nodeTag}", env.controller_hostname)
                                }
                                if (params.must_create_bootstrap_repos) {
                                    runCucumberRakeTarget(target: "cucumber:build_validation_create_bootstrap_repository_${nodeTag}", disableMinions: tempDisableList)
                                }
                                if (params.must_run_tests) {
                                    randomWait()
                                    runCucumberRakeTarget(target: "cucumber:build_validation_smoke_tests_${nodeTag}", disableMinions: tempDisableList)
                                }
                            }
                        }
                    }
                    parallel tests
                }
            }

            if (params.must_run_products_and_salt_migration_tests) {
                stage('Migration Stages') {
                    // Replaced clientMigrationStages() function with inline logic for clarity
                    def features_list = sh(script: "./terracumber-cli ${env.common_params} --runstep cucumber --cucumber-cmd 'ls -1 /root/spacewalk/testsuite/features/build_validation/migration/'", returnStdout: true)
                    def migration_features = features_list.split("\n").findAll { it.contains("migration_") }
                    def migration_tests = [:]

                    migration_features.each { feature ->
                        def minion = cleanMigrationFeatureName(feature)
                        migration_tests["${minion}"] = {
                            runCucumberRakeTarget(target: "cucumber:build_validation_migration_${minion}")
                        }
                    }
                    parallel migration_tests
                }
            }

            if (params.must_prepare_retail) {
                stage('Retail Stages') {
                    parallel(
                            'Init build host sles15sp7': { runCucumberRakeTarget(target: 'cucumber:build_validation_retail_init_sles15sp7_buildhost') },
                            'Init build host sles15sp6': { runCucumberRakeTarget(target: 'cucumber:build_validation_retail_init_sles15sp6_buildhost') }
                    )
                }
            }

            if (params.must_run_containerization_tests) {
                stage('Containerization') {
                    runCucumberRakeTarget(target: 'cucumber:build_validation_containerization')
                }
            }

        } finally {
            stage('Reporting') {
                archiveArtifacts artifacts: "results/sumaform/terraform.tfstate", allowEmptyArchive: true

                if (deployed || !params.must_deploy) {
                    // Soft fail allows reporting to attempt execution even if a stage failed above
                    runCucumberRakeTarget(target: 'cucumber:build_validation_finishing', returnStatus: true)
                    runCucumberRakeTarget(target: 'utils:generate_test_report', returnStatus: true)

                    publishHTML(target: [
                            allowMissing: true, keepAll: true,
                            reportDir: "${env.resultdirbuild}/cucumber_report/",
                            reportFiles: 'cucumber_report.html',
                            reportName: "Build Validation report"
                    ])
                }
                sh "./terracumber-cli ${env.common_params} --logfile ${env.resultdirbuild}/mail.log --runstep mail"
                sh "./clean-old-results -r ${env.resultdir}"
            }
        }
    }
}