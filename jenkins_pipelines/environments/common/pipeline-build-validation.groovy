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
        stage('Init') {
            currentBuild.displayName = "#${BUILD_NUMBER} -test tests 1"
        }
    }
}

// You must return the script object so the caller can use the method
return this