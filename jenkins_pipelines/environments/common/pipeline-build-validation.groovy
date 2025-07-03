def run(params) {
    timestamps {
        //Capybara configuration
        def capybara_timeout = 60
        def default_timeout = 500
        env.bootstrap_timeout = 800

        String controller_hostname = null
        GString TestEnvironmentCleanerProgram = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/test_environment_cleaner/test_environment_cleaner_program/TestEnvironmentCleaner.py"

        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        GString localSumaformDirPath = "${resultdir}/sumaform/"
        // The junit plugin doesn't affect full paths
        GString junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; "

        // Declare lock resource use during node bootstrap
        mgrCreateBootstrapRepo = 'share resource to avoid running mgr create bootstrap repo in parallel'
        // Variables to store none critical stage run status
        def monitoring_stage_result_fail = false
        def client_stage_result_fail = false
        def products_and_salt_migration_stage_result_fail = false
        def retail_stage_result_fail = false
        def containerization_stage_result_fail = false
        def server_container_repository = params.server_container_repository ?: null
        def proxy_container_repository = params.proxy_container_repository ?: null
        def server_container_image = params.server_container_image ?: ''
        // Parameters used for continuous pipeline
        def product_version = params.product_version ?: ''
        def base_os = params.base_os ?: ''

        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform"

        if (params.terraform_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
        }
        stage('Name run') {
            def buildLabel = []
            def options = []

            if (params.must_deploy) buildLabel << 'deploy'
            if (params.must_run_core) buildLabel << 'core'
            if (params.must_sync) buildLabel << 'reposync'

            if (params.must_add_MU_repositories) options << 'AddMU'
            if (params.must_add_non_MU_repositories) options << 'AddNonMU'
            if (params.must_add_keys) options << 'ActKeys'
            if (params.must_create_bootstrap_repos) options << 'CrBoot'
            if (params.must_boot_node) options << 'Boot'
            if (params.must_run_tests) options << 'Smoke'

            if (params.enable_proxy_stages) {
                buildLabel << "proxy[${options.join(' ')}]"
            }

            if (params.enable_monitoring_stages) {
                buildLabel << "monitoring[${options.join(' ')}]"
            }

            if (params.enable_client_stages) {
                buildLabel << "client[${options.join(' ')}]"
            }
            if (params.must_run_products_and_salt_migration_tests) buildLabel << 'migration'
            if (params.must_prepare_retail) buildLabel << 'retail'

            def fullLabel = "${params.product_version}_${params.base_os} - ${buildLabel.join(' ')}"

            if (fullLabel.length() > 120) {
                currentBuild.displayName = "#${env.BUILD_NUMBER} - ${params.product_version}_${params.base_os}"
            } else {
                currentBuild.displayName = "${fullLabel}"
            }

        }
    }
}

// You must return the script object so the caller can use the method
return this
