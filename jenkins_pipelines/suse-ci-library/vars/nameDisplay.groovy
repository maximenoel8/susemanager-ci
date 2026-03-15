def call(Map params) {
    def buildLabel = []

    if (params.must_deploy) buildLabel << 'deploy'
    if (params.must_run_core) buildLabel << 'core'
    if (params.must_sync) buildLabel << 'reposync'

    buildLabel << buildComponentLabel("proxy", params, [
            'must_add_MU_repositories'     : 'AddMU',
            'must_add_keys'                : 'ActKeys',
            'must_create_bootstrap_repos'  : 'CrBoot',
            'must_boot_node'               : 'Boot'
    ], params.enable_proxy_stages)

    buildLabel << buildComponentLabel("monitoring", params, [
            'must_add_MU_repositories'     : 'AddMU',
            'must_add_keys'                : 'ActKeys',
            'must_create_bootstrap_repos'  : 'CrBoot',
            'must_boot_node'               : 'Boot'
    ], params.enable_monitoring_stages)

    buildLabel << buildComponentLabel("client", params, [
            'must_add_MU_repositories'     : 'AddMU',
            'must_add_non_MU_repositories' : 'AddNonMU',
            'must_add_keys'                : 'ActKeys',
            'must_create_bootstrap_repos'  : 'CrBoot',
            'must_boot_node'               : 'Boot',
            'must_run_tests'               : 'Smoke'
    ], params.enable_client_stages)

    if (params.must_run_products_and_salt_migration_tests) buildLabel << 'migration'
    if (params.must_prepare_retail) buildLabel << 'PrepRetail'
    if (params.must_test_retail_terminal) buildLabel << 'TestRetail'

    def filteredLabel = []
    for (item in buildLabel) {
        if (item) {
            filteredLabel << item
        }
    }

    def baseOs = params.base_os ?: ''
    def fullLabel = "${params.product_version_display}${baseOs ? "_${baseOs}" : ""} - ${filteredLabel.join(' ')}"

    if (fullLabel.length() > 160) {
        return "#${env.BUILD_NUMBER} - ${params.product_version_display}${baseOs ? "_${baseOs}" : ""}"
    }
    return fullLabel
}