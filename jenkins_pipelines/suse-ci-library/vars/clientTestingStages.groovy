def call(Map params) {
    def tests = [:]
    def json_matching_non_MU_data = readJSON(file: params.non_MU_channels_tasks_file)
    def nodesHandler = getNodesHandler(params)
    def bootstrap_repository_status = nodesHandler.BootstrapRepositoryStatus
    def required_custom_channel_status = nodesHandler.CustomChannelStatus

    nodesHandler.nodeList.each { node ->
        tests["${node}"] = {
            def temporaryList = nodesHandler.envVariableList.toList() - node.replaceAll('sles', 'sle').toUpperCase()
            def nodeTag = node.replace('sles1','sle1')

            stage("Testing ${node}") {

                if (params.must_add_MU_repositories) {
                    stage("Add MUs ${node}") {
                        if (!node.contains('ssh')) {
                            lock(resource: 'lock the download package step during client add MU stage', timeout: 600) {
                                runCucumberRakeTarget(target: "cucumber:build_validation_add_maintenance_update_repositories_${nodeTag}", disableMinions: temporaryList)
                                echoHtmlReportPath("build_validation_add_maintenance_update_repositories_${nodeTag}")
                            }
                        }
                        if (!json_matching_non_MU_data.containsKey(node)) {
                            required_custom_channel_status[node] = 'CREATED'
                        }
                    }
                }

                if (params.must_add_non_MU_repositories) {
                    stage("Add non MU Repositories ${node}") {
                        if (!node.contains('ssh') && json_matching_non_MU_data.containsKey(node)) {
                            def build_validation_non_MU_script = json_matching_non_MU_data["${node}"]
                            runCucumberRakeTarget(target: "cucumber:${build_validation_non_MU_script}", disableMinions: temporaryList)
                            echoHtmlReportPath(build_validation_non_MU_script)
                        }
                        if (json_matching_non_MU_data.containsKey(node)) {
                            required_custom_channel_status[node] = 'CREATED'
                        }
                    }
                }

                if (params.must_add_keys && !node.contains('salt_migration_minion')) {
                    stage("Add Activation Keys ${node}") {
                        if (node.contains('sshminion')) {
                            def minion_name_without_ssh = node.replaceAll('sshminion', 'minion')
                            waitUntil { required_custom_channel_status[minion_name_without_ssh] != 'NOT_CREATED' }
                        }
                        runCucumberRakeTarget(target: "cucumber:build_validation_add_activation_key_${nodeTag}", disableMinions: temporaryList)
                        echoHtmlReportPath("build_validation_add_activation_key_${nodeTag}")
                    }
                }

                if (params.must_create_bootstrap_repos) {
                    stage("Create bootstrap repository ${node}") {
                        if (node.contains('sshminion')) {
                            def minion_name_without_ssh = node.replaceAll('sshminion', 'minion')
                            waitUntil { bootstrap_repository_status[minion_name_without_ssh] != 'NOT_CREATED' }
                        } else {
                            if (node.contains('s390')){
                                def minion_name_without_s390 = node.replaceAll('s390', '')
                                waitUntil { bootstrap_repository_status[minion_name_without_s390] != 'NOT_CREATED' }
                            }
                            lock(resource: 'share resource to avoid running mgr create bootstrap repo in parallel', timeout: 320) {
                                runCucumberRakeTarget(target: "cucumber:build_validation_create_bootstrap_repository_${nodeTag}", disableMinions: temporaryList)
                                echoHtmlReportPath("build_validation_create_bootstrap_repository_${nodeTag}")
                            }
                        }
                        bootstrap_repository_status[node] = 'CREATED'
                    }
                }

                if (params.must_boot_node) {
                    stage("Bootstrap client ${node}") {
                        randomWait()
                        def customExports = "export DEFAULT_TIMEOUT=${env.bootstrap_timeout};"
                        runCucumberRakeTarget(target: "cucumber:build_validation_init_client_${nodeTag}", disableMinions: temporaryList, customExports: customExports)
                        echoHtmlReportPath("build_validation_init_client_${nodeTag}")
                    }
                }

                if (params.must_run_tests) {
                    stage("Run Smoke Tests ${node}") {
                        randomWait()
                        runCucumberRakeTarget(target: "cucumber:build_validation_smoke_tests_${nodeTag}", disableMinions: temporaryList)
                        echoHtmlReportPath("build_validation_smoke_tests_${nodeTag}")
                    }
                }
            }
        }
    }
    parallel tests
}